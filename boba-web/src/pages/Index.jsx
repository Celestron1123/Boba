import { useNavigate } from 'react-router-dom'
import { useAuth } from '../context/useAuth'
import './Index.css'

// This file was written by Claude 3.7 Sonnet
// it essentially renders the index page of the application

export default function Index() {
  const navigate = useNavigate()
  const { loginAsTherapist, loginAsPatient } = useAuth()

  function handleTherapistClick() {
    loginAsTherapist()
    navigate('/patients')
  }

  function handlePatientClick() {
    loginAsPatient()
    navigate('/patient')
  }

  return (
    <main className="index-page">
      <h1 className="index-title">Boba</h1>
      <button type="button" className="therapist-login-btn" onClick={handleTherapistClick}>
        Therapist
      </button>
      <button type="button" className="patient-login-btn" onClick={handlePatientClick}>
        Patient
      </button>
    </main>
  )
}
