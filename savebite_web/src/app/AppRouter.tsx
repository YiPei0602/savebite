import { BrowserRouter, Routes, Route, Navigate } from 'react-router-dom'
import { LoginPage } from '@/features/auth/pages/LoginPage'
import { AppLayout } from '@/shared/components/Layout/AppLayout'
import { ProtectedRoute } from '@/shared/components/Common/ProtectedRoute'
import { DashboardPage } from '@/features/dashboard/pages/DashboardPage'
import { UsersListPage } from '@/features/users/pages/UsersListPage'
import { UserDetailsPage } from '@/features/users/pages/UserDetailsPage'
import { DonationsPage } from '@/features/donations/pages/DonationsPage'
import { ProfilePage } from '@/features/profile/pages/ProfilePage'

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
          <Route path="dashboard" element={<DashboardPage />} />
          <Route path="users" element={<UsersListPage />} />
          <Route path="users/:id" element={<UserDetailsPage />} />
          <Route path="donations" element={<DonationsPage />} />
          <Route path="profile" element={<ProfilePage />} />
        </Route>

        {/* 404 */}
        <Route path="*" element={<Navigate to="/dashboard" replace />} />
      </Routes>
    </BrowserRouter>
  )
}
