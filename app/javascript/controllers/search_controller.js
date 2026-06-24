import { Controller } from '@hotwired/stimulus'

// Debounced search. Re-submits the form a short delay after the user stops
// typing rather than on every keystroke, and restores focus afterwards so the
// query can be refined without clicking back into the box.
export default class extends Controller {
  static targets = ['input']
  static values = { delay: { type: Number, default: 150 } }

  connect() {
    // After a search navigation the form re-renders with the query value; put
    // the cursor back at the end so typing continues seamlessly. Skipped when
    // empty so navigating to a normal view doesn't steal focus.
    if (this.hasInputTarget && this.inputTarget.value) {
      const input = this.inputTarget
      input.focus()
      input.setSelectionRange(input.value.length, input.value.length)
    }
  }

  submit() {
    clearTimeout(this.timer)
    this.timer = setTimeout(() => this.element.requestSubmit(), this.delayValue)
  }

  // Enter submits immediately (native), so drop any pending debounced submit.
  cancel() {
    clearTimeout(this.timer)
  }

  disconnect() {
    clearTimeout(this.timer)
  }
}
