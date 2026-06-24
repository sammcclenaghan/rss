import { Controller } from '@hotwired/stimulus'

// Vim-style keyboard navigation for the post list. Drives the existing
// post-read controls and filter links rather than duplicating their logic, so
// behaviour stays in one place.
//
//   j / k        next / previous post
//   o / Enter    open the selected post (marks it read)
//   m            toggle read/unread on the selected post
//   u            toggle the "unread only" filter
//   Shift+A      mark all read (current scope)
//   g g / G      first / last post
//   /            focus search
//   ?            toggle this help
//   Escape       close help / blur search
export default class extends Controller {
  static targets = ['help', 'unreadToggle', 'markAll']

  connect() {
    this.index = -1
    this.lastG = 0
    this.onKeydown = this.handle.bind(this)
    window.addEventListener('keydown', this.onKeydown)
  }

  disconnect() {
    window.removeEventListener('keydown', this.onKeydown)
  }

  get posts() {
    return Array.from(this.element.querySelectorAll('.rss-post'))
  }

  handle(event) {
    if (event.metaKey || event.ctrlKey || event.altKey) return

    const el = document.activeElement
    const typing = el && (el.tagName === 'INPUT' || el.tagName === 'TEXTAREA' || el.tagName === 'SELECT' || el.isContentEditable)

    if (event.key === 'Escape') {
      if (typing) el.blur()
      this.hideHelp()
      return
    }
    if (typing) return

    switch (event.key) {
      case 'j': this.move(1); break
      case 'k': this.move(-1); break
      case 'o':
      case 'Enter': this.open(); break
      case 'm': this.toggleRead(); break
      case 'u': this.click(this.unreadToggleTarget, this.hasUnreadToggleTarget); break
      case 'A': this.click(this.markAllTarget, this.hasMarkAllTarget); break
      case 'G': this.select(this.posts.length - 1); break
      case 'g':
        if (Date.now() - this.lastG < 500) { this.select(0); this.lastG = 0 } else { this.lastG = Date.now() }
        break
      case '/': this.focusSearch(); break
      case '?': this.toggleHelp(); break
      default: return
    }
    event.preventDefault()
  }

  move(delta) {
    const posts = this.posts
    if (!posts.length) return
    const start = this.index < 0 ? (delta > 0 ? 0 : posts.length - 1) : this.index + delta
    this.select(start)
  }

  select(i) {
    const posts = this.posts
    if (!posts.length) return
    posts[this.index]?.classList.remove('is-selected')
    this.index = Math.max(0, Math.min(posts.length - 1, i))
    const el = posts[this.index]
    el.classList.add('is-selected')
    el.scrollIntoView({ block: 'nearest' })
  }

  current() {
    if (this.index < 0) this.select(0)
    return this.posts[this.index]
  }

  open() {
    this.current()?.querySelector('a[target="_blank"]')?.click()
  }

  toggleRead() {
    this.current()?.querySelector('[data-post-read-target="toggle"]')?.click()
  }

  focusSearch() {
    const input = this.element.querySelector('input[name="query"]')
    if (input) { input.focus(); input.select() }
  }

  toggleHelp() {
    this.helpTarget?.classList.toggle('hidden')
  }

  hideHelp() {
    this.helpTarget?.classList.add('hidden')
  }

  // Closes the help overlay when the backdrop (not the panel) is clicked.
  closeHelp(event) {
    if (event.target === this.helpTarget) this.hideHelp()
  }

  click(target, present) {
    if (present) target.click()
  }
}
