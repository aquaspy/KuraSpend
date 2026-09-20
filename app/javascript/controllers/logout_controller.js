import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  async wipe(event) {
    event.preventDefault()
    try { await caches.delete("kuraspend-v1") } catch {}
    try {
      // Unsaved composer drafts (prefix must match composer_controller.js).
      const doomed = []
      for (let i = 0; i < window.localStorage.length; i++) {
        const key = window.localStorage.key(i)
        if (key?.startsWith("kuraspend_draft_")) doomed.push(key)
      }
      doomed.forEach((key) => window.localStorage.removeItem(key))
    } catch {}
    try {
      const reg = await navigator.serviceWorker.getRegistration()
      reg?.active?.postMessage("logout")
    } catch {}
    event.target.submit()
  }
}
