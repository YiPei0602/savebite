// Mock Data for SaveBite Admin Dashboard

export interface User {
  id: string
  name: string
  email: string
  role: 'consumer' | 'merchant'
  status: 'active' | 'suspended' | 'inactive'
  phone?: string
  createdAt: string
  lastLogin?: string
}

export interface Order {
  id: string
  consumerId: string
  consumerName: string
  merchantId: string
  merchantName: string
  items: Array<{ name: string; quantity: number; price: number }>
  total: number
  status: 'completed' | 'pending' | 'cancelled'
  createdAt: string
}

export interface AdminProfile {
  id: string
  name: string
  email: string
  phone: string
  role: 'admin'
  createdAt: string
}

// Mock Users Data
export const mockUsers: User[] = [
  {
    id: '1',
    name: 'John Doe',
    email: 'john.doe@example.com',
    role: 'consumer',
    status: 'active',
    phone: '+60123456789',
    createdAt: '2025-01-15T10:00:00Z',
    lastLogin: '2025-12-20T14:30:00Z',
  },
  {
    id: '2',
    name: 'Jane Smith',
    email: 'jane.smith@example.com',
    role: 'consumer',
    status: 'active',
    phone: '+60123456790',
    createdAt: '2025-02-20T11:00:00Z',
    lastLogin: '2025-12-19T09:15:00Z',
  },
  {
    id: '3',
    name: "The Baker's Cottage",
    email: 'baker@example.com',
    role: 'merchant',
    status: 'active',
    phone: '+60123456791',
    createdAt: '2025-01-10T08:00:00Z',
    lastLogin: '2025-12-20T16:45:00Z',
  },
  {
    id: '4',
    name: 'Green Food Market',
    email: 'greenmarket@example.com',
    role: 'merchant',
    status: 'active',
    phone: '+60123456792',
    createdAt: '2025-03-05T09:30:00Z',
    lastLogin: '2025-12-18T10:20:00Z',
  },
  {
    id: '5',
    name: 'Food Rescue Malaysia',
    email: 'foodrescue@example.com',
    role: 'merchant',
    status: 'active',
    phone: '+60123456793',
    createdAt: '2025-01-25T12:00:00Z',
    lastLogin: '2025-12-20T11:00:00Z',
  },
  {
    id: '6',
    name: 'Community Kitchen',
    email: 'community@example.com',
    role: 'merchant',
    status: 'active',
    phone: '+60123456794',
    createdAt: '2025-02-15T13:00:00Z',
    lastLogin: '2025-12-19T15:30:00Z',
  },
  {
    id: '7',
    name: 'Bob Wilson',
    email: 'bob.wilson@example.com',
    role: 'consumer',
    status: 'suspended',
    phone: '+60123456795',
    createdAt: '2025-04-10T10:00:00Z',
    lastLogin: '2025-12-10T08:00:00Z',
  },
  {
    id: '8',
    name: 'Sweet Treats Bakery',
    email: 'sweettreats@example.com',
    role: 'merchant',
    status: 'active',
    phone: '+60123456796',
    createdAt: '2025-05-20T09:00:00Z',
    lastLogin: '2025-12-20T17:00:00Z',
  },
]

// Mock Orders Data
export const mockOrders: Order[] = [
  {
    id: 'O001',
    consumerId: '1',
    consumerName: 'John Doe',
    merchantId: '3',
    merchantName: "The Baker's Cottage",
    items: [
      { name: 'Pastry Box', quantity: 2, price: 8.0 },
      { name: 'Bread Bundle', quantity: 1, price: 5.0 },
    ],
    total: 21.0,
    status: 'completed',
    createdAt: '2025-12-20T09:00:00Z',
  },
  {
    id: 'O002',
    consumerId: '2',
    consumerName: 'Jane Smith',
    merchantId: '4',
    merchantName: 'Green Food Market',
    items: [{ name: 'Fresh Vegetables', quantity: 1, price: 12.0 }],
    total: 12.0,
    status: 'completed',
    createdAt: '2025-12-19T10:00:00Z',
  },
]

// Mock Admin Profile
export const mockAdminProfile: AdminProfile = {
  id: 'admin1',
  name: 'Admin User',
  email: 'admin@savebite.com',
  phone: '+60123456700',
  role: 'admin',
  createdAt: '2025-01-01T00:00:00Z',
}

// Helper functions
export const getUsersByRole = (role: string): User[] => {
  if (!role || role === 'all') return mockUsers
  return mockUsers.filter((user) => user.role === role)
}

export const getUsersByStatus = (status: string): User[] => {
  if (!status || status === 'all') return mockUsers
  return mockUsers.filter((user) => user.status === status)
}

// Calculate statistics (mock / demo only)
export const getDashboardStats = () => {
  const now = new Date()
  const thirtyDaysAgo = new Date(now.getTime() - 30 * 24 * 60 * 60 * 1000)

  const newMerchants = mockUsers.filter(
    (user) => user.role === 'merchant' && new Date(user.createdAt) >= thirtyDaysAgo,
  ).length

  const newConsumers = mockUsers.filter(
    (user) => user.role === 'consumer' && new Date(user.createdAt) >= thirtyDaysAgo,
  ).length

  const completedOrders = mockOrders.filter((o) => o.status === 'completed').length

  return {
    totalUsers: mockUsers.length,
    newMerchants,
    newConsumers,
    completedOrders,
  }
}
