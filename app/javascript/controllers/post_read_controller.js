import { Controller } from '@hotwired/stimulus'

// Tracks a post's read state. Opening the post (clicking its title/image link)
// marks it read; the toggle button flips it either way. Requests are sent to
// the reads endpoint with the CSRF token and update the UI optimistically.
export default class extends Controller {
  static values = { url: String, read: Boolean }
  static targets = ['toggle']

  // Fired when the external post link is opened; only marks read (never unread).
  markRead() {
    if (this.readValue) return
    this.#send('POST')
    this.#setRead(true)
  }

  // Explicit button: flip read <-> unread.
  toggle() {
    const method = this.readValue ? 'DELETE' : 'POST'
    this.#send(method)
    this.#setRead(!this.readValue)
  }

  #setRead(read) {
    this.readValue = read
    this.element.classList.toggle('is-read', read)
    if (this.hasToggleTarget) {
      this.toggleTarget.textContent = read ? 'Read' : 'Mark read'
    }
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
