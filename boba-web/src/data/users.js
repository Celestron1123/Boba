import { doc, getDoc, setDoc } from 'firebase/firestore'
import { db } from '../firebase'

export async function registerUser({ username, password }) {
  const normalizedUsername = username.trim()
  const normalizedPassword = password.trim()

  if (!normalizedUsername || !normalizedPassword) {
    throw new Error('Username and password are required.')
  }

  const userRef = doc(db, 'users', normalizedUsername)
  const existingUser = await getDoc(userRef)

  if (existingUser.exists()) {
    throw new Error('User already exists.')
  }

  await setDoc(userRef, {
    username: normalizedUsername,
    password: normalizedPassword,
  })

  return {
    username: normalizedUsername,
  }
}
