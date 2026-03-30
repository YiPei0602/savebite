import { collection, getDocs } from 'firebase/firestore'
import { db } from '@/shared/firebase/firestore'
import type { OrderRecord } from '@/shared/types/models'

function toIsoString(v: unknown): string {
  // eslint-disable-next-line @typescript-eslint/no-explicit-any
  const anyV: any = v
  if (anyV && typeof anyV.toDate === 'function') {
    return anyV.toDate().toISOString()
  }
  if (v instanceof Date) return v.toISOString()
  if (typeof v === 'string') return new Date(v).toISOString()
  return new Date(0).toISOString()
}

function mapOrderDoc(id: string, data: Record<string, unknown>): OrderRecord {
  return {
    id,
    orderStatus: String(data.orderStatus ?? ''),
    paidAt: data.paidAt != null ? toIsoString(data.paidAt) : '',
  }
}

export async function getOrders(): Promise<OrderRecord[]> {
  const snap = await getDocs(collection(db, 'orders'))
  return snap.docs.map((d) => mapOrderDoc(d.id, d.data() as Record<string, unknown>))
}
