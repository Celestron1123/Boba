import { Link } from 'react-router-dom'
import { useEffect, useState } from 'react'
import { getPatients } from '../data/patients'
import './Patients.css'

export default function Patients() {
  const [patients, setPatients] = useState([])
  const [loading, setLoading] = useState(true)
  const [error, setError] = useState('')

  useEffect(() => {
    async function loadPatients() {
      try {
        const data = await getPatients()
        setPatients(data)
      } catch (err) {
        console.error(err)
        setError('Failed to load patients')
      } finally {
        setLoading(false)
      }
    }

    loadPatients()
  }, [])

  if (loading) return <p>Loading patients...</p>
  if (error) return <p>{error}</p>

  return (
    <main className="patients-page">
      <h1 className="patients-title">Patients</h1>

      <ul className="patient-list">
        {patients.map((patient) => (
          <li key={patient.id} className="patient-item">
            <div className="patient-field">
              <span className="patient-label">Name</span>
              <span className="patient-value">
                <Link className="patient-name-link" to={`/patients/${patient.id}`}>
                  {patient.name}
                </Link>
              </span>
            </div>

            <div className="patient-field">
              <span className="patient-label">Email</span>
              <span className="patient-value">{patient.email}</span>
            </div>

            <div className="patient-field">
              <span className="patient-label">Birthday</span>
              <span className="patient-value">{patient.birthday}</span>
            </div>
          </li>
        ))}
      </ul>
    </main>
  )
}
