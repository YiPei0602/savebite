import { collection, getDocs, orderBy, query } from 'firebase/firestore'
import { db } from '@/shared/firebase/firestore'
import type { DonationRecord } from '@/shared/types/models'

function toIsoString(v: unknown): string {
  // Firestore Timestamp has toDate()
  // eslint-disable-next-line @typescript-eslint/no-explicit-any
  const anyV: any = v
  if (anyV && typeof anyV.toDate === 'function') {
    return anyV.toDate().toISOString()
  }
  if (v instanceof Date) return v.toISOString()
  if (typeof v === 'string') return new Date(v).toISOString()
  return new Date(0).toISOString()
}

function mapDonationDoc(id: string, data: Record<string, unknown>): DonationRecord {
  return {
    id: (data.id as string | undefined) || id,
    merchantName: (data.merchantName as string | undefined) || '',
    ngoName: (data.ngoName as string | undefined) || '',
    items: (Array.isArray(data.items) ? data.items : []) as string[],
    quantity: (typeof data.quantity === 'number' ? data.quantity : Number(data.quantity || 0)) as number,
    status: ((data.status as DonationRecord['status'] | undefined) || 'completed'),
    deliveryDate: toIsoString(data.deliveryDate),
    createdAt: toIsoString(data.createdAt),
  }
}

export async function getDonations(): Promise<DonationRecord[]> {
  const q = query(collection(db, 'donations'), orderBy('createdAt', 'desc'))
  const snap = await getDocs(q)
  return snap.docs.map((d) => mapDonationDoc(d.id, d.data() as Record<string, unknown>))
}

