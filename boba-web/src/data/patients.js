/** 
This file was written by Claude 3.7 Sonnet
It is the data for the patients of the application
*/ 


/**
 * Static fallback for local dev. Replace with Firebase-backed loading in the UI layer.
 *
 * When Firestore (or Realtime Database) is implemented, fetch documents here or in a
 * dedicated module (e.g. `src/firebase/patients.js`):
 *
 *   // Firestore example: query a collection (NoSQL documents)
 *   // import { getFirestore, collection, query, where, getDocs } from 'firebase/firestore'
 *   // const db = getFirestore(app)
 *   // const q = query(
 *   //   collection(db, 'patients'),
 *   //   where('therapistId', '==', currentTherapistUid),
 *   // )
 *   // const snapshot = await getDocs(q)
 *   // const patients = snapshot.docs.map((doc) => ({
 *   //   id: doc.id,
 *   //   name: doc.data().name,
 *   //   email: doc.data().email,
 *   //   birthday: doc.data().birthday,
 *   // }))
 *
 *   // Or subscribe for live updates: onSnapshot(q, (snapshot) => { ... })
 *
 * Use the signed-in therapist’s UID (or custom claims) from Firebase Auth when scoping queries.
 */

// src/data/patients.js
import { collection, getDocs, doc, getDoc, query, where } from 'firebase/firestore'
import { db } from '../firebase'

export async function getPatients() {
  const snapshot = await getDocs(collection(db, 'patients'))

  return snapshot.docs.map((d) => ({
    id: d.id,
    ...d.data(),
  }))
}

export async function getPatientsForTherapist(therapistId) {
  const q = query(
    collection(db, 'patients'),
    where('therapistId', '==', therapistId),
  )

  const snapshot = await getDocs(q)

  return snapshot.docs.map((d) => ({
    id: d.id,
    ...d.data(),
  }))
}

export async function getPatientById(id) {
  const patientRef = doc(db, 'patients', id)
  const snapshot = await getDoc(patientRef)

  if (!snapshot.exists()) return null

  return {
    id: snapshot.id,
    ...snapshot.data(),
  }
}
// export const PATIENTS = [
//   {
//     id: '1',
//     name: 'Alex Morgan',
//     email: 'alex.morgan@email.com',
//     birthday: '1990-04-15',
//   },
//   {
//     id: '2',
//     name: 'Jordan Lee',
//     email: 'jordan.lee@email.com',
//     birthday: '1985-11-02',
//   },
//   {
//     id: '3',
//     name: 'Sam Rivera',
//     email: 'sam.rivera@email.com',
//     birthday: '1992-07-22',
//   },
// ]

// export function getPatientById(id) {
//   return PATIENTS.find((p) => p.id === id) ?? null
// }
