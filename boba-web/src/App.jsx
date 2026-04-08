// This file was written by Claude 3.7 Sonnet
// it essentially renders the app of the application

import { BrowserRouter, Navigate, Route, Routes } from 'react-router-dom'
import { AuthProvider } from './context/AuthContext'
import TherapistRoute from './components/TherapistRoute'
import PatientRoute from './components/PatientRoute'
import Index from './pages/Index'
import Patients from './pages/Patients'
import PatientShow from './pages/PatientShow'
import PatientDashboard from './pages/PatientDashboard'
import PatientProfile from './pages/PatientProfile'
import Register from './pages/Register'

export default function App() {
  return (
    <BrowserRouter>
      <AuthProvider>
        <Routes>
          <Route path="/" element={<Index />} />
          <Route path="/register" element={<Register />} />
          <Route
            path="/patients"
            element={
              <TherapistRoute>
                <Patients />
              </TherapistRoute>
            }
          />
          <Route
            path="/patients/:patientId"
            element={
              <TherapistRoute>
                <PatientShow />
              </TherapistRoute>
            }
          />
          <Route
            path="/patient"
            element={
              <PatientRoute>
                <PatientDashboard />
              </PatientRoute>
            }
          />
          <Route
            path="/patient/profile"
            element={
              <PatientRoute>
                <PatientProfile />
              </PatientRoute>
            }
          />
          <Route path="*" element={<Navigate to="/" replace />} />
        </Routes>
      </AuthProvider>
    </BrowserRouter>
  )
}
