/**
 * Appointment.swift
 *
 * Overview: Defines the appointment data model used to represent scheduled
 * care appointments in the Boba app.
 *
 * Contains:
 * - A Codable and Identifiable Appointment model.
 * - Firestore document identity and appointment date, patient, provider,
 *   and time fields.
 *
 * Date: September 10, 2026
 * Attribution: BOBA t team
 * Copyright: Copyright © 2026 BOBA t. All rights reserved.
 */
import FirebaseFirestore

struct Appointment: Codable, Identifiable {
    @DocumentID var id: String?
    var Date: Date
    var Patient: String
    var Provider: String
    var Time: String
    
}
