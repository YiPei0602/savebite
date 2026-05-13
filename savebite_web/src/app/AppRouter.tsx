import { BrowserRouter, Routes, Route, Navigate } from 'react-router-dom'
import { LoginPage } from '@/features/auth/pages/LoginPage'
import { AppLayout } from '@/shared/components/Layout/AppLayout'
import { ProtectedRoute } from '@/shared/components/Common/ProtectedRoute'
import { DashboardPage } from '@/features/dashboard/pages/DashboardPage'
import { UsersListPage } from '@/features/users/pages/UsersListPage'
import { UserDetailsPage } from '@/features/users/pages/UserDetailsPage'
import { ProfilePage } from '@/features/profile/pages/ProfilePage'

export function AppRouter() {
  return (
    <BrowserRouter>
      <Routes>
        <Route path="/login" element={<LoginPage />} />
        <Route path="/" element={<Navigate to="/login" replace />} />

        <Route
          element={
            <ProtectedRoute>
              <AppLayout />
            </ProtectedRoute>
          }
        >
          <Route path="dashboard" element={<DashboardPage />} />
          <Route path="users" element={<UsersListPage />} />
          <Route path="users/:id" element={<UserDetailsPage />} />
          <Route path="profile" element={<ProfilePage />} />
        </Route>

        <Route path="*" element={<Navigate to="/login" replace />} />
      </Routes>
    </BrowserRouter>
  )
}
