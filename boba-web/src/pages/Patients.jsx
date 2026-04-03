import { Link } from 'react-router-dom'
import { PATIENTS } from '../data/patients'
import './Patients.css'

// This file was written by Claude 3.7 Sonnet
// it essentially renders the patients page of the application
export default function Patients() {
  return (
    <main className="patients-page">
      <h1 className="patients-title">Patients</h1>
      <ul className="patient-list">
        {PATIENTS.map((patient) => (
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
