import { Controller } from '@hotwired/stimulus'

// Keeps a native colour swatch and a hex text input in sync. The text input is
// the one that's submitted; leaving it blank means "use the default colour", so
// the swatch is just an optional helper that never forces a value on its own.
export default class extends Controller {
  static targets = ['swatch', 'text']

  // Swatch changed -> mirror its hex into the text field.
  fromSwatch() {
    this.textTarget.value = this.swatchTarget.value.toUpperCase()
  }

  // Text changed -> if it's a valid hex, reflect it in the swatch.
  fromText() {
    const v = this.textTarget.value.trim().replace(/^#?/, '#')
    if (/^#[0-9a-fA-F]{6}$/.test(v)) this.swatchTarget.value = v
  }

  // Clear back to the default (no stored colour).
  clear() {
    this.textTarget.value = ''
    this.textTarget.focus()
  }
}
