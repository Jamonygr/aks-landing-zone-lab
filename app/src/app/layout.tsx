import type { Metadata } from 'next';
import { IBM_Plex_Mono, Orbitron, Space_Grotesk } from 'next/font/google';
import Link from 'next/link';
import './globals.css';

const spaceGrotesk = Space_Grotesk({
  subsets: ['latin'],
  variable: '--font-display',
});

const orbitron = Orbitron({
  subsets: ['latin'],
  weight: ['500', '700'],
  variable: '--font-heading',
});

const ibmPlexMono = IBM_Plex_Mono({
  subsets: ['latin'],
  weight: ['400', '500'],
  variable: '--font-mono',
});

export const metadata: Metadata = {
  title: 'AKS Lab App',
  description: 'Full web application for running and tracking an AKS landing zone lab.',
};

export default function RootLayout({
  children,
}: {
  children: React.ReactNode;
}) {
  return (
    <html lang="en" className={`${spaceGrotesk.variable} ${orbitron.variable} ${ibmPlexMono.variable}`}>
      <body className="synthwave-theme min-h-screen bg-slate-50 text-slate-900 antialiased">
        <div className="mesh-bg" aria-hidden="true" />
        <nav className="app-shell-nav sticky top-0 z-40 border-b border-slate-200/70 bg-white/75 backdrop-blur-md">
          <div className="mx-auto flex h-16 max-w-7xl items-center justify-between px-4 sm:px-6 lg:px-8">
            <Link href="/" className="app-shell-brand text-base font-semibold tracking-tight text-slate-900">
              AKS Learning Hub
            </Link>
            <div className="hidden items-center gap-6 text-sm font-medium text-slate-700 md:flex">
              <Link href="/" className="hover:text-sky-700">Dashboard</Link>
              <Link href="/labs" className="hover:text-sky-700">Modules</Link>
              <Link href="/labs#module-runbook" className="hover:text-sky-700">Runbook</Link>
              <Link href="/journal" className="hover:text-sky-700">Journal</Link>
              <Link href="/health" className="hover:text-sky-700">Health</Link>
            </div>
          </div>
        </nav>
        <main className="relative">{children}</main>
        <footer className="app-shell-footer mt-20 border-t border-slate-200 bg-white/80">
          <div className="mx-auto max-w-7xl px-4 py-10 text-sm text-slate-600 sm:px-6 lg:px-8">
            <p className="font-medium text-slate-800">AKS Learning Hub</p>
            <p className="mt-1">Hands-on Kubernetes platform engineering on Azure.</p>
            <p className="mt-2 text-xs font-mono tracking-tight text-slate-500">
              Node: {process.env.KUBERNETES_NODE || 'local'}
            </p>
          </div>
        </footer>
      </body>
    </html>
  );
}
