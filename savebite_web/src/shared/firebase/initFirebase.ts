import { FirebaseApp, getApp, getApps, initializeApp } from 'firebase/app'

// Uses the same Firebase project as the mobile app (from FlutterFire web options).
// This is safe to ship to clients (public config).
const firebaseConfig = {
  apiKey: 'AIzaSyCxS2Kc5j46iaxGxNb2YAsN0Ln1FN_HUQk',
  authDomain: 'savebite-1fd01.firebaseapp.com',
  projectId: 'savebite-1fd01',
  storageBucket: 'savebite-1fd01.firebasestorage.app',
  messagingSenderId: '261732256114',
  appId: '1:261732256114:web:9734f5a56529dba5e375eb',
  measurementId: 'G-5KZRNDKKCB',
}

export function initFirebase(): FirebaseApp {
  if (getApps().length > 0) return getApp()
  return initializeApp(firebaseConfig)
}

