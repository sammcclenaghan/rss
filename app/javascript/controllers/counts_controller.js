import { Controller } from '@hotwired/stimulus'

// Keeps the sidebar unread counts in sync when posts are marked read/unread,
// without a page reload. The per-feed counts are the source of truth: when a
// post's read state changes, the matching feed count is adjusted, then each
// folder count and the Unread/All totals are recomputed by summing. Count
// badges hide when they reach zero.
export default class extends Controller {
  static targets = ['feed', 'folder', 'total']

  update(event) {
    const { feedId, delta } = event.detail
    if (feedId == null || !delta) return

    this.feedTargets
      .filter(el => el.dataset.feedId === String(feedId))
      .forEach(el => this.#set(el, this.#value(el) + delta))

    this.folderTargets.forEach(el => this.#set(el, this.#sumWithin(el.closest('[data-counts-folder]'))))

    const total = this.feedTargets.reduce((sum, el) => sum + this.#value(el), 0)
    this.totalTargets.forEach(el => this.#set(el, total))
  }

  // Sum the feed counts that live inside a folder container.
  #sumWithin(container) {
    if (!container) return 0
    return this.feedTargets
      .filter(el => container.contains(el))
      .reduce((sum, el) => sum + this.#value(el), 0)
  }

  #value(el) {
    return parseInt(el.textContent.trim(), 10) || 0
  }

  #set(el, n) {
    const value = Math.max(0, n)
    el.textContent = value
    el.classList.toggle('hidden', value === 0)
  }
}
