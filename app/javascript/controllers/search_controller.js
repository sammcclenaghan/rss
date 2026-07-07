import { Controller } from '@hotwired/stimulus'
import { debounce } from '../helpers/timing_helpers'

// Debounced search. Re-submits the form a short delay after the user stops
// typing rather than on every keystroke, and restores focus afterwards so the
// query can be refined without clicking back into the box.
export default class extends Controller {
  static targets = ['input']
  static values = { delay: { type: Number, default: 150 } }

  connect() {
    this.debouncedSubmit = debounce(() => this.element.requestSubmit(), this.delayValue)
    this.#restoreFocus()
  }

  disconnect() {
    this.debouncedSubmit.cancel()
  }

  submit() {
    this.debouncedSubmit()
  }

  // Enter submits immediately (native), so drop any pending debounced submit.
  cancel() {
    this.debouncedSubmit.cancel()
  }

  // After a search navigation the form re-renders with the query value; put
  // the cursor back at the end so typing continues seamlessly. Skipped when
  // empty so navigating to a normal view doesn't steal focus.
  #restoreFocus() {
    if (!this.hasInputTarget || !this.inputTarget.value) return

    const input = this.inputTarget
    input.focus()
    input.setSelectionRange(input.value.length, input.value.length)
  }
}
