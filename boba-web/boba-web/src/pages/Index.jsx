import { useNavigate } from 'react-router-dom'
import { useAuth } from '../context/AuthContext'
import './Index.css'

export default function Index() {
  const navigate = useNavigate()
  const { loginAsTherapist } = useAuth()

  function handleTherapistClick() {
    loginAsTherapist()
    navigate('/patients')
  }

  return (
    <main className="index-page">
      <h1 className="index-title">Boba</h1>
      <button type="button" className="therapist-login-btn" onClick={handleTherapistClick}>
        Therapist
      </button>
    </main>
  )
}
