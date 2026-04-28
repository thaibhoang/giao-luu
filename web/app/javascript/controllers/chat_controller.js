/**
 * chat_controller.js — Stimulus controller cho chat panel realtime.
 *
 * Luồng:
 *   connect() → fetchToken() → openWS(token, roomId)
 *                                 ↓
 *                             onmessage → appendMessage() → scrollBottom()
 *                             onerror/onclose → scheduleReconnect()
 *
 * Rate limiting: phía Go giới hạn 10 msg/phút/user.
 * Khi nhận WS error "rate_limit", controller hiển thị cảnh báo nhẹ.
 *
 * Token TTL 15 phút — controller tự refresh 1 phút trước khi hết hạn.
 */
import { Controller } from "@hotwired/stimulus"

const RECONNECT_DELAYS  = [1_000, 3_000, 5_000, 10_000, 30_000] // exponential backoff
const STATUS_HIDE_AFTER = 4_000 // ms — tự ẩn thông báo trạng thái

export default class extends Controller {
  static values = {
    tokenUrl:      String, // GET /listings/:id/chat_token
    serviceUrl:    String, // ws://... hoặc wss://...
    roomId:        Number,
    currentUserId: Number, // ID của user đang đăng nhập
    ownerId:       Number, // ID của chủ listing
    users:         Object, // { "user_id": "Tên hiển thị" }
  }

  static targets = ["messages", "input", "sendBtn", "status"]

  // ── Private state ──────────────────────────────────────────────────────────
  #ws              = null
  #token           = null
  #tokenExpiresAt  = 0       // unix seconds
  #reconnectCount  = 0
  #reconnectTimer  = null
  #refreshTimer    = null
  #statusTimer     = null
  #seenMessageIds  = new Set() // deduplicate server-side + WS messages

  // ── Lifecycle ──────────────────────────────────────────────────────────────

  connect() {
    // Collect IDs của messages đã render server-side để không duplicate
    this.messagesTarget.querySelectorAll("[data-message-id]").forEach(el => {
      this.#seenMessageIds.add(el.dataset.messageId)
    })
    // Resolve tên cho server-side history
    this.#resolveAllUserLabels()
    // Format lại tất cả <time> elements theo timezone của browser
    this.#formatAllTimes()
    this.#scrollToBottom()
    this.#fetchTokenAndConnect()
  }

  disconnect() {
    this.#clearTimers()
    this.#ws?.close()
    this.#ws = null
  }

  // ── Public actions (data-action bindings) ──────────────────────────────────

  send() {
    const body = this.inputTarget.value.trim()
    if (!body || !this.#wsReady()) return

    this.#ws.send(JSON.stringify({ body }))
    this.inputTarget.value = ""
    this.inputTarget.focus()
  }

  // ── Token management ───────────────────────────────────────────────────────

  async #fetchTokenAndConnect() {
    try {
      const res = await fetch(this.tokenUrlValue, {
        headers: { Accept: "application/json" },
        credentials: "same-origin",
      })

      if (res.status === 403) {
        // Không có quyền (race condition với Rails render) — ẩn panel
        this.element.hidden = true
        return
      }
      if (!res.ok) {
        this.#showStatus("Không thể kết nối chat. Thử lại sau.", "error")
        return
      }

      const { token, expires_in } = await res.json()
      this.#token = token
      this.#tokenExpiresAt = Math.floor(Date.now() / 1000) + expires_in

      // Refresh token 60 giây trước khi hết hạn
      const refreshIn = (expires_in - 60) * 1000
      if (refreshIn > 0) {
        this.#refreshTimer = setTimeout(() => this.#refreshToken(), refreshIn)
      }

      this.#openWS()
    } catch (err) {
      console.error("chat: fetch token failed", err)
      this.#showStatus("Lỗi kết nối. Thử lại sau.", "error")
    }
  }

  async #refreshToken() {
    // Nếu WS vẫn đang open, lấy token mới để dùng cho reconnect tiếp theo
    try {
      const res = await fetch(this.tokenUrlValue, {
        headers: { Accept: "application/json" },
        credentials: "same-origin",
      })
      if (res.ok) {
        const { token, expires_in } = await res.json()
        this.#token = token
        this.#tokenExpiresAt = Math.floor(Date.now() / 1000) + expires_in
        // Lập lịch refresh tiếp theo
        const refreshIn = (expires_in - 60) * 1000
        if (refreshIn > 0) {
          this.#refreshTimer = setTimeout(() => this.#refreshToken(), refreshIn)
        }
      }
    } catch (_) { /* silent — sẽ dùng token cũ hoặc reconnect tự lấy mới */ }
  }

  // ── WebSocket management ───────────────────────────────────────────────────

  #openWS() {
    if (!this.#token) return

    const baseUrl = this.serviceUrlValue.replace(/^http/, "ws")
    const url = `${baseUrl}/ws?room=${this.roomIdValue}&token=${encodeURIComponent(this.#token)}`

    this.#showStatus("Đang kết nối…", "info")
    const ws = new WebSocket(url)
    this.#ws = ws

    ws.onopen = () => {
      this.#reconnectCount = 0
      this.#showStatus("Đã kết nối", "success", STATUS_HIDE_AFTER)
      this.#setSendDisabled(false)
    }

    ws.onmessage = (event) => {
      try {
        const msg = JSON.parse(event.data)
        if (msg.error === "rate_limit") {
          this.#showStatus("Gửi quá nhanh — vui lòng chờ 1 phút.", "warn")
          return
        }
        this.#appendMessage(msg)
      } catch (e) {
        console.warn("chat: bad message", event.data, e)
      }
    }

    ws.onerror = (event) => {
      console.error("chat: ws error", event)
    }

    ws.onclose = (event) => {
      this.#ws = null
      this.#setSendDisabled(true)

      if (event.code === 1000 || !this.element.isConnected) return // clean close

      this.#scheduleReconnect()
    }
  }

  #scheduleReconnect() {
    const delay = RECONNECT_DELAYS[
      Math.min(this.#reconnectCount, RECONNECT_DELAYS.length - 1)
    ]
    this.#reconnectCount++
    this.#showStatus(`Mất kết nối — thử lại sau ${delay / 1000}s…`, "warn")

    this.#reconnectTimer = setTimeout(() => {
      if (!this.element.isConnected) return

      // Nếu token gần hết hạn, fetch mới trước khi reconnect
      const now = Math.floor(Date.now() / 1000)
      if (this.#tokenExpiresAt - now < 60) {
        this.#fetchTokenAndConnect()
      } else {
        this.#openWS()
      }
    }, delay)
  }

  // ── DOM helpers ────────────────────────────────────────────────────────────

  #appendMessage(msg) {
    const id = String(msg.message_id)
    if (this.#seenMessageIds.has(id)) return
    this.#seenMessageIds.add(id)

    // Merge user vào local map nếu WS message có trường name (future-proof)
    if (msg.user_name) {
      const users = { ...(this.usersValue || {}) }
      users[String(msg.user_id)] = msg.user_name
      this.usersValue = users
    }

    const div = document.createElement("div")
    div.className = "flex gap-2 items-start"
    div.dataset.messageId = id

    const ts = new Date(msg.created_at)
    const timeISO = ts.toISOString()

    div.innerHTML = `
      <span class="text-xs flex items-center gap-0.5 overflow-hidden" style="flex:0 0 5rem;width:5rem" data-chat-user-label data-user-id="${msg.user_id}">${this.#buildUserLabel(msg.user_id)}</span>
      <p class="text-on-surface leading-snug wrap-break-word min-w-0 flex-1">${this.#escapeHtml(msg.body)}</p>
      <time class="ml-2 text-xs text-on-surface-variant whitespace-nowrap shrink-0"
            datetime="${timeISO}"></time>
    `

    this.messagesTarget.appendChild(div)
    this.#formatAllTimes()
    this.#scrollToBottom()
  }

  // Format tất cả <time datetime="..."> theo timezone browser (Asia/Ho_Chi_Minh)
  #formatAllTimes() {
    this.messagesTarget.querySelectorAll("time[datetime]").forEach(el => {
      const dt = el.getAttribute("datetime")
      if (!dt) return
      const ts = new Date(dt)
      if (isNaN(ts)) return
      el.textContent = ts.toLocaleTimeString("vi-VN", {
        hour: "2-digit",
        minute: "2-digit",
        timeZone: "Asia/Ho_Chi_Minh",
      })
      el.title = ts.toLocaleString("vi-VN", {
        dateStyle: "short",
        timeStyle: "short",
        timeZone: "Asia/Ho_Chi_Minh",
      })
    })
  }

  // Resolve tên cho tất cả [data-chat-user-label] elements trong messages target
  #resolveAllUserLabels() {
    this.messagesTarget.querySelectorAll("[data-chat-user-label]").forEach(el => {
      const userId = el.dataset.userId
      if (!userId) return
      el.innerHTML = this.#buildUserLabel(userId)
    })
  }

  // Trả về HTML string cho tên user + icon crown nếu là owner
  #buildUserLabel(userId) {
    const users = this.usersValue || {}
    const name = users[userId] || users[String(userId)] || `#${userId}`
    const isOwner = String(userId) === String(this.ownerIdValue)
    const isMe = String(userId) === String(this.currentUserIdValue)
    const ownerIcon = isOwner
      ? `<span class="ml-0.5 text-amber-500 align-middle" title="Người đăng bài">★</span>`
      : ""
    const nameClass = isMe ? "text-primary" : "text-secondary"
    return `<span class="font-semibold ${nameClass} truncate block w-full" title="${this.#escapeHtml(name)}">${this.#escapeHtml(name)}</span>${ownerIcon}`
  }

  #scrollToBottom() {
    const el = this.messagesTarget
    requestAnimationFrame(() => { el.scrollTop = el.scrollHeight })
  }

  #showStatus(text, tone = "info", autohideMs = 0) {
    clearTimeout(this.#statusTimer)
    const el = this.statusTarget

    const toneClass = {
      info:    "text-on-surface-variant",
      success: "text-green-600",
      warn:    "text-amber-600",
      error:   "text-red-600",
    }[tone] ?? "text-on-surface-variant"

    el.textContent = text
    el.className = `text-xs text-center ${toneClass}`
    el.hidden = false

    if (autohideMs > 0) {
      this.#statusTimer = setTimeout(() => { el.hidden = true }, autohideMs)
    }
  }

  #setSendDisabled(disabled) {
    if (this.hasSendBtnTarget) this.sendBtnTarget.disabled = disabled
    if (this.hasInputTarget)   this.inputTarget.disabled   = disabled
  }

  #wsReady() {
    return this.#ws?.readyState === WebSocket.OPEN
  }

  #clearTimers() {
    clearTimeout(this.#reconnectTimer)
    clearTimeout(this.#refreshTimer)
    clearTimeout(this.#statusTimer)
  }

  /** Escape để tránh XSS khi chèn body vào innerHTML */
  #escapeHtml(str) {
    return String(str)
      .replace(/&/g, "&amp;")
      .replace(/</g, "&lt;")
      .replace(/>/g, "&gt;")
      .replace(/"/g, "&quot;")
      .replace(/'/g, "&#039;")
  }
}
