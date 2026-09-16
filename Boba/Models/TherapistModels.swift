/**
 * TherapistModels.swift
 *
 * Overview: Defines the therapist data model
 *
 * Contains:

 *
 * Date: September 10, 2026
 * Attribution: BOBA t team
 * Copyright: Copyright © 2026 BOBA t. All rights reserved.
 */
import Foundation
import FirebaseFirestore

struct TherapistAvailability: Codable, Identifiable, Equatable {
    @DocumentID var id: String?
    let therapistId: String
    let startAt: Date
    let endAt: Date
    let sessionDurationMinutes: Int?
    let bufferMinutes: Int?

    init(
        therapistId: String,
        startAt: Date,
        endAt: Date,
        sessionDurationMinutes: Int = 50,
        bufferMinutes: Int = 10
    ) {
        self.therapistId = therapistId
        self.startAt = startAt
        self.endAt = endAt
        self.sessionDurationMinutes = sessionDurationMinutes
        self.bufferMinutes = bufferMinutes
    }

    var duration: TimeInterval {
        endAt.timeIntervalSince(startAt)
    }

    var effectiveSessionDurationMinutes: Int {
        sessionDurationMinutes ?? 50
    }

    var effectiveBufferMinutes: Int {
        bufferMinutes ?? 10
    }
    /// Convert availability blocks into individual appointment slots
    var bookableStartTimes: [Date] {
        let calendar = Calendar.current
        let sessionLength = effectiveSessionDurationMinutes
        let intervalLength = sessionLength + effectiveBufferMinutes
        var starts: [Date] = []
        var candidate = startAt

        while let sessionEnd = calendar.date(byAdding: .minute, value: sessionLength, to: candidate),
              sessionEnd <= endAt {
            starts.append(candidate)
            guard let next = calendar.date(byAdding: .minute, value: intervalLength, to: candidate) else {
                break
            }
            candidate = next
        }

        return starts
    }
}

struct TherapistPatientConnection: Identifiable, Equatable {
    let patientId: String
    let patientNumber: Int
    let firstName: String
    let lastName: String
    let patientAge: Int?
    let wellnessGoals: [String]

    var id: String { patientId }
    var displayName: String {
        let name = "\(firstName) \(lastName)".trimmingCharacters(in: .whitespacesAndNewlines)
        return name.isEmpty ? "Patient #\(patientNumber)" : name
    }
}

struct TherapistAnnotation: Identifiable, Equatable {
    let id: String
    let text: String
    let authorId: String
    let createdAt: Date
}

struct LogAnnotationSummary {
    var privateNotes: [TherapistAnnotation] = []
    var comments: [TherapistAnnotation] = []
}

struct TherapistAppointment: Identifiable {
    let id: String
    let startAt: Date
    let providerName: String
}

struct MoodTrendPoint: Identifiable {
    let id: Date
    let date: Date
    let value: Double
    let mood: String
}

struct TherapistTagCount: Identifiable {
    let tag: String
    let count: Int

    var id: String { tag }
}
