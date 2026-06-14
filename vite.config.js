import { resolve } from 'path'
import { defineConfig } from 'vite'

export default defineConfig({
  build: {
    rollupOptions: {
      input: {
        main: resolve(__dirname, 'index.html'),
        dashboard: resolve(__dirname, 'dashboard.html'),
        courses: resolve(__dirname, 'courses.html'),
        quiz_editor: resolve(__dirname, 'quiz_editor.html'),
      },
    },
  },
})
