import Foundation

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
