export type UserRole = 'consumer' | 'merchant' | 'ngo'
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

export type DonationStatus = 'completed' | 'pending' | 'cancelled'

export interface DonationRecord {
  id: string
  merchantName: string
  ngoName: string
  items: string[]
  quantity: number
  status: DonationStatus
  deliveryDate: string
  createdAt: string
}

