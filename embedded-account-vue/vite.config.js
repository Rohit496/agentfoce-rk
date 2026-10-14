import { defineConfig } from 'vite';
import vue from '@vitejs/plugin-vue';

// The port must match the CSP Trusted Site and the baseUrl of accountEmbeddedVueApp.
export default defineConfig({
    plugins: [vue()],
    server: { port: 5181, strictPort: true },
    build: { target: 'es2022' }
});
