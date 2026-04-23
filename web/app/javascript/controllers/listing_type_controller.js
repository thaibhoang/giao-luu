import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["courtPassSection", "tournamentSection", "matchSection"]

  onChange(event) {
    const type = event.currentTarget.value
    this.#updateLabelStyles(type)
    this.#showSectionsFor(type)
  }

  // Also run on connect so SSR-rendered page is consistent
  connect() {
    const checked = this.element.querySelector("input[name='listing[listing_type]']:checked")
    if (checked) {
      this.#updateLabelStyles(checked.value)
      this.#showSectionsFor(checked.value)
    }
  }

  #updateLabelStyles(selectedType) {
    const inputs = this.element.querySelectorAll("input[name='listing[listing_type]']")
    inputs.forEach(input => {
      const div = input.closest("label")?.querySelector("div")
      if (!div) return
      const isActive = input.value === selectedType
      div.classList.toggle("border-primary", isActive)
      div.classList.toggle("bg-primary/5", isActive)
      div.classList.toggle("text-primary", isActive)
      div.classList.toggle("border-outline-variant/40", !isActive)
      div.classList.toggle("text-on-surface-variant", !isActive)
    })
  }

  #showSectionsFor(type) {
    this.courtPassSectionTargets.forEach(el => {
      el.classList.toggle("hidden", type !== "court_pass")
    })
    this.tournamentSectionTargets.forEach(el => {
      el.classList.toggle("hidden", type !== "tournament")
    })
    this.matchSectionTargets.forEach(el => {
      el.classList.toggle("hidden", type === "court_pass")
    })
  }
}
