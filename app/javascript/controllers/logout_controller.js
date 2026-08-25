import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  async wipe(event) {
    event.preventDefault()
    try { await caches.delete("kuraspend-v1") } catch {}
    try {
      const reg = await navigator.serviceWorker.getRegistration()
      reg?.active?.postMessage("logout")
    } catch {}
    event.target.submit()
  }
}
