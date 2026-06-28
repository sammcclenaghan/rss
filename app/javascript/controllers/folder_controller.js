import { Controller } from '@hotwired/stimulus'

// A collapsible sidebar folder. Toggling hides/shows the feed list and rotates
// the chevron; the open/closed state is persisted in localStorage keyed by the
// folder name so it survives Turbo navigations and reloads. Defaults to open.
export default class extends Controller {
  static targets = ['content', 'chevron']
  static values = { key: String }

  connect() {
    if (this.#stored() === 'closed') this.#apply(false)
  }

  toggle() {
    this.#apply(this.contentTarget.classList.contains('hidden'))
  }

  #apply(open) {
    this.contentTarget.classList.toggle('hidden', !open)
    if (this.hasChevronTarget) {
      this.chevronTarget.classList.toggle('-rotate-90', !open)
    }
    this.#store(open ? 'open' : 'closed')
  }

  #storageKey() {
    return `folder:${this.keyValue}`
  }

  #stored() {
    try { return localStorage.getItem(this.#storageKey()) } catch { return null }
  }

  #store(value) {
    try { localStorage.setItem(this.#storageKey(), value) } catch {}
  }
}
