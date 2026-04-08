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

export const MOCK_PATIENTS = [
  {
    id: 'patient-1',
    therapistId: 'therapist-1',
    name: 'Ethan Carter',
    email: 'ethan.carter@example.com',
    birthday: '1997-08-12',
    pronouns: 'he/him',
    therapistName: 'Dr. Maya Patel',
    nextAppointment: 'Tuesday, April 8 at 2:00 PM',
    programStage: 'Week 4 of anxiety management',
    checkInStatus: 'Completed today',
    planSummary:
      'Focus on sleep consistency, three grounding exercises per day, and journaling after stressful events.',
    goals: [
      'Reduce panic symptoms during work meetings',
      'Sleep at least 7 hours on weekdays',
      'Practice breathing exercises before bed',
    ],
    recentWins: [
      'Logged mood check-ins for 6 straight days',
      'Used grounding techniques before a presentation',
      'Reported fewer nighttime wakeups this week',
    ],
    careTeam: {
      therapist: 'Dr. Maya Patel',
      therapistEmail: 'maya.patel@bobahealth.dev',
      supportLine: '(555) 240-0182',
    },
  },
  {
    id: 'patient-2',
    therapistId: 'therapist-1',
    name: 'Olivia Bennett',
    email: 'olivia.bennett@example.com',
    birthday: '1989-03-22',
  },
  {
    id: 'patient-3',
    therapistId: 'therapist-2',
    name: 'Noah Kim',
    email: 'noah.kim@example.com',
    birthday: '1994-11-05',
  },
]

const MOCK_PATIENT_VIEW = {
  ...MOCK_PATIENTS[0],
  moodTrend: [
    { day: 'Mon', score: 2, label: 'Low stress' },
    { day: 'Tue', score: 3, label: 'Steady' },
    { day: 'Wed', score: 4, label: 'Manageable' },
    { day: 'Thu', score: 3, label: 'Steady' },
    { day: 'Fri', score: 5, label: 'Best day this week' },
  ],
  tasks: [
    { id: 'task-1', title: 'Complete nightly mood log', due: 'Tonight', done: false },
    { id: 'task-2', title: 'Practice 4-7-8 breathing', due: 'After lunch', done: true },
    { id: 'task-3', title: 'Write one journal reflection', due: 'Before next session', done: false },
  ],
  notesFromTherapist: [
    'You have been more consistent with sleep and morning routines.',
    'Keep using the grounding script before stressful conversations.',
  ],
}

function toPatientRecord(d) {
  return {
    id: d.id,
    ...d.data(),
  }
}

export async function getPatients() {
  try {
    const snapshot = await getDocs(collection(db, 'patients'))
    return snapshot.docs.map(toPatientRecord)
  } catch (error) {
    console.warn('Falling back to mock patients:', error)
    return MOCK_PATIENTS
  }
}

export async function getPatientsForTherapist(therapistId) {
  try {
    const q = query(collection(db, 'patients'), where('therapistId', '==', therapistId))
    const snapshot = await getDocs(q)
    return snapshot.docs.map(toPatientRecord)
  } catch (error) {
    console.warn('Falling back to mock therapist patient list:', error)
    return MOCK_PATIENTS.filter((patient) => patient.therapistId === therapistId)
  }
}

export async function getPatientById(id) {
  try {
    const patientRef = doc(db, 'patients', id)
    const snapshot = await getDoc(patientRef)

    if (!snapshot.exists()) return null

    return {
      id: snapshot.id,
      ...snapshot.data(),
    }
  } catch (error) {
    console.warn(`Falling back to mock patient for id "${id}":`, error)
    return MOCK_PATIENTS.find((patient) => patient.id === id) ?? null
  }
}

export async function getCurrentPatient(username = 'ethan') {
  return {
    ...MOCK_PATIENT_VIEW,
    id: username,
    email: `${username}@example.com`,
    name: username === 'ethan' ? MOCK_PATIENT_VIEW.name : `${username} Patient`,
  }
}
