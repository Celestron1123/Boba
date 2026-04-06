// This file was written by Claude 3.7 Sonnet
// it essentially toggles the state of whether the user is logged in as a therapist

import { useCallback, useMemo, useState } from 'react'
import { AuthContext } from './auth-context'

export function AuthProvider({ children }) {
  const [isLoggedInAsTherapist, setIsLoggedInAsTherapist] = useState(false)
  const [isLoggedInAsPatient, setIsLoggedInAsPatient] = useState(false)

  const loginAsTherapist = useCallback(() => {
    setIsLoggedInAsTherapist(true)
    setIsLoggedInAsPatient(false)
  }, [])

  const loginAsPatient = useCallback(() => {
    setIsLoggedInAsTherapist(false)
    setIsLoggedInAsPatient(true)
  }, [])

  const logout = useCallback(() => {
    setIsLoggedInAsTherapist(false)
    setIsLoggedInAsPatient(false)
  }, [])

  const value = useMemo(
    () => ({
      isLoggedInAsTherapist,
      isLoggedInAsPatient,
      loginAsTherapist,
      loginAsPatient,
      logout,
    }),
    [
      isLoggedInAsTherapist,
      isLoggedInAsPatient,
      loginAsTherapist,
      loginAsPatient,
      logout,
    ],
  )

  return <AuthContext.Provider value={value}>{children}</AuthContext.Provider>
}
