import { Controller } from '@hotwired/stimulus'

// Reveals hidden content (e.g. the overflow tags) and removes its own trigger.
export default class extends Controller {
  static targets = ['more', 'trigger']

  show() {
    this.moreTargets.forEach(el => el.classList.remove('hidden'))
    this.triggerTarget.remove()
  }
}
