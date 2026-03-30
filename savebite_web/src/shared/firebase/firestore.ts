import { getFirestore } from 'firebase/firestore'
import { initFirebase } from './initFirebase'

// Must initialize the app before getFirestore(); static imports load App before main's initFirebase() runs.
const app = initFirebase()
export const db = getFirestore(app)

