import '@hotwired/turbo'
import { Application } from '@hotwired/stimulus'
import { registerControllers } from 'stimulus-vite-helpers'

// Boot Stimulus and auto-register every controller.
const application = Application.start()
const controllers = import.meta.glob('../controllers/**/*_controller.js', { eager: true })
registerControllers(application, controllers)
