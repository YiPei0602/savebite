import {
  collection,
  deleteDoc,
  doc,
  getDoc,
  getDocs,
  orderBy,
  query,
  updateDoc,
} from 'firebase/firestore'
import { db } from '@/shared/firebase/firestore'
import type { UserRecord, UserStatus } from '@/shared/types/models'

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

function displayNameFromFirestore(data: Record<string, unknown>): string {
  const first = String(data.firstName ?? '').trim()
  const last = String(data.lastName ?? '').trim()
  const joined = [first, last].filter(Boolean).join(' ')
  if (joined) return joined
  const legacy = (data.name as string | undefined)?.trim()
  return legacy || ''
}

function mapUserDoc(id: string, data: Record<string, unknown>): UserRecord {
  const uid = (data.uid as string | undefined) || id
  return {
    id,
    uid,
    name: displayNameFromFirestore(data),
    email: (data.email as string | undefined) || '',
    role: ((data.role as UserRecord['role'] | undefined) || 'consumer'),
    status: ((data.status as UserStatus | undefined) || 'active'),
    createdAt: toIsoString(data.createdAt),
  }
}

export async function getUsers(): Promise<UserRecord[]> {
  const q = query(collection(db, 'users'), orderBy('createdAt', 'desc'))
  const snap = await getDocs(q)
  return snap.docs.map((d) => mapUserDoc(d.id, d.data() as Record<string, unknown>))
}

export async function getUserById(id: string): Promise<UserRecord | null> {
  const ref = doc(db, 'users', id)
  const snap = await getDoc(ref)
  if (!snap.exists()) return null
  return mapUserDoc(snap.id, snap.data() as Record<string, unknown>)
}

function splitDisplayName(full: string): { firstName: string; lastName: string } {
  const t = full.trim()
  if (!t) return { firstName: '', lastName: '' }
  const i = t.indexOf(' ')
  if (i === -1) return { firstName: t, lastName: '' }
  return { firstName: t.slice(0, i).trim(), lastName: t.slice(i + 1).trim() }
}

function buildUserUpdatePayload(
  patch: Partial<Pick<UserRecord, 'name' | 'email' | 'role' | 'status'>>,
): Record<string, string> {
  const out: Record<string, string> = {}
  if (patch.name !== undefined) {
    out.name = patch.name
    const { firstName, lastName } = splitDisplayName(patch.name)
    out.firstName = firstName
    out.lastName = lastName
  }
  if (patch.email !== undefined) out.email = patch.email
  if (patch.role !== undefined) out.role = patch.role
  if (patch.status !== undefined) out.status = patch.status
  return out
}

export async function updateUser(
  id: string,
  patch: Partial<Pick<UserRecord, 'name' | 'email' | 'role' | 'status'>>,
): Promise<void> {
  const data = buildUserUpdatePayload(patch)
  if (Object.keys(data).length === 0) return
  const ref = doc(db, 'users', id)
  await updateDoc(ref, data)
}

/** Sets `users/{userId}.status` to `"active"` or `"suspended"` (or `"inactive"`). */
export async function updateUserStatus(userId: string, status: UserStatus): Promise<void> {
  const ref = doc(db, 'users', userId)
  await updateDoc(ref, { status })
}

export async function deleteUser(userId: string): Promise<void> {
  const ref = doc(db, 'users', userId)
  await deleteDoc(ref)
}

