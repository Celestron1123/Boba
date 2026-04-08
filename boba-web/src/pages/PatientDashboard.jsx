import { useEffect, useState } from 'react'
import { useNavigate } from 'react-router-dom'
import { useAuth } from '../context/useAuth'
import { getCurrentPatient } from '../data/patients'
import { getMoodOption, getPatientLogs, getTodayLog } from '../data/patientLogs'
import { getUserProfile } from '../data/users'
import CheckInForm from '../components/CheckInForm'
import './PatientDashboard.css'

function getLocalDateString() {
  const now = new Date()
  const year = now.getFullYear()
  const month = String(now.getMonth() + 1).padStart(2, '0')
  const day = String(now.getDate()).padStart(2, '0')

  return `${year}-${month}-${day}`
}

function formatDisplayDate(dateString) {
  return new Intl.DateTimeFormat('en-US', {
    weekday: 'long',
    month: 'long',
    day: 'numeric',
  }).format(new Date(`${dateString}T00:00:00`))
}

export default function PatientDashboard() {
  const navigate = useNavigate()
  const { logout, currentPatientUsername } = useAuth()
  const [patient, setPatient] = useState(null)
  const [logs, setLogs] = useState([])
  const [todayLog, setTodayLog] = useState(null)
  const [historyExpanded, setHistoryExpanded] = useState(false)
  const [loading, setLoading] = useState(true)
  const [error, setError] = useState('')
  const [today] = useState(getLocalDateString)

  useEffect(() => {
    let active = true

    async function loadPatient() {
      try {
        const [patientData, patientLogs, existingTodayLog, userProfile] = await Promise.all([
          getCurrentPatient(currentPatientUsername),
          getPatientLogs(currentPatientUsername),
          getTodayLog(currentPatientUsername, today),
          getUserProfile(currentPatientUsername),
        ])

        if (active) {
          setPatient({
            ...patientData,
            name: userProfile.name || patientData.name,
          })
          setLogs(patientLogs)
          setTodayLog(existingTodayLog)
        }
      } catch (err) {
        console.error(err)
        if (active) {
          setError('Failed to load patient information.')
        }
      } finally {
        if (active) {
          setLoading(false)
        }
      }
    }

    loadPatient()

    return () => {
      active = false
    }
  }, [currentPatientUsername, today])

  function handleLogout() {
    logout()
    navigate('/')
  }

  function handleProfileClick() {
    navigate('/patient/profile')
  }

  function handleLogSaved(savedLog) {
    if (savedLog.date === today) {
      setTodayLog(savedLog)
    }
    setLogs((currentLogs) => {
      const nextLogs = [savedLog, ...currentLogs.filter((log) => log.id !== savedLog.id)]
      return nextLogs.sort((a, b) => b.date.localeCompare(a.date))
    })
  }

  if (loading) {
    return <main className="patient-dashboard-page">Loading patient dashboard...</main>
  }

  if (error || !patient) {
    return <main className="patient-dashboard-page">{error || 'Patient not found.'}</main>
  }

  return (
    <main className="patient-dashboard-page">
      <section className="patient-hero">
        <div>
          <p className="patient-eyebrow">Patient view</p>
          <h1 className="patient-dashboard-title">Welcome back, {patient.name.split(' ')[0]}</h1>
          <p className="patient-summary">{patient.planSummary}</p>
        </div>
        <div className="patient-hero-actions">
          <button type="button" className="patient-logout-btn" onClick={handleLogout}>
            Log out
          </button>
          <button type="button" className="patient-profile-btn" onClick={handleProfileClick}>
            Profile
          </button>
        </div>
      </section>

      <section className="patient-overview-grid">
        <article className="patient-card patient-card-emphasis">
          <h2>Next appointment</h2>
          <p className="patient-card-value">{patient.nextAppointment}</p>
          <p className="patient-card-meta">with {patient.therapistName}</p>
        </article>

        <article className="patient-card">
          <h2>Current focus</h2>
          <p className="patient-card-value">{patient.programStage}</p>
          <p className="patient-card-meta">{patient.checkInStatus}</p>
        </article>

        <article className="patient-card">
          <h2>Care team</h2>
          <p className="patient-card-value">{patient.careTeam.therapist}</p>
          <p className="patient-card-meta">{patient.careTeam.therapistEmail}</p>
          <p className="patient-card-meta">Support: {patient.careTeam.supportLine}</p>
        </article>
      </section>

      <section className="patient-content-grid">
        <article className="patient-panel patient-panel-wide">
          <div className="patient-panel-heading">
            <div>
              <h2>Daily check-in</h2>
              <p className="patient-panel-copy">{formatDisplayDate(today)}</p>
            </div>
            {todayLog ? (
              <span className="patient-checkin-pill patient-checkin-pill-complete">Submitted</span>
            ) : (
              <span className="patient-checkin-pill">Open</span>
            )}
          </div>
          <CheckInForm
            patientId={currentPatientUsername}
            date={today}
            existingLog={todayLog}
            onSaved={handleLogSaved}
            submitLabel="Save today’s check-in"
            allowEditing
          />
        </article>

        <article className="patient-panel">
          <h2>This week&apos;s goals</h2>
          <ul className="patient-dashboard-list">
            {patient.goals.map((goal) => (
              <li key={goal}>{goal}</li>
            ))}
          </ul>
        </article>

        <article className="patient-panel">
          <h2>To do</h2>
          <ul className="patient-dashboard-list">
            {patient.tasks.map((task) => (
              <li key={task.id} className={task.done ? 'is-complete' : ''}>
                <span>{task.title}</span>
                <span className="patient-list-meta">{task.due}</span>
              </li>
            ))}
          </ul>
        </article>

        <article className="patient-panel">
          <h2>Mood trend</h2>
          <div className="patient-mood-trend" aria-label="Mood trend for the week">
            {patient.moodTrend.map((entry) => (
              <div key={entry.day} className="patient-mood-bar-group">
                <div
                  className="patient-mood-bar"
                  style={{ height: `${entry.score * 18}px` }}
                  title={`${entry.day}: ${entry.label}`}
                />
                <span>{entry.day}</span>
              </div>
            ))}
          </div>
        </article>

        <article className="patient-panel">
          <h2>Recent progress</h2>
          <ul className="patient-dashboard-list">
            {patient.recentWins.map((win) => (
              <li key={win}>{win}</li>
            ))}
          </ul>
        </article>

        <article className="patient-panel patient-panel-wide">
          <div className="patient-panel-heading">
            <div>
              <h2>Previous check-ins</h2>
              <p className="patient-panel-copy">Review earlier entries saved in Firebase.</p>
            </div>
            <button
              type="button"
              className="patient-toggle-btn"
              onClick={() => setHistoryExpanded((value) => !value)}
            >
              {historyExpanded ? 'Hide history' : 'Show history'}
            </button>
          </div>
          {!historyExpanded ? (
            <p className="patient-empty-state">Select “Show history” to review or edit past entries.</p>
          ) : logs.length === 0 ? (
            <p className="patient-empty-state">No check-ins yet.</p>
          ) : (
            <div className="patient-log-list">
              {logs.map((log) => {
                const option = getMoodOption(log.mood)

                return (
                  <article key={log.id} className="patient-log-card">
                    <div className="patient-log-header">
                      <div>
                        <h3>{formatDisplayDate(log.date)}</h3>
                        <p className="patient-card-meta">{log.date}</p>
                      </div>
                      <div className="patient-log-mood">
                        <span className="patient-log-emoji" aria-hidden="true">
                          {option.emoji}
                        </span>
                        <span>{option.label}</span>
                      </div>
                    </div>
                    <CheckInForm
                      patientId={currentPatientUsername}
                      date={log.date}
                      existingLog={log}
                      onSaved={handleLogSaved}
                      submitLabel="Save changes"
                      allowEditing
                    />
                  </article>
                )
              })}
            </div>
          )}
        </article>

        <article className="patient-panel patient-panel-wide">
          <h2>Notes from your therapist</h2>
          <ul className="patient-dashboard-list">
            {patient.notesFromTherapist.map((note) => (
              <li key={note}>{note}</li>
            ))}
          </ul>
        </article>
      </section>
    </main>
  )
}
