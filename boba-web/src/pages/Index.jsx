import { useState } from 'react'
import { Link, useNavigate } from 'react-router-dom'
import { useAuth } from '../context/useAuth'
import { authenticateUser } from '../data/users'
import './Index.css'

// This file was written by Claude 3.7 Sonnet
// it essentially renders the index page of the application

export default function Index() {
  const navigate = useNavigate()
  const { loginAsTherapist, loginAsPatient } = useAuth()
  const [loginDialogRole, setLoginDialogRole] = useState('')
  const [username, setUsername] = useState('')
  const [password, setPassword] = useState('')
  const [loginError, setLoginError] = useState('')
  const [isAuthenticating, setIsAuthenticating] = useState(false)

  function handleTherapistClick() {
    openLoginDialog('THERAPIST')
  }

  function handlePatientClick() {
    openLoginDialog('PATIENT')
  }

  function openLoginDialog(role) {
    setLoginError('')
    setUsername('')
    setPassword('')
    setLoginDialogRole(role)
  }

  function closeLoginDialog() {
    setLoginDialogRole('')
    setUsername('')
    setPassword('')
  }

  async function handleLogin(event) {
    event.preventDefault()
    setIsAuthenticating(true)
    setLoginError('')

    try {
      const user = await authenticateUser({ username, password })
      if (user.role !== loginDialogRole) {
        throw new Error('Login failed. Incorrect username or password.')
      }

      if (loginDialogRole === 'THERAPIST') {
        loginAsTherapist()
        closeLoginDialog()
        navigate('/patients')
      } else {
        loginAsPatient(user.username)
        closeLoginDialog()
        navigate('/patient')
      }
    } catch (error) {
      console.error(error)
      closeLoginDialog()
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
      <Link className="register-link" to="/register">
        Register a new user
      </Link>
      {loginError ? <p className="index-error-message">{loginError}</p> : null}

      {loginDialogRole ? (
        <div
          className="patient-login-modal"
          role="dialog"
          aria-modal="true"
          aria-labelledby="user-login-title"
        >
          <div className="patient-login-card">
            <h2 id="user-login-title" className="patient-login-title">
              {loginDialogRole === 'THERAPIST' ? 'Therapist Login' : 'Patient Login'}
            </h2>
            <form className="patient-login-form" onSubmit={handleLogin}>
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
                <button type="button" className="patient-login-cancel-btn" onClick={closeLoginDialog}>
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
