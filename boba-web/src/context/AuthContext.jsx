// This file was written by Claude 3.7 Sonnet
// it essentially toggles the state of whether the user is logged in as a therapist

import { useCallback, useMemo, useState } from 'react'
import { AuthContext } from './auth-context'

export function AuthProvider({ children }) {
  const [isLoggedInAsTherapist, setIsLoggedInAsTherapist] = useState(false)
  const [isLoggedInAsPatient, setIsLoggedInAsPatient] = useState(false)
  const [currentPatientUsername, setCurrentPatientUsername] = useState('')

  const loginAsTherapist = useCallback(() => {
    setIsLoggedInAsTherapist(true)
    setIsLoggedInAsPatient(false)
    setCurrentPatientUsername('')
  }, [])

  const loginAsPatient = useCallback((username) => {
    setIsLoggedInAsTherapist(false)
    setIsLoggedInAsPatient(true)
    setCurrentPatientUsername(username)
  }, [])

  const logout = useCallback(() => {
    setIsLoggedInAsTherapist(false)
    setIsLoggedInAsPatient(false)
    setCurrentPatientUsername('')
  }, [])

  const value = useMemo(
    () => ({
      isLoggedInAsTherapist,
      isLoggedInAsPatient,
      currentPatientUsername,
      loginAsTherapist,
      loginAsPatient,
      logout,
    }),
    [
      isLoggedInAsTherapist,
      isLoggedInAsPatient,
      currentPatientUsername,
      loginAsTherapist,
      loginAsPatient,
      logout,
    ],
  )

  return <AuthContext.Provider value={value}>{children}</AuthContext.Provider>
}
