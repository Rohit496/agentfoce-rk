import { defineConfig } from 'vite';

// The port must match the CSP Trusted Site and the baseUrl of accountEmbeddedExternalApp.
export default defineConfig({
    server: { port: 5183, strictPort: true },
    build: { target: 'es2022' }
});
