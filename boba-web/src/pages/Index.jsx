import { useState } from 'react'
import { useNavigate } from 'react-router-dom'
import { useAuth } from '../context/useAuth'
import { authenticateUser } from '../data/users'
import './Index.css'

// This file was written by Claude 3.7 Sonnet
// it essentially renders the index page of the application

export default function Index() {
  const navigate = useNavigate()
  const { loginAsTherapist, loginAsPatient } = useAuth()
  const [isPatientDialogOpen, setIsPatientDialogOpen] = useState(false)
  const [username, setUsername] = useState('')
  const [password, setPassword] = useState('')
  const [loginError, setLoginError] = useState('')
  const [isAuthenticating, setIsAuthenticating] = useState(false)

  function handleTherapistClick() {
    loginAsTherapist()
    navigate('/patients')
  }

  function handlePatientClick() {
    setLoginError('')
    setUsername('')
    setPassword('')
    setIsPatientDialogOpen(true)
  }

  function closePatientDialog() {
    setIsPatientDialogOpen(false)
    setUsername('')
    setPassword('')
  }

  async function handlePatientLogin(event) {
    event.preventDefault()
    setIsAuthenticating(true)
    setLoginError('')

    try {
      const user = await authenticateUser({ username, password })
      loginAsPatient(user.username)
      closePatientDialog()
      navigate('/patient')
    } catch (error) {
      console.error(error)
      closePatientDialog()
      setLoginError('Login failed. Incorrect username or password.')
    } finally {
      setIsAuthenticating(false)
    }
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
      {loginError ? <p className="index-error-message">{loginError}</p> : null}

      {isPatientDialogOpen ? (
        <div className="patient-login-modal" role="dialog" aria-modal="true" aria-labelledby="patient-login-title">
          <div className="patient-login-card">
            <h2 id="patient-login-title" className="patient-login-title">
              Patient Login
            </h2>
            <form className="patient-login-form" onSubmit={handlePatientLogin}>
              <label className="patient-login-field">
                <span>Username</span>
                <input
                  type="text"
                  value={username}
                  onChange={(event) => setUsername(event.target.value)}
                  autoComplete="username"
                />
              </label>
              <label className="patient-login-field">
                <span>Password</span>
                <input
                  type="password"
                  value={password}
                  onChange={(event) => setPassword(event.target.value)}
                  autoComplete="current-password"
                />
              </label>
              <div className="patient-login-actions">
                <button type="submit" className="patient-login-submit-btn" disabled={isAuthenticating}>
                  {isAuthenticating ? 'Signing in...' : 'Log in'}
                </button>
                <button type="button" className="patient-login-cancel-btn" onClick={closePatientDialog}>
                  Cancel
                </button>
              </div>
            </form>
          </div>
        </div>
      ) : null}
    </main>
  )
}
