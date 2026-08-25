import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["box"]

  open(event) {
    event?.preventDefault()
    this.boxTarget.showModal()
  }

  close() {
    this.boxTarget.close()
  }

  backdrop(event) {
    if (event.target === this.boxTarget) this.close()
  }
}
