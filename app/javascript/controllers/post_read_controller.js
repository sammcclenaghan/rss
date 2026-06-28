import { Controller } from '@hotwired/stimulus'

// Tracks a post's read state. Opening the post (clicking its title/link) marks
// it read; the toggle button flips it either way. The read/unread icon is
// driven by the `is-read` class on the row (see application.css). Requests are
// sent to the reads endpoint with the CSRF token and update the UI optimistically.
export default class extends Controller {
  static values = { url: String, read: Boolean, feedId: Number }
  static targets = ['toggle']

  // Fired when the external post link is opened; only marks read (never unread).
  markRead() {
    if (this.readValue) return
    this.#send('POST')
    this.#setRead(true)
    this.#notify(-1)
  }

  // Explicit button: flip read <-> unread.
  toggle() {
    const wasRead = this.readValue
    this.#send(wasRead ? 'DELETE' : 'POST')
    this.#setRead(!wasRead)
    this.#notify(wasRead ? +1 : -1)
  }

  #setRead(read) {
    this.readValue = read
    this.element.classList.toggle('is-read', read)
  }

  // Tell the sidebar to adjust unread counts for this feed (-1 read, +1 unread).
  #notify(delta) {
    this.dispatch('changed', { detail: { feedId: this.feedIdValue, delta } })
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
