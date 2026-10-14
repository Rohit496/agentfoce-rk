import './globals.css';

export const metadata = {
    title: 'Account Insights (Next.js)'
};

export default function RootLayout({ children }) {
    return (
        <html lang="en">
            <body>{children}</body>
        </html>
    );
}
