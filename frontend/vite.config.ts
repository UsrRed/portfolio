import { defineConfig } from 'vite'
import vue from '@vitejs/plugin-vue'

// https://vite.dev/config/
export default defineConfig({
  plugins: [vue()],
  server: {
    proxy: {
      // En dev, réutilise le nginx du docker-compose (port 3000)
      '/api': 'http://localhost:3000',
      '/user-uploads': 'http://localhost:3000',
    },
  },
})
