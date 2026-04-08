import { collection, doc, getDoc, getDocs, query, where } from 'firebase/firestore'
import { db } from '../firebase'

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
  }
}
