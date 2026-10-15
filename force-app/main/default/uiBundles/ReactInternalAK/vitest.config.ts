import { defineConfig } from 'vitest/config';
import react from '@vitejs/plugin-react';

export default defineConfig({
  plugins: [react()],
  test: {
    globals: true,
    environment: 'jsdom',
    setupFiles: './vitest.setup.ts',
    // Only run unit/component tests under src/. The e2e/ suite uses Playwright's
    // own runner (`@playwright/test`), which throws if executed by Vitest.
    include: [
      'src/**/*.{test,spec}.{js,mjs,cjs,ts,mts,cts,jsx,tsx}',
      'src/**/__tests__/**/*.{js,mjs,cjs,ts,mts,cts,jsx,tsx}',
    ],
    exclude: ['**/node_modules/**', '**/dist/**', '**/build/**', 'e2e/**'],
    // This bundle has no unit tests yet; don't fail `npm test` because of that.
    passWithNoTests: true,
  },
});
