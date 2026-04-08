import { useState } from 'react'
import { Link } from 'react-router-dom'
import { registerUser, USER_ROLE_OPTIONS } from '../data/users'
import './Register.css'

export default function Register() {
  const [username, setUsername] = useState('')
  const [password, setPassword] = useState('')
  const [role, setRole] = useState('PATIENT')
  const [error, setError] = useState('')
  const [success, setSuccess] = useState('')
  const [submitting, setSubmitting] = useState(false)

  async function handleSubmit(event) {
    event.preventDefault()

    setSubmitting(true)
    setError('')
    setSuccess('')

    try {
      const createdUser = await registerUser({ username, password, role })
      setSuccess(`New user registered: "${createdUser.username}".`)
      setUsername('')
      setPassword('')
      setRole('PATIENT')
    } catch (err) {
      console.error(err)
      setError(err instanceof Error ? err.message : 'Failed to register user.')
    } finally {
      setSubmitting(false)
    }
  }

  return (
    <main className="register-page">
      <div className="register-card">
        <Link className="register-back-link" to="/">
          ← Home
        </Link>
        <h1 className="register-title">Register</h1>
        <p className="register-copy">Enter a username and password to register user.</p>

        <form className="register-form" onSubmit={handleSubmit}>
          <label className="register-field">
            <span>Username</span>
            <input
              type="text"
              value={username}
              onChange={(event) => setUsername(event.target.value)}
              autoComplete="username"
            />
          </label>

          <label className="register-field">
            <span>Password</span>
            <input
              type="password"
              value={password}
              onChange={(event) => setPassword(event.target.value)}
              autoComplete="new-password"
            />
          </label>

          <label className="register-field">
            <span>User type</span>
            <select value={role} onChange={(event) => setRole(event.target.value)}>
              {USER_ROLE_OPTIONS.map((option) => (
                <option key={option.value} value={option.value}>
                  {option.label}
                </option>
              ))}
            </select>
          </label>

          {error ? <p className="register-message register-message-error">{error}</p> : null}
          {success ? <p className="register-message register-message-success">{success}</p> : null}

          <button type="submit" className="register-submit-btn" disabled={submitting}>
            {submitting ? 'Registering...' : 'Register'}
          </button>
        </form>
      </div>
    </main>
  )
}
