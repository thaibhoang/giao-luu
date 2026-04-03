import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["input"]

  decrement(event) {
    event.preventDefault()
    this.changeBy(-this.stepValue())
  }

  increment(event) {
    event.preventDefault()
    this.changeBy(this.stepValue())
  }

  stepValue() {
    const step = parseInt(this.inputTarget.step || "1", 10)
    return Number.isFinite(step) && step > 0 ? step : 1
  }

  minValue() {
    if (this.inputTarget.min === "") return -Infinity
    const min = parseInt(this.inputTarget.min, 10)
    return Number.isFinite(min) ? min : -Infinity
  }

  maxValue() {
    if (this.inputTarget.max === "") return Infinity
    const max = parseInt(this.inputTarget.max, 10)
    return Number.isFinite(max) ? max : Infinity
  }

  changeBy(delta) {
    const input = this.inputTarget
    const current = parseInt(input.value, 10) || 0
    let next = current + delta
    next = Math.max(this.minValue(), Math.min(this.maxValue(), next))
    input.value = next
    input.dispatchEvent(new Event("input", { bubbles: true }))
    input.dispatchEvent(new Event("change", { bubbles: true }))
  }
}
