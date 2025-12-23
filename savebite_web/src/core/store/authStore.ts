import { create } from 'zustand'
import { persist, createJSONStorage } from 'zustand/middleware'

export interface AdminUser {
  id: string
  email: string
  name: string
  role: 'admin'
}

interface AuthState {
  user: AdminUser | null
  token: string | null
  isAuthenticated: boolean
  login: (email: string, password: string) => Promise<void>
  logout: () => void
  setUser: (user: AdminUser, token: string) => void
}

export const useAuthStore = create<AuthState>()(
  persist(
    (set) => ({
      user: null,
      token: null,
      isAuthenticated: false,
      login: async (email: string, password: string) => {
        // TODO: Implement actual login API call
        // For now, this is a placeholder
        const mockUser: AdminUser = {
          id: '1',
          email,
          name: 'Admin User',
          role: 'admin',
        }
        const mockToken = 'mock-token'
        set({
          user: mockUser,
          token: mockToken,
          isAuthenticated: true,
        })
        // Store token in localStorage for API client
        localStorage.setItem('auth-token', mockToken)
      },
      logout: () => {
        localStorage.removeItem('auth-token')
        set({
          user: null,
          token: null,
          isAuthenticated: false,
        })
      },
      setUser: (user: AdminUser, token: string) => {
        localStorage.setItem('auth-token', token)
        set({
          user,
          token,
          isAuthenticated: true,
        })
      },
    }),
    {
      name: 'auth-storage',
      storage: createJSONStorage(() => localStorage),
    }
  )
)

