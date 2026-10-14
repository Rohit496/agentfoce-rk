/** @type {import('next').NextConfig} */
const nextConfig = {
    // The app is fully client-side, so build it as static files (out/) that any HTTPS host can serve.
    output: 'export',
    // Keep the Next.js dev badge out of the embedded frame.
    devIndicators: false,
    // This app lives inside a larger repo that has its own lockfile; pin the root to this folder.
    turbopack: { root: import.meta.dirname }
};

export default nextConfig;
