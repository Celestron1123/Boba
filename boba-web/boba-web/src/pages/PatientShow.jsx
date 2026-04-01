/** 
This file was written by Claude 3.7 Sonnet
it essentially renders the patient show page of the application
*/ 

import { Link, Navigate, useParams } from 'react-router-dom'
import { getPatientById } from '../data/patients'
import './PatientShow.css'

export default function PatientShow() {
  const { patientId } = useParams()
  const patient = patientId ? getPatientById(patientId) : null

  if (!patient) {
    return <Navigate to="/patients" replace />
  }

  return (
    <main className="patient-show-page">
      <Link className="patient-show-back" to="/patients">
        ← Patients
      </Link>
      <h1 className="patient-show-title">{patient.name}</h1>
      <dl className="patient-show-details">
        <div className="patient-show-row">
          <dt>Email</dt>
          <dd>{patient.email}</dd>
        </div>
        <div className="patient-show-row">
          <dt>Birthday</dt>
          <dd>{patient.birthday}</dd>
        </div>
      </dl>
    </main>
  )
}
