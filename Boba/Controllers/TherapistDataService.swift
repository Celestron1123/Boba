import Foundation
import Combine
import FirebaseFirestore

final class TherapistDataService {
    static let shared = TherapistDataService()

    private let db = Firestore.firestore()

    private init() {}

    func observeConnections(
        therapistId: String,
        onChange: @escaping ([TherapistPatientConnection], Error?) -> Void
    ) -> ListenerRegistration {
        db.collection("users")
            .document(therapistId)
            .collection("connections")
            .order(by: "createdAt", descending: false)
            .addSnapshotListener { snapshot, error in
                let connections = snapshot?.documents.compactMap(Self.connection(from:)) ?? []
                onChange(connections, error)
            }
    }

    func observeLogs(
        patientId: String,
        onChange: @escaping ([DailyLog], Error?) -> Void
    ) -> ListenerRegistration {
        db.collection("users")
            .document(patientId)
            .collection("logs")
            .order(by: "date", descending: true)
            .limit(to: 90)
            .addSnapshotListener { snapshot, error in
                let logs = snapshot?.documents.compactMap { try? $0.data(as: DailyLog.self) } ?? []
                onChange(logs, error)
            }
    }

    func observePrivateNotes(
        patientId: String,
        logId: String,
        authorId: String,
        onChange: @escaping ([TherapistAnnotation], Error?) -> Void
    ) -> ListenerRegistration {
        annotationQuery(patientId: patientId, logId: logId, collection: "therapistNotes")
            .whereField("authorId", isEqualTo: authorId)
            .addSnapshotListener { snapshot, error in
                onChange(Self.annotations(from: snapshot), error)
            }
    }

    func observeComments(
        patientId: String,
        logId: String,
        onChange: @escaping ([TherapistAnnotation], Error?) -> Void
    ) -> ListenerRegistration {
        annotationQuery(patientId: patientId, logId: logId, collection: "comments")
            .addSnapshotListener { snapshot, error in
                onChange(Self.annotations(from: snapshot), error)
            }
    }

    func observeAppointments(
        patientId: String,
        onChange: @escaping ([TherapistAppointment], Error?) -> Void
    ) -> ListenerRegistration {
        db.collection("appointments")
            .whereField("patientId", isEqualTo: patientId)
            .addSnapshotListener { snapshot, error in
                let appointments = snapshot?.documents.compactMap(Self.appointment(from:)) ?? []
                onChange(appointments.filter { $0.startAt >= Date() }.sorted { $0.startAt < $1.startAt }, error)
            }
    }

    func observeAvailability(
        therapistId: String,
        onChange: @escaping ([TherapistAvailability], Error?) -> Void
    ) -> ListenerRegistration {
        db.collection("users")
            .document(therapistId)
            .collection("availability")
            .order(by: "startAt", descending: false)
            .addSnapshotListener { snapshot, error in
                let availability = snapshot?.documents.compactMap {
                    try? $0.data(as: TherapistAvailability.self)
                } ?? []
                onChange(availability, error)
            }
    }

    func addAvailability(
        therapistId: String,
        startAt: Date,
        endAt: Date,
        sessionDurationMinutes: Int,
        bufferMinutes: Int,
        completion: @escaping (Error?) -> Void
    ) {
        let availability = TherapistAvailability(
            therapistId: therapistId,
            startAt: startAt,
            endAt: endAt,
            sessionDurationMinutes: sessionDurationMinutes,
            bufferMinutes: bufferMinutes
        )

        do {
            try db.collection("users")
                .document(therapistId)
                .collection("availability")
                .addDocument(from: availability, completion: completion)
        } catch {
            completion(error)
        }
    }

    func deleteAvailability(
        therapistId: String,
        availabilityId: String,
        completion: @escaping (Error?) -> Void
    ) {
        db.collection("users")
            .document(therapistId)
            .collection("availability")
            .document(availabilityId)
            .delete(completion: completion)
    }

    func connectPatient(
        therapistId: String,
        patientNumber: Int,
        completion: @escaping (Result<Void, Error>) -> Void
    ) {
        db.collection("users")
            .whereField("patientNumber", isEqualTo: patientNumber)
            .limit(to: 1)
            .getDocuments { [db] snapshot, error in
                if let error {
                    completion(.failure(error))
                    return
                }
                guard let patient = snapshot?.documents.first,
                      (patient.data()["role"] as? String) == "patient" else {
                    completion(.failure(TherapistDataError.patientNotFound))
                    return
                }

                let data = patient.data()
                let connectionRef = db.collection("users").document(therapistId)
                    .collection("connections").document(patient.documentID)
                let therapistRef = db.collection("users").document(therapistId)
                let patientProviderRef = db.collection("users").document(patient.documentID)
                    .collection("providers").document(therapistId)
                var connection: [String: Any] = [
                    "patientId": patient.documentID,
                    "patientNumber": patientNumber,
                    "firstName": data["firstName"] as? String ?? "",
                    "lastName": data["lastName"] as? String ?? "",
                    "wellnessGoals": data["wellnessGoals"] as? [String] ?? [],
                    "status": "active",
                    "createdBy": therapistId,
                    "createdAt": FieldValue.serverTimestamp(),
                    "updatedAt": FieldValue.serverTimestamp()
                ]
                if let birthday = data["birthday"] as? Timestamp {
                    connection["patientAge"] = Self.age(from: birthday.dateValue())
                }

                connectionRef.getDocument { existing, readError in
                    if let readError {
                        completion(.failure(readError))
                    } else if existing?.exists == true {
                        completion(.failure(TherapistDataError.alreadyConnected))
                    } else {
                        therapistRef.getDocument { therapistSnapshot, therapistError in
                            if let therapistError {
                                completion(.failure(therapistError))
                                return
                            }

                            let therapist = therapistSnapshot?.data() ?? [:]
                            var providerConnection = Self.providerConnectionData(
                                therapistId: therapistId,
                                therapist: therapist
                            )
                            providerConnection["connectedAt"] = FieldValue.serverTimestamp()

                            let batch = db.batch()
                            batch.setData(connection, forDocument: connectionRef)
                            batch.setData(providerConnection, forDocument: patientProviderRef)
                            batch.commit { writeError in
                                if let writeError {
                                    completion(.failure(writeError))
                                } else {
                                    completion(.success(()))
                                }
                            }
                        }
                    }
                }
            }
    }

    func disconnectPatient(
        therapistId: String,
        patientId: String,
        completion: @escaping (Result<Void, Error>) -> Void
    ) {
        let connectionRef = db.collection("users").document(therapistId)
            .collection("connections").document(patientId)
        let patientProviderRef = db.collection("users").document(patientId)
            .collection("providers").document(therapistId)
        let batch = db.batch()
        batch.deleteDocument(connectionRef)
        batch.deleteDocument(patientProviderRef)
        batch.commit { error in
            if let error {
                completion(.failure(error))
            } else {
                completion(.success(()))
            }
        }
    }
    /// We can erase this later. This is just for patients who were connected before the new providers' subcollection
    func syncPatientProviderConnections(
        therapistId: String,
        connections: [TherapistPatientConnection],
        completion: @escaping (Error?) -> Void
    ) {
        guard !connections.isEmpty else {
            completion(nil)
            return
        }

        db.collection("users").document(therapistId).getDocument { [db] snapshot, error in
            if let error {
                completion(error)
                return
            }

            let providerConnection = Self.providerConnectionData(
                therapistId: therapistId,
                therapist: snapshot?.data() ?? [:]
            )
            let batch = db.batch()

            for connection in connections {
                let patientProviderRef = db.collection("users")
                    .document(connection.patientId)
                    .collection("providers")
                    .document(therapistId)
                batch.setData(providerConnection, forDocument: patientProviderRef, merge: true)
            }

            batch.commit(completion: completion)
        }
    }

    private static func age(from birthday: Date) -> Int {
        Calendar.current.dateComponents([.year], from: birthday, to: Date()).year ?? 0
    }

    private enum TherapistDataError: LocalizedError {
        case patientNotFound
        case alreadyConnected

        var errorDescription: String? {
            switch self {
            case .patientNotFound: return "No patient was found with that number."
            case .alreadyConnected: return "This patient is already connected."
            }
        }
    }

    func addPrivateNote(
        patientId: String,
        logId: String,
        text: String,
        authorId: String,
        completion: @escaping (Error?) -> Void
    ) {
        addAnnotation(collection: "therapistNotes", patientId: patientId, logId: logId,
                      text: text, authorId: authorId, completion: completion)
    }

    func addComment(
        patientId: String,
        logId: String,
        text: String,
        authorId: String,
        completion: @escaping (Error?) -> Void
    ) {
        addAnnotation(collection: "comments", patientId: patientId, logId: logId,
                      text: text, authorId: authorId, completion: completion)
    }

    private func addAnnotation(
        collection: String,
        patientId: String,
        logId: String,
        text: String,
        authorId: String,
        completion: @escaping (Error?) -> Void
    ) {
        db.collection("users").document(patientId)
            .collection("logs").document(logId)
            .collection(collection)
            .addDocument(data: [
                "text": text,
                "authorId": authorId,
                "createdAt": FieldValue.serverTimestamp()
            ], completion: completion)
    }

    private func annotationQuery(patientId: String, logId: String, collection: String) -> Query {
        db.collection("users").document(patientId)
            .collection("logs").document(logId)
            .collection(collection)
            .order(by: "createdAt", descending: true)
    }

    nonisolated private static func connection(from document: QueryDocumentSnapshot) -> TherapistPatientConnection? {
        let data = document.data()
        guard let patientNumber = data["patientNumber"] as? Int else { return nil }
        return TherapistPatientConnection(
            patientId: data["patientId"] as? String ?? document.documentID,
            patientNumber: patientNumber,
            firstName: data["firstName"] as? String ?? "",
            lastName: data["lastName"] as? String ?? "",
            patientAge: data["patientAge"] as? Int,
            wellnessGoals: data["wellnessGoals"] as? [String] ?? []
        )
    }

    nonisolated private static func annotations(from snapshot: QuerySnapshot?) -> [TherapistAnnotation] {
        snapshot?.documents.compactMap { document in
            let data = document.data()
            guard let text = data["text"] as? String,
                  let authorId = data["authorId"] as? String else { return nil }
            return TherapistAnnotation(
                id: document.documentID,
                text: text,
                authorId: authorId,
                createdAt: (data["createdAt"] as? Timestamp)?.dateValue() ?? Date()
            )
        } ?? []
    }

    nonisolated private static func appointment(from document: QueryDocumentSnapshot) -> TherapistAppointment? {
        let data = document.data()
        guard let timestamp = data["startAt"] as? Timestamp else { return nil }
        return TherapistAppointment(
            id: document.documentID,
            startAt: timestamp.dateValue(),
            providerName: data["providerName"] as? String ?? "Care team"
        )
    }

    nonisolated private static func providerConnectionData(
        therapistId: String,
        therapist: [String: Any]
    ) -> [String: Any] {
        [
            "providerId": therapistId,
            "firstName": therapist["firstName"] as? String ?? "",
            "lastName": therapist["lastName"] as? String ?? "",
            "clinicalTitle": therapist["clinicalTitle"] as? String ?? "",
            "practiceName": therapist["practiceName"] as? String ?? "",
            "specialties": therapist["practiceSpecialties"] as? [String] ?? [],
            "status": "active",
            "updatedAt": FieldValue.serverTimestamp()
        ]
    }
}

@MainActor
final class TherapistDashboardViewModel: ObservableObject {
    @Published private(set) var connections: [TherapistPatientConnection] = []
    @Published private(set) var selectedPatientId: String?
    @Published private(set) var logs: [DailyLog] = []
    @Published private(set) var annotations: [String: LogAnnotationSummary] = [:]
    @Published private(set) var appointments: [TherapistAppointment] = []
    @Published var errorMessage: String?
    @Published var isLoading = true

    private let service = TherapistDataService.shared
    private var therapistId: String?
    private var connectionListener: ListenerRegistration?
    private var logListener: ListenerRegistration?
    private var appointmentListener: ListenerRegistration?
    private var annotationListeners: [String: [ListenerRegistration]] = [:]

    func start(therapistId: String) {
        guard self.therapistId != therapistId else { return }
        stop()
        self.therapistId = therapistId
        isLoading = true
        connectionListener = service.observeConnections(therapistId: therapistId) { [weak self] connections, error in
            DispatchQueue.main.async {
                guard let self else { return }
                self.isLoading = false
                self.errorMessage = error?.localizedDescription
                self.connections = connections
                self.service.syncPatientProviderConnections(
                    therapistId: therapistId,
                    connections: connections
                ) { [weak self] syncError in
                    DispatchQueue.main.async {
                        if let syncError {
                            self?.errorMessage = syncError.localizedDescription
                        }
                    }
                }
                if let selected = self.selectedPatientId,
                   connections.contains(where: { $0.patientId == selected }) {
                    return
                }
                self.selectPatient(connections.first?.patientId)
            }
        }
    }

    func stop() {
        connectionListener?.remove()
        logListener?.remove()
        appointmentListener?.remove()
        annotationListeners.values.flatMap { $0 }.forEach { $0.remove() }
        connectionListener = nil
        logListener = nil
        appointmentListener = nil
        annotationListeners = [:]
        therapistId = nil
        selectedPatientId = nil
        logs = []
        annotations = [:]
        appointments = []
    }

    func selectPatient(_ patientId: String?) {
        guard selectedPatientId != patientId else { return }
        logListener?.remove()
        appointmentListener?.remove()
        annotationListeners.values.flatMap { $0 }.forEach { $0.remove() }
        annotationListeners = [:]
        logs = []
        annotations = [:]
        appointments = []
        selectedPatientId = patientId
        guard let patientId else { return }

        logListener = service.observeLogs(patientId: patientId) { [weak self] logs, error in
            DispatchQueue.main.async {
                guard let self else { return }
                self.logs = logs
                self.errorMessage = error?.localizedDescription
                self.observeAnnotations(for: logs, patientId: patientId)
            }
        }
        appointmentListener = service.observeAppointments(patientId: patientId) { [weak self] appointments, error in
            DispatchQueue.main.async {
                self?.appointments = appointments
                self?.errorMessage = error?.localizedDescription
            }
        }
    }

    func savePrivateNote(text: String, for log: DailyLog, completion: @escaping (Error?) -> Void) {
        guard let therapistId, let patientId = selectedPatientId, let logId = log.id else { return }
        service.addPrivateNote(patientId: patientId, logId: logId, text: text, authorId: therapistId, completion: completion)
    }

    func saveComment(text: String, for log: DailyLog, completion: @escaping (Error?) -> Void) {
        guard let therapistId, let patientId = selectedPatientId, let logId = log.id else { return }
        service.addComment(patientId: patientId, logId: logId, text: text, authorId: therapistId, completion: completion)
    }

    var selectedConnection: TherapistPatientConnection? {
        connections.first { $0.patientId == selectedPatientId }
    }

    var moodTrend: [MoodTrendPoint] {
        let calendar = Calendar.current
        let start = calendar.startOfDay(for: Date().addingTimeInterval(-6 * 24 * 60 * 60))
        let recent = logs.filter { $0.date >= start }
        let grouped = Dictionary(grouping: recent) { calendar.startOfDay(for: $0.date) }
        return grouped.compactMap { day, dayLogs in
            let values = dayLogs.compactMap { moodValue($0.mood) }
            guard !values.isEmpty else { return nil }
            let average = values.reduce(0, +) / Double(values.count)
            return MoodTrendPoint(id: day, date: day, value: average, mood: moodLabel(for: average))
        }.sorted { $0.date < $1.date }
    }

    var checkInsLast30Days: Int {
        let start = Date().addingTimeInterval(-30 * 24 * 60 * 60)
        return logs.filter { $0.date >= start }.count
    }

    var activeDaysLast30Days: Int {
        let calendar = Calendar.current
        let start = Date().addingTimeInterval(-30 * 24 * 60 * 60)
        return Set(logs.filter { $0.date >= start }.map { calendar.startOfDay(for: $0.date) }).count
    }

    var tagCounts: [TherapistTagCount] {
        let counts = logs.flatMap(\.tags).reduce(into: [:]) { result, tag in result[tag, default: 0] += 1 }
        return counts.map { TherapistTagCount(tag: $0.key, count: $0.value) }
            .sorted { $0.count > $1.count }
            .prefix(4)
            .map { $0 }
    }

    var latestLogDate: Date? { logs.first?.date }

    func annotationSummary(for log: DailyLog) -> LogAnnotationSummary {
        guard let id = log.id else { return LogAnnotationSummary() }
        return annotations[id] ?? LogAnnotationSummary()
    }

    private func observeAnnotations(for logs: [DailyLog], patientId: String) {
        let logIds = Set(logs.compactMap(\.id))
        let staleLogIds = annotationListeners.keys.filter { !logIds.contains($0) }
        for logId in staleLogIds {
            guard let listeners = annotationListeners[logId] else { continue }
            listeners.forEach { $0.remove() }
            annotationListeners.removeValue(forKey: logId)
            annotations.removeValue(forKey: logId)
        }

        for logId in logIds where annotationListeners[logId] == nil {
            let privateListener = service.observePrivateNotes(patientId: patientId, logId: logId, authorId: therapistId ?? "") { [weak self] notes, _ in
                DispatchQueue.main.async {
                    self?.annotations[logId, default: LogAnnotationSummary()].privateNotes = notes
                }
            }
            let commentListener = service.observeComments(patientId: patientId, logId: logId) { [weak self] comments, _ in
                DispatchQueue.main.async {
                    self?.annotations[logId, default: LogAnnotationSummary()].comments = comments
                }
            }
            annotationListeners[logId] = [privateListener, commentListener]
        }
    }

    private func moodValue(_ mood: String) -> Double? {
        switch mood.uppercased() {
        case "AWFUL": return 1
        case "BAD": return 2
        case "OKAY": return 3
        case "GOOD": return 4
        case "GREAT": return 5
        default: return nil
        }
    }

    private func moodLabel(for value: Double) -> String {
        switch value.rounded() {
        case 1: return "Awful"
        case 2: return "Bad"
        case 3: return "Okay"
        case 4: return "Good"
        default: return "Great"
        }
    }
}
