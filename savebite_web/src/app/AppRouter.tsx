import { BrowserRouter, Routes, Route, Navigate } from 'react-router-dom'
import { LoginPage } from '@/features/auth/pages/LoginPage'
import { AppLayout } from '@/shared/components/Layout/AppLayout'
import { ProtectedRoute } from '@/shared/components/Common/ProtectedRoute'
import { AnalyticsDashboardPage } from '@/features/analytics/pages/AnalyticsDashboardPage'
import { UsersListPage } from '@/features/users/pages/UsersListPage'
import { UserDetailsPage } from '@/features/users/pages/UserDetailsPage'
import { OrdersListPage } from '@/features/orders/pages/OrdersListPage'
import { DonationsPage } from '@/features/donations/pages/DonationsPage'
import { SystemActivityPage } from '@/features/system/pages/SystemActivityPage'

export function AppRouter() {
  return (
    <BrowserRouter>
      <Routes>
        {/* Public Routes */}
        <Route path="/login" element={<LoginPage />} />

        {/* Protected Routes */}
        <Route
          path="/"
          element={
            <ProtectedRoute>
              <AppLayout />
            </ProtectedRoute>
          }
        >
          <Route index element={<Navigate to="/dashboard" replace />} />
          <Route path="dashboard" element={<AnalyticsDashboardPage />} />
          <Route path="users" element={<UsersListPage />} />
          <Route path="users/:id" element={<UserDetailsPage />} />
          <Route path="orders" element={<OrdersListPage />} />
          <Route path="donations" element={<DonationsPage />} />
          <Route path="analytics" element={<AnalyticsDashboardPage />} />
          <Route path="system" element={<SystemActivityPage />} />
        </Route>

        {/* 404 */}
        <Route path="*" element={<Navigate to="/dashboard" replace />} />
      </Routes>
    </BrowserRouter>
  )
}

