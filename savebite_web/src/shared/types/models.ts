export type UserRole = 'consumer' | 'merchant'
export type UserStatus = 'active' | 'suspended' | 'inactive'

export interface UserRecord {
  id: string
  uid: string
  name: string
  email: string
  role: UserRole
  status: UserStatus
  createdAt: string
}

/** Firestore `orders` collection (subset used by admin dashboard). */
export interface OrderRecord {
  id: string
  orderStatus: string
  /** ISO string from Firestore `paidAt` */
  paidAt: string
}

