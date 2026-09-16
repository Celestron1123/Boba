/**
 * PatientSchedulingDataService.swift
 *
 * Overview: Reads a patient's connected providers and their availability,
 * then atomically books a generated appointment slot.
 *
 * Date: September 10, 2026
 * Attribution: BOBA t team
 * Copyright: Copyright © 2026 BOBA t. All rights reserved.
 */
import Foundation
import FirebaseFirestore

final class PatientSchedulingDataService {
    static let shared = PatientSchedulingDataService()

    private let db = Firestore.firestore()

    private init() {}

    func observeProviders(
        patientId: String,
        onChange: @escaping ([PatientProviderConnection], Error?) -> Void
    ) -> ListenerRegistration {
        db.collection("users")
            .document(patientId)
            .collection("providers")
            .addSnapshotListener { snapshot, error in
                let providers = snapshot?.documents.compactMap {
                    try? $0.data(as: PatientProviderConnection.self)
                } ?? []
                onChange(providers.sorted { $0.displayName < $1.displayName }, error)
            }
    }

    func observeAppointments(
        patientId: String,
        onChange: @escaping ([Appointment], Error?) -> Void
    ) -> ListenerRegistration {
        db.collection("appointments")
            .whereField("patientId", isEqualTo: patientId)
            .addSnapshotListener { snapshot, error in
                let appointments = snapshot?.documents.compactMap {
                    try? $0.data(as: Appointment.self)
                } ?? []
                let upcoming = appointments
                    .filter { $0.startAt >= Date() && $0.status != "cancelled" }
                    .sorted { $0.startAt < $1.startAt }
                onChange(upcoming, error)
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

    func observeReservedSlots(
        therapistId: String,
        onChange: @escaping (Set<String>, Error?) -> Void
    ) -> ListenerRegistration {
        db.collection("users")
            .document(therapistId)
            .collection("bookedSlots")
            .addSnapshotListener { snapshot, error in
                let slotIds = Set(snapshot?.documents.map(\.documentID) ?? [])
                onChange(slotIds, error)
            }
    }

    func book(
        slot: BookableAppointmentSlot,
        patientId: String,
        providerName: String,
        completion: @escaping (Result<Void, Error>) -> Void
    ) {
        let appointmentRef = db.collection("appointments").document()
        let reservationRef = db.collection("users")
            .document(slot.therapistId)
            .collection("bookedSlots")
            .document(slot.id)
        db.runTransaction({ transaction, errorPointer in
            do {
                let reservation = try transaction.getDocument(reservationRef)
                guard !reservation.exists else {
                    errorPointer?.pointee = PatientSchedulingError.slotUnavailable as NSError
                    return nil
                }

                transaction.setData([
                    "therapistId": slot.therapistId,
                    "availabilityId": slot.availabilityId,
                    "slotId": slot.id,
                    "startAt": Timestamp(date: slot.startAt),
                    "appointmentId": appointmentRef.documentID,
                    "createdAt": FieldValue.serverTimestamp()
                ], forDocument: reservationRef)

                transaction.setData([
                    "patientId": patientId,
                    "therapistId": slot.therapistId,
                    "providerName": providerName,
                    "startAt": Timestamp(date: slot.startAt),
                    "availabilityId": slot.availabilityId,
                    "slotId": slot.id,
                    "durationMinutes": slot.durationMinutes,
                    "status": "scheduled",
                    "createdAt": FieldValue.serverTimestamp()
                ], forDocument: appointmentRef)

                return nil
            } catch {
                errorPointer?.pointee = error as NSError
                return nil
            }
        }) { _, error in
            if let error {
                completion(.failure(error))
            } else {
                completion(.success(()))
            }
        }
    }
}

enum PatientSchedulingError: LocalizedError {
    case slotUnavailable

    var errorDescription: String? {
        "That appointment was just booked. Please choose another time."
    }
}
