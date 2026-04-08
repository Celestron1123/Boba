import { useEffect, useState } from 'react'
import { Link } from 'react-router-dom'
import { useAuth } from '../context/useAuth'
import { getUserProfile, updateUserProfile, USER_ROLE_OPTIONS } from '../data/users'
import './PatientProfile.css'

export default function PatientProfile() {
  const { currentPatientUsername } = useAuth()
  const [profile, setProfile] = useState({
    username: '',
    password: '',
    email: '',
    name: '',
    birthday: '',
    role: 'PATIENT',
  })
  const [loading, setLoading] = useState(true)
  const [saving, setSaving] = useState(false)
  const [error, setError] = useState('')
  const [success, setSuccess] = useState('')

  useEffect(() => {
    let active = true

    async function loadProfile() {
      try {
        const userProfile = await getUserProfile(currentPatientUsername)
        if (active) {
          setProfile(userProfile)
        }
      } catch (err) {
        console.error(err)
        if (active) {
          setError('Failed to load profile.')
        }
      } finally {
        if (active) {
          setLoading(false)
        }
      }
    }

    loadProfile()

    return () => {
      active = false
    }
  }, [currentPatientUsername])

  function handleChange(event) {
    const { name, value } = event.target
    setProfile((current) => ({
      ...current,
      [name]: value,
    }))
  }

  async function handleSubmit(event) {
    event.preventDefault()
    setSaving(true)
    setError('')
    setSuccess('')

    try {
      const updatedProfile = await updateUserProfile(profile)
      setProfile(updatedProfile)
      setSuccess('Profile updated.')
    } catch (err) {
      console.error(err)
      setError(err instanceof Error ? err.message : 'Failed to update profile.')
    } finally {
      setSaving(false)
    }
  }

  const roleLabel =
    USER_ROLE_OPTIONS.find((option) => option.value === profile.role)?.label ?? profile.role

  if (loading) {
    return <main className="patient-profile-page">Loading profile...</main>
  }

  if (error && !profile.username) {
    return <main className="patient-profile-page">{error}</main>
  }

  return (
    <main className="patient-profile-page">
      <div className="patient-profile-card">
        <Link className="patient-profile-back" to="/patient">
          ← Back to patient page
        </Link>
        <h1 className="patient-profile-title">Profile</h1>
        <p className="patient-profile-copy">Update your account and personal information.</p>

        <form className="patient-profile-form" onSubmit={handleSubmit}>
          <label className="patient-profile-field">
            <span>Username</span>
            <input type="text" value={profile.username} disabled readOnly />
          </label>

          <label className="patient-profile-field">
            <span>Password</span>
            <input
              type="password"
              name="password"
              value={profile.password}
              onChange={handleChange}
              autoComplete="current-password"
            />
          </label>

          <label className="patient-profile-field">
            <span>Email address</span>
            <input type="text" name="email" value={profile.email} onChange={handleChange} />
          </label>

          <label className="patient-profile-field">
            <span>Name</span>
            <input type="text" name="name" value={profile.name} onChange={handleChange} />
          </label>

          <label className="patient-profile-field">
            <span>Birthday</span>
            <input type="text" name="birthday" value={profile.birthday} onChange={handleChange} />
          </label>

          <label className="patient-profile-field">
            <span>User type</span>
            <input type="text" value={roleLabel} disabled readOnly />
          </label>

          {error ? <p className="patient-profile-message patient-profile-message-error">{error}</p> : null}
          {success ? <p className="patient-profile-message patient-profile-message-success">{success}</p> : null}

          <button type="submit" className="patient-profile-submit-btn" disabled={saving}>
            {saving ? 'Saving...' : 'Save profile'}
          </button>
        </form>
      </div>
    </main>
  )
}
