import { Controller } from '@hotwired/stimulus'

export default class extends Controller {
  static targets = ['status']
  static values = {
    url: String,
    reloading: Boolean,
    pollInterval: { type: Number, default: 3000 }
  }

  connect() {
    if (this.reloadingValue) {
      this.statusTarget.classList.remove('hidden')
      this.schedulePoll()
    }
  }

  disconnect() {
    this.stopPoll()
  }

  schedulePoll() {
    this.pollTimer = setTimeout(() => this.poll(), this.pollIntervalValue)
  }

  stopPoll() {
    if (this.pollTimer) {
      clearTimeout(this.pollTimer)
      this.pollTimer = null
    }
  }

  async poll() {
    try {
      const resp = await fetch(`/feeds/information?url=${encodeURIComponent(this.urlValue)}`)
      const data = await resp.json()

      if (data && !data.outdated) {
        this.statusTarget.classList.add('hidden')
        this.stopPoll()
        window.location.reload()
      } else {
        this.schedulePoll()
      }
    } catch {
      this.schedulePoll()
    }
  }
}
