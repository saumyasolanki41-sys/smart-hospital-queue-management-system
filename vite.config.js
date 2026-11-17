import react from '@vitejs/plugin-react'
import tailwindcss from '@tailwindcss/vite'
import { defineConfig } from 'vite'

// https://vite.dev/config/
export default defineConfig({
  plugins: [react(), tailwindcss()],
  server: {
    proxy: {
      '/api/chatbot': {
        target: 'https://smart-hospital-api.508z112c8xp8p.ap-southeast-2.cs.amazonlightsail.com',
        changeOrigin: true,
        rewrite: (path) => path.replace(/^\/api\/chatbot/, '/chat'),
      },
    },
  },
})
