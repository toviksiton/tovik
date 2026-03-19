import { defineConfig } from 'vite'
import vue from '@vitejs/plugin-vue'

export default defineConfig({
  plugins: [vue()],
  base: './',
  build: {
    outDir: 'dist',
    assetsInlineLimit: 0,
  },
  server: {
    port: 5173,
    host: 'localhost',
    proxy: {
      '/api/alerts': {
        target: 'https://www.oref.org.il',
        changeOrigin: true,
        rewrite: (path) => '/WarningMessages/alert/alerts.json',
        headers: {
          'X-Requested-With': 'XMLHttpRequest',
          'Referer': 'https://www.oref.org.il/',
        },
      },
    },
  },
})
