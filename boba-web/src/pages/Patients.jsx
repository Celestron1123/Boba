import { Link } from 'react-router-dom'
import { useEffect, useState } from 'react'
import { getPatients } from '../data/patients'
import './Patients.css'

export default function Patients() {
  const [patients, setPatients] = useState([])
  const [loading, setLoading] = useState(true)
  const [error, setError] = useState('')
  const [query, setQuery] = useState("");
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

  const filteredPatients = patients.filter(patient => patient.name.toLowerCase().includes(query.toLowerCase()));

  if (loading) return <p>Loading patients...</p>
  if (error) return <p>{error}</p>

  return (
    <main className="patients-page">
      <h1 className="patients-title">Patients</h1>
      <input type="text" placeholder="Search Patients" value={query} onChange={(e) => setQuery(e.target.value)} />

      <ul className="patient-list">
        {filteredPatients.map((patient) => (
          <li key={patient.id} className="patient-item">
            <div className="patient-field">
              <span className="patient-value">
                <Link className="patient-name-link" to={`/patients/${patient.id}`}>
                  {patient.name}
                </Link>
              </span>
            </div>
          </li>
        ))}
      </ul>
    </main>
  )
}
