import { useEffect, useState } from 'react'
import { getAuth, onAuthStateChanged } from 'firebase/auth'
import { initFirebase } from '@/shared/firebase/initFirebase'
import { adminLogin } from '@/shared/firebase/adminLogin'

/** Temporary: ensures Firestore rules see request.auth for internal admin testing. */
export function AdminFirebaseLoginButton() {
  const [firebaseReady, setFirebaseReady] = useState(false)
  const [hasFirebaseUser, setHasFirebaseUser] = useState(false)

  useEffect(() => {
    const app = initFirebase()
    const auth = getAuth(app)
    setHasFirebaseUser(!!auth.currentUser)
    setFirebaseReady(true)
    const unsub = onAuthStateChanged(auth, (user) => {
      setHasFirebaseUser(!!user)
    })
    return unsub
  }, [])

  if (!firebaseReady || hasFirebaseUser) return null

  return (
    <button
      type="button"
      onClick={() => {
        adminLogin().catch((e) => {
          console.error('Admin Firebase Auth login failed', e)
          window.alert(e instanceof Error ? e.message : String(e))
        })
      }}
      className="text-sm font-medium px-3 py-1.5 rounded-lg bg-amber-500 text-white hover:bg-amber-600"
    >
      Admin Login
    </button>
  )
}
