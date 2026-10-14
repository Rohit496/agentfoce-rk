import { defineConfig } from 'vite';
import react from '@vitejs/plugin-react';

// The port must match the CSP Trusted Site and the baseUrl of accountEmbeddedReactApp.
export default defineConfig({
    plugins: [react()],
    server: { port: 5180, strictPort: true },
    build: { target: 'es2022' }
});
