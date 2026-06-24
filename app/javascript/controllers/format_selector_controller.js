import { Controller } from '@hotwired/stimulus'

// Active-button styling, mirrored from the reference FormatSelector.vue.
const ACTIVE_CLASSES = ['bg-gray-100', 'text-gray-900', 'dark:bg-gray-800', 'dark:text-gray-400']
const WIDTHS = { card: 'max-w-lg', list: 'max-w-2xl', compact: 'w-full' }
const MARKERS = { card: 'format-card', list: 'format-list', compact: 'format-compact' }

export default class extends Controller {
  static targets = ['container', 'button']
  static values = { storageKey: String }

  connect() {
    const saved = localStorage.getItem(this.storageKeyValue)
    this.applyFormat(saved && MARKERS[saved] ? saved : 'card')
  }

  select(event) {
    const format = event.currentTarget.dataset.format
    localStorage.setItem(this.storageKeyValue, format)
    this.applyFormat(format)
  }

  applyFormat(format) {
    // Container width per format (card → narrow, list → wide, compact → full)
    // and the marker class that drives body visibility + compact padding via CSS.
    this.containerTarget.classList.remove(...Object.values(WIDTHS), ...Object.values(MARKERS))
    this.containerTarget.classList.add(WIDTHS[format], MARKERS[format])

    // Highlight the active format button.
    this.buttonTargets.forEach(btn => {
      const isActive = btn.dataset.format === format
      ACTIVE_CLASSES.forEach(cls => btn.classList.toggle(cls, isActive))
    })
  }
}
