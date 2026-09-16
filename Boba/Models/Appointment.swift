/**
 * Appointment.swift
 *
 * Overview: Defines the appointment data model used to represent scheduled
 * care appointments in the Boba app.
 *
 * Contains:
 * - A Codable and Identifiable Appointment model.
 * - Firestore document identity and normalized patient, provider, and start
 *   time fields.
 *
 * Date: September 10, 2026
 * Attribution: BOBA t team
 * Copyright: Copyright © 2026 BOBA t. All rights reserved.
 */
import FirebaseFirestore

struct Appointment: Codable, Identifiable {
    @DocumentID var id: String?
    var patientId: String
    var therapistId: String?
    var providerName: String
    var startAt: Date
    var availabilityId: String? = nil
    var slotId: String? = nil
    var durationMinutes: Int? = nil
    var status: String? = nil
}

struct BookableAppointmentSlot: Identifiable, Equatable {
    let therapistId: String
    let availabilityId: String
    let startAt: Date
    let durationMinutes: Int
    let bufferMinutes: Int

    var id: String {
        "\(availabilityId)_\(Int(startAt.timeIntervalSince1970))"
    }

    var endAt: Date {
        Calendar.current.date(
            byAdding: .minute,
            value: durationMinutes,
            to: startAt
        ) ?? startAt
    }
}
