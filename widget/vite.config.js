import { defineConfig } from 'vite'

export default defineConfig({
  build: {
    lib: {
      entry: 'src/chat-widget.js',
      name: 'BMIWidget',
      fileName: 'chat-widget',
      formats: ['iife', 'es']
    },
    rollupOptions: {
      output: {
        // Ensure the library is exposed as a global variable
        globals: {
          // No external dependencies for now
        }
      }
    },
    minify: 'terser',
    sourcemap: true
  },
  server: {
    port: 3004,
    host: '0.0.0.0'
  }
}) 