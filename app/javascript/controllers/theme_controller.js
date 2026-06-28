import { Controller } from '@hotwired/stimulus'

// Appearance menu. Persists the user's choice in localStorage under `theme`
// (one of 'system' | 'light' | 'dark' | 'vercel' | 'gruvbox') and applies it to
// <html>. The same resolution runs in an inline <head> script on first paint to
// avoid a flash of the wrong theme; this controller keeps the menu in sync and
// re-resolves when the OS preference changes while 'system' is selected.
//
// `.dark` on <html> drives Tailwind's `dark:` utilities; `data-theme` selects
// the palette (which remaps the gray ramp in application.css).
const STORAGE_KEY = 'theme'
const DARK_THEMES = ['dark', 'vercel', 'gruvbox']

export default class extends Controller {
  static targets = ['menu', 'option']

  connect() {
    this.mql = window.matchMedia('(prefers-color-scheme: dark)')
    this.onSystemChange = () => { if (this.current === 'system') this.apply('system') }
    this.mql.addEventListener('change', this.onSystemChange)
    this.markActive()
  }

  disconnect() {
    this.mql?.removeEventListener('change', this.onSystemChange)
  }

  get current() {
    return localStorage.getItem(STORAGE_KEY) || 'system'
  }

  toggle() {
    this.menuTarget.classList.toggle('hidden')
  }

  close() {
    this.menuTarget.classList.add('hidden')
  }

  closeOutside(event) {
    if (!this.element.contains(event.target)) this.close()
  }

  select(event) {
    const theme = event.currentTarget.dataset.theme
    localStorage.setItem(STORAGE_KEY, theme)
    this.apply(theme)
    this.close()
  }

  apply(theme) {
    const effective = theme === 'system'
      ? (this.mql.matches ? 'dark' : 'light')
      : theme
    const el = document.documentElement
    el.dataset.theme = effective
    el.classList.toggle('dark', DARK_THEMES.includes(effective))
    this.markActive()
  }

  markActive() {
    const cur = this.current
    this.optionTargets.forEach((btn) => {
      const active = btn.dataset.theme === cur
      btn.setAttribute('aria-pressed', active ? 'true' : 'false')
      btn.querySelector('.theme-check')?.classList.toggle('hidden', !active)
    })
  }
}
