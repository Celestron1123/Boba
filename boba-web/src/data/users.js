import { collection, doc, getDoc, getDocs, query, setDoc, where } from 'firebase/firestore'
import { db } from '../firebase'

export const USER_ROLE_OPTIONS = [
  { value: 'PATIENT', label: 'Patient' },
  { value: 'THERAPIST', label: 'Therapist' },
]

async function getUserByUsername(username) {
  const normalizedUsername = username.trim()

  const userRef = doc(db, 'users', normalizedUsername)
  const directSnapshot = await getDoc(userRef)

  if (directSnapshot.exists()) {
    return {
      id: directSnapshot.id,
      ...directSnapshot.data(),
    }
  }

  const usersQuery = query(collection(db, 'users'), where('username', '==', normalizedUsername))
  const querySnapshot = await getDocs(usersQuery)
  const matchedUser = querySnapshot.docs[0]

  if (!matchedUser) {
    return null
  }

  return {
    id: matchedUser.id,
    ...matchedUser.data(),
  }
}

export async function authenticateUser({ username, password }) {
  const normalizedUsername = username.trim()
  const normalizedPassword = password.trim()

  if (!normalizedUsername || !normalizedPassword) {
    throw new Error('Username and password are required.')
  }

  const user = await getUserByUsername(normalizedUsername)

  if (!user || user.password !== normalizedPassword) {
    throw new Error('Login failed. Incorrect username or password.')
  }

  return {
    username: user.username ?? normalizedUsername,
    role: user.role ?? 'PATIENT',
  }
}

export async function registerUser({ username, password, role = 'PATIENT' }) {
  const normalizedUsername = username.trim()
  const normalizedPassword = password.trim()
  const normalizedRole = role.trim() || 'PATIENT'

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
    role: normalizedRole,
  })

  return {
    username: normalizedUsername,
    role: normalizedRole,
  }
}

export async function getUserProfile(username) {
  const normalizedUsername = username.trim()

  if (!normalizedUsername) {
    throw new Error('Username is required.')
  }

  const userRef = doc(db, 'users', normalizedUsername)
  const snapshot = await getDoc(userRef)

  if (!snapshot.exists()) {
    throw new Error('User not found.')
  }

  const data = snapshot.data()

  return {
    username: normalizedUsername,
    password: data.password ?? '',
    email: data.email ?? '',
    name: data.name ?? '',
    birthday: data.birthday ?? '',
    role: data.role ?? 'PATIENT',
  }
}

export async function updateUserProfile({ username, password, email, name, birthday, role }) {
  const normalizedUsername = username.trim()

  if (!normalizedUsername) {
    throw new Error('Username is required.')
  }

  const userRef = doc(db, 'users', normalizedUsername)
  const existingUser = await getDoc(userRef)

  if (!existingUser.exists()) {
    throw new Error('User not found.')
  }

  const payload = {
    username: normalizedUsername,
    password: password.trim(),
    email: email.trim(),
    name: name.trim(),
    birthday: birthday.trim(),
    role: role?.trim() || 'PATIENT',
  }

  await setDoc(userRef, payload, { merge: true })

  return payload
}
