import Link from 'next/link';
import { ReactNode } from 'react';

interface AdminLayoutProps {
  children: ReactNode;
}

/**
 * AdminLayout component
 * Provides a consistent layout for all admin pages with navigation
 */
export default function AdminLayout({ children }: AdminLayoutProps) {
  return (
    <div className="min-h-screen bg-gray-50">
      {/* Header */}
      <header className="bg-white shadow">
        <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
          <div className="flex justify-between items-center py-6">
            <div className="flex items-center gap-8">
              <h1 className="text-3xl font-bold text-gray-900">
                QR Menu Admin
              </h1>
              <nav className="flex gap-4">
                <Link
                  href="/admin"
                  className="text-gray-600 hover:text-gray-900 transition-colors"
                >
                  Dashboard
                </Link>
                <Link
                  href="/"
                  className="text-gray-600 hover:text-gray-900 transition-colors"
                >
                  Main Site
                </Link>
              </nav>
            </div>
            <div className="flex items-center gap-4">
              <a
                href="/api/auth/logout"
                className="bg-red-600 text-white px-4 py-2 rounded hover:bg-red-700 transition-colors"
              >
                Logout
              </a>
            </div>
          </div>
        </div>
      </header>

      {/* Main Content */}
      <main className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-8">
        {children}
      </main>

      {/* Footer */}
      <footer className="bg-white border-t mt-12">
        <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-6">
          <p className="text-center text-gray-500 text-sm">
            QR Menu Admin Dashboard &copy; {new Date().getFullYear()}
          </p>
        </div>
      </footer>
    </div>
  );
}
