import { getAuth, signInWithEmailAndPassword } from 'firebase/auth'
import { initFirebase } from './initFirebase'

const ADMIN_EMAIL = 'admin@gmail.com'
const ADMIN_PASSWORD = '12345678'

export async function adminLogin(): Promise<void> {
  const app = initFirebase()
  const auth = getAuth(app)
  await signInWithEmailAndPassword(auth, ADMIN_EMAIL, ADMIN_PASSWORD)
  console.log('Admin Firebase Auth: signed in successfully')
  window.location.reload()
}
