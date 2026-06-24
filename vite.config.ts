import { defineConfig } from 'vite'
import RubyPlugin from 'vite-plugin-ruby'
import tailwindcss from '@tailwindcss/vite'
import StimulusHMR from 'vite-plugin-stimulus-hmr'
import FullReload from 'vite-plugin-full-reload'

export default defineConfig({
  plugins: [
    RubyPlugin(),
    tailwindcss(),
    StimulusHMR(),
    FullReload(['config/routes.rb', 'app/views/**/*']),
  ],
})
