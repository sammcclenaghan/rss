import { Controller } from '@hotwired/stimulus'

// Generic class toggle. Buttons anywhere within the controller's scope call
// toggle() to flip the configured class on the controller element — used for
// the off-canvas mobile sidebar (`sidebar-open` on the page wrapper).
export default class extends Controller {
  static classes = ['toggle']

  toggle() {
    this.element.classList.toggle(this.toggleClass)
  }
}
