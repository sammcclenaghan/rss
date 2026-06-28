import { Controller } from '@hotwired/stimulus'

// Tracks a post's starred state. The toggle button stars/unstars the post,
// sending the request to the stars endpoint with the CSRF token and updating
// the UI optimistically (mirrors post_read_controller).
export default class extends Controller {
  static values = { url: String, starred: Boolean }

  toggle() {
    const method = this.starredValue ? 'DELETE' : 'POST'
    this.#send(method)
    this.#setStarred(!this.starredValue)
  }

  #setStarred(starred) {
    this.starredValue = starred
    this.element.classList.toggle('is-starred', starred)
  }

  #send(method) {
    const token = document.querySelector('meta[name="csrf-token"]')?.content
    fetch(this.urlValue, {
      method,
      headers: { 'X-CSRF-Token': token || '', 'Accept': 'application/json' },
      keepalive: true,
    }).catch(() => {})
  }
}
