import {
  collection,
  doc,
  getDocs,
  orderBy,
  query,
  serverTimestamp,
  setDoc,
  where,
} from 'firebase/firestore'
import { db } from '../firebase'

const CURRENT_USER_ID = 'ethan'

const MOCK_LOGS = [
  {
    id: 'mock-log-1',
    date: '2026-04-03',
    mood: 'GOOD',
    notes: 'Had a calmer morning and felt more prepared for class.',
  },
  {
    id: 'mock-log-2',
    date: '2026-04-04',
    mood: 'SAD',
    notes: 'Busy afternoon. Took a walk later and felt a little steadier.',
  },
]

let mockLogsState = [...MOCK_LOGS]

export const MOOD_OPTIONS = [
  { value: 'GREAT', emoji: '😄', label: 'Great' },
  { value: 'GOOD', emoji: '🙂', label: 'Good' },
  { value: 'OKAY', emoji: '😐', label: 'Okay' },
  { value: 'SAD', emoji: '🙁', label: 'Sad' },
  { value: 'TERRIBLE', emoji: '😣', label: 'Terrible' },
]

function logsCollection(userId = CURRENT_USER_ID) {
  return collection(db, 'users', userId, 'logs')
}

function createTimestampLogId() {
  const isoString = new Date().toISOString()
  const compactTimestamp = isoString.replaceAll('-', '').replaceAll(':', '').replace('.', '')
  return compactTimestamp
}

function sortLogsDesc(logs) {
  return [...logs].sort((a, b) => b.date.localeCompare(a.date))
}

function normalizeMood(mood) {
  if (!mood) return 'OKAY'
  if (typeof mood === 'string') return mood
  return mood.value ?? mood.label ?? 'OKAY'
}

function toLogRecord(snapshot) {
  const data = snapshot.data()

  return {
    id: snapshot.id,
    date: data.date,
    mood: normalizeMood(data.mood),
    notes: data.notes ?? '',
  }
}

export async function getPatientLogs(userId = CURRENT_USER_ID) {
  try {
    const logsQuery = query(logsCollection(userId), orderBy('date', 'desc'))
    const snapshot = await getDocs(logsQuery)

    return snapshot.docs.map(toLogRecord)
  } catch (error) {
    console.warn('Falling back to mock patient logs:', error)
    return sortLogsDesc(mockLogsState)
  }
}

export async function getTodayLog(userId = CURRENT_USER_ID, date) {
  try {
    const logsQuery = query(logsCollection(userId), where('date', '==', date))
    const snapshot = await getDocs(logsQuery)
    const log = snapshot.docs[0]

    return log ? toLogRecord(log) : null
  } catch (error) {
    console.warn('Falling back to mock today log:', error)
    return mockLogsState.find((log) => log.date === date) ?? null
  }
}

export async function createPatientLog({ patientId = CURRENT_USER_ID, date, mood, notes }) {
  const logId = createTimestampLogId()
  const payload = {
    date,
    mood,
    notes,
    createdAt: serverTimestamp(),
  }

  try {
    const logRef = doc(logsCollection(patientId), logId)
    await setDoc(logRef, payload)

    return {
      id: logId,
      date,
      mood: payload.mood,
      notes,
    }
  } catch (error) {
    console.warn('Unable to write patient log to Firestore, using local mock result:', error)

    const fallbackLog = {
      id: logId,
      date,
      mood: payload.mood,
      notes,
    }
    mockLogsState = sortLogsDesc([fallbackLog, ...mockLogsState.filter((log) => log.id !== logId)])

    return fallbackLog
  }
}

export async function updatePatientLog({
  patientId = CURRENT_USER_ID,
  logId,
  date,
  mood,
  notes,
}) {
  const payload = {
    date,
    mood,
    notes,
    updatedAt: serverTimestamp(),
  }

  try {
    const logRef = doc(logsCollection(patientId), logId)
    await setDoc(logRef, payload, { merge: true })

    return {
      id: logId,
      date,
      mood,
      notes,
    }
  } catch (error) {
    console.warn('Unable to update patient log in Firestore, using local mock result:', error)

    const fallbackLog = {
      id: logId,
      date,
      mood,
      notes,
    }
    mockLogsState = sortLogsDesc([
      fallbackLog,
      ...mockLogsState.filter((log) => log.id !== logId),
    ])

    return fallbackLog
  }
}

export function getMoodOption(value) {
  return MOOD_OPTIONS.find((option) => option.value === value) ?? MOOD_OPTIONS[2]
}
