import { Navigate, useLocation } from 'react-router-dom'
import { useAuth } from '../context/useAuth'

export default function PatientRoute({ children }) {
  const { isLoggedInAsPatient } = useAuth()
  const location = useLocation()

  if (!isLoggedInAsPatient) {
    return <Navigate to="/" replace state={{ from: location }} />
  }

  return children
}
