import { Controller } from "@hotwired/stimulus"

const MAP_STYLES = [
  { elementType: "geometry", stylers: [{ color: "#efefef" }] },
  { elementType: "labels.text.fill", stylers: [{ color: "#6b7280" }] },
  { elementType: "labels.text.stroke", stylers: [{ color: "#f3f4f6" }] },
  { featureType: "poi", stylers: [{ visibility: "off" }] },
  { featureType: "transit", stylers: [{ visibility: "off" }] },
  { featureType: "road", elementType: "geometry", stylers: [{ color: "#d6d9df" }] },
  { featureType: "road.highway", elementType: "geometry", stylers: [{ color: "#cfd4db" }] },
  { featureType: "water", elementType: "geometry", stylers: [{ color: "#dfe5ec" }] },
]

export default class extends Controller {
  static values = {
    initialLat:      { type: Number, default: 10.8231 },
    initialLng:      { type: Number, default: 106.6297 },
    focusListingId:  { type: String, default: "" },
    badmintonAsset:  String,
    pickleballAsset: String,
  }

  static targets = [
    "mapCanvas",
    "drawer", "drawerBackdrop", "searchBarLabel",
    "qInput", "fromInput", "toInput", "skillMin", "skillMax",
    "locationStatus", "locationStatusText", "useLocationBtn",
    "pinModeOverlay", "pinConfirmBar",
    "panel", "panelToggle", "panelExpand",
    "tabListBtn", "tabDetailBtn", "tabListContent", "tabDetailContent",
    "resultList", "resultCount",
    "sportBtn", "radiusBtn", "listingTypeBtn",
  ]

  // ── Private state ──────────────────────────────────────────
  #map            = null
  #cluster        = null
  #markersById    = new Map()
  #activeMarkerIds = new Set()
  #lastRenderedKey = ""
  #sourceListings = []
  #filterSport       = ""
  #filterListingType = "match_finding"
  #filterRadiusKm = 3
  #filterLat      = null
  #filterLng      = null
  #isPinMode      = false
  #pinTempMarker  = null
  #pinTempLat     = null
  #pinTempLng     = null
  #mapClickListener = null
  #fmt            = new Intl.NumberFormat("vi-VN")

  // ── Lifecycle ──────────────────────────────────────────────

  connect() {
    this.#waitForMapLib()
      .then(() => {
        this.#initMap()
        this.#prefillFromUrl()
        this.#setDefaultFromDatetime()
        this.#setPanelCollapsed(false)
        return this.#fetchListings()
      })
      .catch(err => console.error("Không khởi tạo được map", err))
  }

  disconnect() {
    if (this.#mapClickListener) {
      google.maps.event.removeListener(this.#mapClickListener)
      this.#mapClickListener = null
    }
    this.#markersById.clear()
    this.#activeMarkerIds.clear()
  }

  // ── Public actions (data-action bindings) ──────────────────

  openDrawer()  {
    this.drawerTarget.classList.remove("-translate-x-full")
    this.drawerBackdropTarget.classList.remove("hidden")
    requestAnimationFrame(() =>
      this.drawerBackdropTarget.classList.replace("opacity-0", "opacity-100")
    )
  }

  closeDrawer() {
    this.drawerTarget.classList.add("-translate-x-full")
    this.drawerBackdropTarget.classList.replace("opacity-100", "opacity-0")
    setTimeout(() => this.drawerBackdropTarget.classList.add("hidden"), 300)
  }

  selectSport(event) {
    this.#updateSportButtons(event.currentTarget.dataset.sport ?? "")
  }

  selectListingType(event) {
    this.#updateListingTypeButtons(event.currentTarget.dataset.listingType ?? "")
  }

  selectRadius(event) {
    this.#updateRadiusButtons(event.currentTarget.dataset.radius)
  }

  useLocation() {
    if (!navigator.geolocation) return
    const btn = this.useLocationBtnTarget
    const originalHtml = btn.innerHTML
    btn.disabled = true
    btn.textContent = "Đang lấy vị trí..."

    navigator.geolocation.getCurrentPosition(
      (pos) => {
        this.#setLocationPin(pos.coords.latitude, pos.coords.longitude, "Vị trí hiện tại")
        this.#map.panTo({ lat: pos.coords.latitude, lng: pos.coords.longitude })
        this.#map.setZoom(14)
        btn.disabled = false
        btn.innerHTML = originalHtml
      },
      () => {
        btn.disabled = false
        btn.innerHTML = originalHtml
      }
    )
  }

  clearLocation() {
    this.#clearLocationPin()
  }

  enterPinMode() {
    this.#isPinMode = true
    this.closeDrawer()
    this.#setPanelCollapsed(true)
    this.pinModeOverlayTarget.classList.remove("hidden")
    this.pinConfirmBarTarget.classList.remove("hidden")
    this.mapCanvasTarget.style.cursor = "crosshair"

    this.#mapClickListener = this.#map.addListener("click", (e) => {
      this.#pinTempLat = e.latLng.lat()
      this.#pinTempLng = e.latLng.lng()
      if (this.#pinTempMarker) {
        this.#pinTempMarker.setPosition(e.latLng)
      } else {
        this.#pinTempMarker = new google.maps.Marker({
          position: e.latLng,
          map: this.#map,
          draggable: true,
          icon: this.#pinTempSvgIcon(),
        })
        this.#pinTempMarker.addListener("dragend", (ev) => {
          this.#pinTempLat = ev.latLng.lat()
          this.#pinTempLng = ev.latLng.lng()
        })
      }
    })
  }

  confirmPin() { this.#exitPinMode(true) }
  cancelPin()  { this.#exitPinMode(false) }

  togglePanel()    { this.#setPanelCollapsed(true) }
  expandPanel()    { this.#openPanel("list") }
  switchToList()   { this.#switchTab("list") }
  switchToDetail() { this.#switchTab("detail") }

  doSearch() {
    const params = new URLSearchParams()

    if (this.#filterListingType) params.set("listing_type", this.#filterListingType)
    if (this.#filterSport) params.set("sport", this.#filterSport)

    const q = this.qInputTarget.value.trim()
    if (q) params.set("q", q)

    if (this.fromInputTarget.value)
      params.set("from", new Date(this.fromInputTarget.value).toISOString())
    if (this.toInputTarget.value)
      params.set("to", new Date(this.toInputTarget.value).toISOString())

    const skillMin = this.skillMinTarget.value
    const skillMax = this.skillMaxTarget.value
    const skillMinOptions = Array.from(this.skillMinTarget.options).map(o => o.value)
    const skillMaxOptions = Array.from(this.skillMaxTarget.options).map(o => o.value)
    if (skillMin && skillMin !== skillMinOptions[0])                      params.set("skill_min", skillMin)
    if (skillMax && skillMax !== skillMaxOptions[skillMaxOptions.length - 1]) params.set("skill_max", skillMax)

    if (this.#filterLat !== null && this.#filterLng !== null) {
      params.set("lat",       this.#filterLat.toFixed(6))
      params.set("lng",       this.#filterLng.toFixed(6))
      params.set("radius_km", String(this.#filterRadiusKm))
    }

    const newUrl = window.location.pathname + (params.toString() ? "?" + params.toString() : "")
    try {
      history.replaceState(null, "", newUrl)
    } catch {
      window.location.href = "/listings/map" + (params.toString() ? "?" + params.toString() : "")
      return
    }

    this.#updateSearchBarLabel()
    this.closeDrawer()
    this.#fetchListings()
      .then(() => this.#openPanel("list"))
      .catch(err => console.error("fetchListings failed", err))
  }

  // ── Private helpers ────────────────────────────────────────

  #waitForMapLib() {
    return new Promise((resolve, reject) => {
      const startedAt = Date.now()
      const timer = setInterval(() => {
        if (window.google?.maps && window.markerClusterer) {
          clearInterval(timer); resolve()
        } else if (Date.now() - startedAt > 12_000) {
          clearInterval(timer); reject(new Error("Google Maps library timeout"))
        }
      }, 120)
    })
  }

  #initMap() {
    this.#map = new google.maps.Map(this.mapCanvasTarget, {
      center: { lat: this.initialLatValue, lng: this.initialLngValue },
      zoom: 12,
      mapTypeControl:   false,
      streetViewControl: false,
      fullscreenControl: false,
      rotateControl:    false,
      gestureHandling:  "greedy",
      zoomControl:      true,
      styles:           MAP_STYLES,
    })
  }

  #markerIconForSport(sport) {
    const url = sport === "pickleball" ? this.pickleballAssetValue : this.badmintonAssetValue
    return { url, scaledSize: new google.maps.Size(40, 48), anchor: new google.maps.Point(20, 48) }
  }

  #clusterSvgIcon(count) {
    const svg = `<svg xmlns="http://www.w3.org/2000/svg" width="58" height="58" viewBox="0 0 58 58">
      <circle cx="29" cy="29" r="25" fill="#ffffff" stroke="#ef4444" stroke-width="3"/>
      <text x="29" y="34" text-anchor="middle" font-family="Inter, Arial, sans-serif" font-size="16" font-weight="700" fill="#111827">${this.#fmt.format(count)}</text>
    </svg>`
    return {
      url: "data:image/svg+xml;charset=UTF-8," + encodeURIComponent(svg),
      scaledSize: new google.maps.Size(58, 58),
      anchor: new google.maps.Point(29, 29),
    }
  }

  #pinTempSvgIcon() {
    const svg = `<svg xmlns="http://www.w3.org/2000/svg" width="48" height="58" viewBox="0 0 48 58">
      <path d="M24 3C13.2 3 4.5 11.7 4.5 22.5c0 13.2 15.9 29.1 18.2 31.3a1.9 1.9 0 0 0 2.6 0c2.3-2.2 18.2-18.1 18.2-31.3C43.5 11.7 34.8 3 24 3z"
        fill="#6366f1" stroke="#4f46e5" stroke-width="2"/>
      <text x="24" y="28.5" text-anchor="middle" font-size="18">📍</text>
    </svg>`
    return {
      url: "data:image/svg+xml;charset=UTF-8," + encodeURIComponent(svg),
      scaledSize: new google.maps.Size(48, 58),
      anchor: new google.maps.Point(24, 54),
    }
  }

  #toLocalDatetimeValue(date) {
    const pad = n => String(n).padStart(2, "0")
    return `${date.getFullYear()}-${pad(date.getMonth() + 1)}-${pad(date.getDate())}T${pad(date.getHours())}:${pad(date.getMinutes())}`
  }

  #updateSportButtons(value) {
    this.#filterSport = value
    this.sportBtnTargets.forEach(btn => {
      const isActive = (btn.dataset.sport ?? "") === value
      btn.classList.toggle("bg-primary",              isActive)
      btn.classList.toggle("text-white",              isActive)
      btn.classList.toggle("border-primary",          isActive)
      btn.classList.toggle("bg-white",               !isActive)
      btn.classList.toggle("text-on-surface",        !isActive)
      btn.classList.toggle("border-outline-variant/40", !isActive)
    })
    this.#rebuildSkillOptions(value)
  }

  #rebuildSkillOptions(sport) {
    const isPickleball = sport === "pickleball"
    ;[this.skillMinTarget, this.skillMaxTarget].forEach((select, idx) => {
      const key = isPickleball ? "pickleballOptions" : "badmintonOptions"
      const options = JSON.parse(select.dataset[key] ?? "[]")
      const prevValue = select.value
      select.innerHTML = ""
      options.forEach(([label, value]) => {
        const opt = document.createElement("option")
        opt.value = value
        opt.textContent = label
        select.appendChild(opt)
      })
      // Restore value nếu vẫn hợp lệ, nếu không thì chọn đầu/cuối mặc định
      const values = options.map(([, v]) => v)
      if (values.includes(prevValue)) {
        select.value = prevValue
      } else {
        select.value = idx === 0 ? values[0] : values[values.length - 1]
      }
    })
  }

  #updateListingTypeButtons(value) {
    this.#filterListingType = value
    this.listingTypeBtnTargets.forEach(btn => {
      const isActive = (btn.dataset.listingType ?? "") === value
      btn.classList.toggle("bg-primary",              isActive)
      btn.classList.toggle("text-white",              isActive)
      btn.classList.toggle("border-primary",          isActive)
      btn.classList.toggle("bg-white",               !isActive)
      btn.classList.toggle("text-on-surface",        !isActive)
      btn.classList.toggle("border-outline-variant/40", !isActive)
    })
  }

  #updateRadiusButtons(value) {
    this.#filterRadiusKm = Number(value)
    this.radiusBtnTargets.forEach(btn => {
      const isActive = Number(btn.dataset.radius) === this.#filterRadiusKm
      btn.classList.toggle("bg-primary",              isActive)
      btn.classList.toggle("text-white",              isActive)
      btn.classList.toggle("border-primary",          isActive)
      btn.classList.toggle("bg-white",               !isActive)
      btn.classList.toggle("text-on-surface",        !isActive)
      btn.classList.toggle("border-outline-variant/40", !isActive)
    })
  }

  #setLocationPin(lat, lng, label) {
    this.#filterLat = lat
    this.#filterLng = lng
    this.locationStatusTarget.classList.remove("hidden")
    this.locationStatusTextTarget.textContent = label
  }

  #clearLocationPin() {
    this.#filterLat = null
    this.#filterLng = null
    this.locationStatusTarget.classList.add("hidden")
    this.locationStatusTextTarget.textContent = ""
  }

  #exitPinMode(confirmed) {
    this.#isPinMode = false
    if (this.#mapClickListener) {
      google.maps.event.removeListener(this.#mapClickListener)
      this.#mapClickListener = null
    }
    this.mapCanvasTarget.style.cursor = ""
    this.pinModeOverlayTarget.classList.add("hidden")
    this.pinConfirmBarTarget.classList.add("hidden")
    if (confirmed && this.#pinTempLat !== null) {
      this.#setLocationPin(
        this.#pinTempLat, this.#pinTempLng,
        `📍 ${this.#pinTempLat.toFixed(4)}, ${this.#pinTempLng.toFixed(4)}`
      )
    }
    if (this.#pinTempMarker) { this.#pinTempMarker.setMap(null); this.#pinTempMarker = null }
    this.#pinTempLat = null
    this.#pinTempLng = null
    this.openDrawer()
  }

  #updateSearchBarLabel() {
    const sportMap = { badminton: "Cầu lông", pickleball: "Pickleball" }
    const typeMap  = { match_finding: "Tuyển giao lưu", court_pass: "Pass sân", tournament: "Tuyển giải đấu" }
    const parts = []
    if (this.#filterListingType && typeMap[this.#filterListingType]) parts.push(typeMap[this.#filterListingType])
    if (this.#filterSport && sportMap[this.#filterSport]) parts.push(sportMap[this.#filterSport])
    if (this.qInputTarget.value.trim()) parts.push(`"${this.qInputTarget.value.trim()}"`)
    if (this.#filterLat !== null) parts.push(`📍 ${this.#filterRadiusKm}km`)
    this.searchBarLabelTarget.textContent = parts.length > 0 ? parts.join(" · ") : "Tìm kiếm kèo..."
  }

  #prefillFromUrl() {
    const sp = new URLSearchParams(window.location.search)
    if (sp.get("listing_type")) this.#updateListingTypeButtons(sp.get("listing_type"))
    else this.#updateListingTypeButtons("match_finding") // default
    if (sp.get("sport"))     this.#updateSportButtons(sp.get("sport"))
    if (sp.get("q"))         this.qInputTarget.value = sp.get("q")
    if (sp.get("from"))      { try { this.fromInputTarget.value = this.#toLocalDatetimeValue(new Date(sp.get("from"))) } catch {} }
    if (sp.get("to"))        { try { this.toInputTarget.value   = this.#toLocalDatetimeValue(new Date(sp.get("to")))   } catch {} }
    if (sp.get("skill_min")) this.skillMinTarget.value = sp.get("skill_min")
    if (sp.get("skill_max")) this.skillMaxTarget.value = sp.get("skill_max")
    if (sp.get("radius_km")) this.#updateRadiusButtons(sp.get("radius_km"))
    if (sp.get("lat") && sp.get("lng")) {
      const lat = Number(sp.get("lat")), lng = Number(sp.get("lng"))
      if (Number.isFinite(lat) && Number.isFinite(lng))
        this.#setLocationPin(lat, lng, `📍 ${lat.toFixed(4)}, ${lng.toFixed(4)}`)
    }
    this.#updateSearchBarLabel()
  }

  #setDefaultFromDatetime() {
    if (!this.fromInputTarget.value)
      this.fromInputTarget.value = this.#toLocalDatetimeValue(new Date())
  }

  #switchTab(tab) {
    const isDetail = tab === "detail"
    this.tabListBtnTarget.classList.toggle("border-primary",         !isDetail)
    this.tabListBtnTarget.classList.toggle("text-primary",           !isDetail)
    this.tabListBtnTarget.classList.toggle("border-transparent",      isDetail)
    this.tabListBtnTarget.classList.toggle("text-on-surface-variant", isDetail)
    this.tabDetailBtnTarget.classList.toggle("border-primary",         isDetail)
    this.tabDetailBtnTarget.classList.toggle("text-primary",           isDetail)
    this.tabDetailBtnTarget.classList.toggle("border-transparent",    !isDetail)
    this.tabDetailBtnTarget.classList.toggle("text-on-surface-variant", !isDetail)
    this.tabListContentTarget.classList.toggle("hidden",   isDetail)
    this.tabDetailContentTarget.classList.toggle("hidden", !isDetail)
  }

  #setPanelCollapsed(collapsed) {
    this.panelTarget.classList.toggle("translate-y-full",  collapsed)
    this.panelTarget.classList.toggle("translate-y-0",    !collapsed)
    this.panelToggleTarget.setAttribute("aria-expanded", String(!collapsed))
    this.panelExpandTarget.classList.toggle("hidden", !collapsed)
  }

  #openPanel(tab = "list") {
    this.#switchTab(tab)
    this.#setPanelCollapsed(false)
  }

  #listingCardHtml(item) {
    const startAt = item.start_at ? new Date(item.start_at) : null
    const timeLabel = startAt
      ? startAt.toLocaleString("vi-VN", { day: "2-digit", month: "2-digit", hour: "2-digit", minute: "2-digit" })
      : "Chưa cập nhật"
    const sportLabel = item.sport === "pickleball" ? "Pickleball" : "Cầu lông"
    const typeLabels = { match_finding: "Tuyển giao lưu", court_pass: "Pass sân", tournament: "Tuyển giải đấu" }
    const typeLabel  = typeLabels[item.listing_type] || ""
    const typeBadgeColor = item.listing_type === "court_pass" ? "bg-orange-100 text-orange-700"
                         : item.listing_type === "tournament" ? "bg-purple-100 text-purple-700"
                         : "bg-green-100 text-green-700"
    return `
      <div data-listing-card data-listing-id="${item.id}" data-lat="${item.lat}" data-lng="${item.lng}"
        class="cursor-pointer min-w-[240px] max-w-[260px] rounded-2xl border border-outline-variant/30 bg-white p-3 shadow-sm active:bg-surface-container hover:shadow-md transition-shadow">
        <div class="flex items-center gap-2 mb-1">
          <p class="text-[11px] text-on-surface-variant font-semibold">${sportLabel}</p>
          <span class="text-[10px] font-bold px-2 py-0.5 rounded-full ${typeBadgeColor}">${typeLabel}</span>
        </div>
        <p class="mt-1 text-sm font-semibold text-on-surface line-clamp-2">${item.title || ""}</p>
        <p class="mt-1 text-xs text-on-surface-variant line-clamp-1">${item.location_name || ""}</p>
        <p class="mt-2 text-xs text-on-surface-variant">${timeLabel}</p>
      </div>
    `
  }

  #listingDetailHtml(item) {
    const startAt = item.start_at ? new Date(item.start_at) : null
    const timeLabel = startAt
      ? startAt.toLocaleString("vi-VN", { weekday: "short", day: "2-digit", month: "2-digit", year: "numeric", hour: "2-digit", minute: "2-digit" })
      : "Chưa cập nhật"
    const sportLabel = item.sport === "pickleball" ? "Pickleball" : "Cầu lông"
    const iconUrl = item.sport === "pickleball" ? this.pickleballAssetValue : this.badmintonAssetValue
    return `
      <div class="space-y-3">
        <div class="flex items-center gap-2">
          <img src="${iconUrl}" class="w-8 h-8" alt="${sportLabel}" />
          <span class="text-xs font-semibold text-on-surface-variant uppercase tracking-wide">${sportLabel}</span>
        </div>
        <h3 class="font-headline font-extrabold text-lg leading-snug text-on-surface">${item.title || ""}</h3>
        <div class="flex flex-col gap-1.5 text-sm text-on-surface-variant">
          <div class="flex items-center gap-2">
            <svg class="w-4 h-4 flex-shrink-0" viewBox="0 0 24 24" fill="currentColor">
              <path d="M12 2C8.13 2 5 5.13 5 9c0 5.25 7 13 7 13s7-7.75 7-13c0-3.87-3.13-7-7-7zm0 9.5c-1.38 0-2.5-1.12-2.5-2.5s1.12-2.5 2.5-2.5 2.5 1.12 2.5 2.5-1.12 2.5-2.5 2.5z"/>
            </svg>
            <span class="line-clamp-2">${item.location_name || "Chưa có địa điểm"}</span>
          </div>
          <div class="flex items-center gap-2">
            <svg class="w-4 h-4 flex-shrink-0" viewBox="0 0 24 24" fill="currentColor">
              <path d="M11.99 2C6.47 2 2 6.48 2 12s4.47 10 9.99 10C17.52 22 22 17.52 22 12S17.52 2 11.99 2zM12 20c-4.42 0-8-3.58-8-8s3.58-8 8-8 8 3.58 8 8-3.58 8-8 8zm.5-13H11v6l5.25 3.15.75-1.23-4.5-2.67V7z"/>
            </svg>
            <span>${timeLabel}</span>
          </div>
        </div>
        <a href="/listings/${item.id}"
          class="mt-4 inline-flex items-center justify-center w-full h-10 rounded-xl bg-primary text-white text-sm font-semibold gap-2">
          Xem trang sân
          <svg class="w-4 h-4" viewBox="0 0 24 24" fill="currentColor">
            <path d="M10 6L8.59 7.41 13.17 12l-4.58 4.59L10 18l6-6z"/>
          </svg>
        </a>
      </div>
    `
  }

  #renderResultList(items) {
    if (items.length === 0) {
      this.resultListTarget.innerHTML = '<p class="text-sm text-on-surface-variant py-2">Không có kèo phù hợp với bộ lọc hiện tại.</p>'
      return
    }
    this.resultListTarget.innerHTML = items.map(item => this.#listingCardHtml(item)).join("")
    this.resultListTarget.querySelectorAll("[data-listing-card]").forEach(card => {
      card.addEventListener("click", () => {
        const id  = card.dataset.listingId
        const lat = Number(card.dataset.lat)
        const lng = Number(card.dataset.lng)
        const item = this.#sourceListings.find(l => String(l.id) === String(id))
        if (Number.isFinite(lat) && Number.isFinite(lng)) {
          this.#map.panTo({ lat, lng })
          this.#map.setZoom(15)
        }
        if (item) {
          this.tabDetailContentTarget.innerHTML = this.#listingDetailHtml(item)
          this.#openPanel("detail")
        }
      })
    })
  }

  #ensureCluster() {
    if (this.#cluster) return this.#cluster
    this.#cluster = new markerClusterer.MarkerClusterer({
      map: this.#map,
      markers: [],
      renderer: {
        render: ({ count, position }) => new google.maps.Marker({
          position,
          icon: this.#clusterSvgIcon(count),
          zIndex: Number(google.maps.Marker.MAX_ZINDEX) + count,
        }),
      },
    })
    return this.#cluster
  }

  #getOrBuildMarker(item) {
    const key = String(item.id)
    if (this.#markersById.has(key)) return this.#markersById.get(key)

    const marker = new google.maps.Marker({
      position: { lat: Number(item.lat), lng: Number(item.lng) },
      title: item.title,
      icon: this.#markerIconForSport(item.sport),
    })
    marker.addListener("click", () => {
      this.#map.panTo({ lat: Number(item.lat), lng: Number(item.lng) })
      this.#map.setZoom(15)
      this.tabDetailContentTarget.innerHTML = this.#listingDetailHtml(item)
      this.#openPanel("detail")
    })
    this.#markersById.set(key, marker)
    return marker
  }

  #renderMarkers(items) {
    const validItems    = items.filter(item => Number.isFinite(Number(item.lat)) && Number.isFinite(Number(item.lng)))
    const nextIds       = new Set(validItems.map(item => String(item.id)))
    const validItemsById = new Map(validItems.map(item => [String(item.id), item]))
    const renderKey     = Array.from(nextIds).sort().join(",")

    if (renderKey === this.#lastRenderedKey) {
      this.resultCountTarget.textContent = `Tìm thấy ${items.length} trận đấu`
      return
    }
    this.#lastRenderedKey = renderKey

    const activeCluster = this.#ensureCluster()
    const toAdd = [], toRemove = []

    nextIds.forEach(id => {
      if (!this.#activeMarkerIds.has(id)) {
        const item = validItemsById.get(id)
        if (item) toAdd.push(this.#getOrBuildMarker(item))
      }
    })
    this.#activeMarkerIds.forEach(id => {
      if (!nextIds.has(id)) {
        const marker = this.#markersById.get(id)
        if (marker) toRemove.push(marker)
      }
    })

    if (toRemove.length > 0) activeCluster.removeMarkers(toRemove)
    if (toAdd.length > 0)    activeCluster.addMarkers(toAdd)
    this.#activeMarkerIds = nextIds

    this.resultCountTarget.textContent = `Tìm thấy ${items.length} trận đấu`
    this.#renderResultList(validItems)
  }

  async #fetchListings() {
    const sp = new URLSearchParams(window.location.search)
    const apiParams = new URLSearchParams()
    for (const key of ["from", "to", "sport", "listing_type", "q", "lat", "lng", "radius_km"]) {
      if (sp.get(key)) apiParams.set(key, sp.get(key))
    }
    const resp = await fetch("/api/v1/listings/map?" + apiParams.toString())
    if (!resp.ok) throw new Error("map feed failed")
    const json = await resp.json()
    this.#sourceListings = json.listings || []
    this.#renderMarkers(this.#sourceListings)

    if (this.focusListingIdValue) {
      const focused = this.#sourceListings.find(item => String(item.id) === this.focusListingIdValue)
      if (focused && Number.isFinite(Number(focused.lat)) && Number.isFinite(Number(focused.lng))) {
        this.#map.panTo({ lat: Number(focused.lat), lng: Number(focused.lng) })
        this.#map.setZoom(15)
      }
    }
  }
}
