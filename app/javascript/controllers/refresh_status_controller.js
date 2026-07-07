import { Controller } from '@hotwired/stimulus'

// Sidebar refresh progress. Feeds awaiting a background fetch render a
// server-side "Refreshing…" row; one poller (not one per feed) asks the
// server which feeds are still outdated, removes each row as its feed
// completes, and reloads the posts frame once when the last one finishes —
// no full-page reloads.
export default class extends Controller {
  static targets = ['status']
  static values = {
    url: String,
    pollInterval: { type: Number, default: 3000 }
  }

  connect() {
    if (this.hasStatusTarget) this.#schedule()
  }

  disconnect() {
    clearTimeout(this.pollTimer)
  }

  #schedule() {
    this.pollTimer = setTimeout(() => this.#poll(), this.pollIntervalValue)
  }

  async #poll() {
    try {
      const response = await fetch(this.urlValue, { headers: { Accept: 'application/json' } })
      const { outdated_feed_ids: outdatedIds } = await response.json()
      this.#settle(new Set(outdatedIds))
    } catch {
      this.#schedule()
    }
  }

  // Remove the spinner rows whose feeds have been fetched; keep polling while
  // any remain, and pull in the fresh posts once they're all done.
  #settle(outdatedIds) {
    const remaining = this.statusTargets.filter(el => {
      const done = !outdatedIds.has(Number(el.dataset.feedId))
      if (done) el.remove()
      return !done
    })

    remaining.length ? this.#schedule() : this.#reloadPosts()
  }

  #reloadPosts() {
    const frame = document.getElementById('posts')
    if (frame) frame.src = window.location.href
  }
}
