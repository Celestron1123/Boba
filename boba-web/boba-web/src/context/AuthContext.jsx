//

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
