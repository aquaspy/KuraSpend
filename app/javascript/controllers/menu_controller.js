import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["menu", "menuButton"]

  connect() {
    this.onPointer = (event) => {
      if (!this.hasMenuTarget || this.menuTarget.hidden) return
      if (event.target.closest(".mobile-menu, [data-menu-target='menuButton']")) return
      this.close()
    }
    document.addEventListener("pointerdown", this.onPointer)
  }

  disconnect() {
    document.removeEventListener("pointerdown", this.onPointer)
  }

  toggle() {
    if (!this.hasMenuTarget) return
    this.menuTarget.hidden = !this.menuTarget.hidden
    if (this.hasMenuButtonTarget) {
      this.menuButtonTarget.setAttribute("aria-expanded", String(!this.menuTarget.hidden))
    }
  }

  close() {
    if (this.hasMenuTarget) this.menuTarget.hidden = true
    if (this.hasMenuButtonTarget) this.menuButtonTarget.setAttribute("aria-expanded", "false")
  }
}
