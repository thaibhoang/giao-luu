import { Controller } from "@hotwired/stimulus"

// Ẩn/hiện dropdown trình độ theo môn được chọn (badminton vs pickleball)
export default class extends Controller {
  static values = {
    sport: { type: String, default: "badminton" }
  }

  static targets = ["badmintonSkill", "pickleballSkill"]

  connect() {
    this.#applySport(this.sportValue)
  }

  onSportChange(event) {
    const sport = event.target.value
    this.sportValue = sport
    this.#applySport(sport)
  }

  #applySport(sport) {
    const isPickleball = sport === "pickleball"
    this.badmintonSkillTargets.forEach(el => el.classList.toggle("hidden", isPickleball))
    this.pickleballSkillTargets.forEach(el => el.classList.toggle("hidden", !isPickleball))
  }
}
