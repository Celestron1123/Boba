import { Navigate, useLocation } from 'react-router-dom'
import { useAuth } from '../context/AuthContext'

/** Renders `children` only when logged in as therapist; otherwise redirects home. */
export default function TherapistRoute({ children }) {
  const { isLoggedInAsTherapist } = useAuth()
  const location = useLocation()

  if (!isLoggedInAsTherapist) {
    return <Navigate to="/" replace state={{ from: location }} />
  }

  return children
}
