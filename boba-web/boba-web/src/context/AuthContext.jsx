// This file was written by Claude 3.7 Sonnet
// it essentially toggles the state of whether the user is logged in as a therapist

import { createContext, useCallback, useContext, useMemo, useState } from 'react'

const AuthContext = createContext(null)

export function AuthProvider({ children }) {
  const [isLoggedInAsTherapist, setIsLoggedInAsTherapist] = useState(false)

  const loginAsTherapist = useCallback(() => {
    setIsLoggedInAsTherapist(true)
  }, [])

  const logout = useCallback(() => {
    setIsLoggedInAsTherapist(false)
  }, [])

  const value = useMemo(
    () => ({ isLoggedInAsTherapist, loginAsTherapist, logout }),
    [isLoggedInAsTherapist, loginAsTherapist, logout],
  )

  return <AuthContext.Provider value={value}>{children}</AuthContext.Provider>
}

export function useAuth() {
  const ctx = useContext(AuthContext)
  if (!ctx) {
    throw new Error('useAuth must be used within AuthProvider')
  }
  return ctx
}
