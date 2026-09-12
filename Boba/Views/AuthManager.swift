/**
 * AuthManager.swift
 *
 * Overview: Encapsulates Firebase Authentication operations used by the Boba
 * app's sign-up, sign-in, verification, and recovery flows.
 *
 * Contains:
 * - A shared authentication manager for coordinating Firebase Auth requests.
 * - User registration, login, sign-out, and password-reset operations.
 * - Email-verification refresh and related Firestore profile synchronization.
 *
 * Date: September 10, 2026
 * Attribution: BOBA t team
 * Copyright: Copyright © 2026 BOBA t. All rights reserved.
 */

import FirebaseFirestore
import FirebaseAuth
import Foundation

class AuthManager {
    static let shared = AuthManager()
    private init() {}

    // Create a new user
    func signUp(email: String, password: String, completion: @escaping (Result<User, Error>) -> Void) {
        Auth.auth().createUser(withEmail: email, password: password) { result, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            if let user = result?.user {
                completion(.success(user))
            }
        }
    }
    
    // Log in an existing user
    func logIn(email: String, password: String, completion: @escaping (Result<User, Error>) -> Void) {
         Auth.auth().signIn(withEmail: email, password: password) { result, error in
             if let error = error {
                 completion(.failure(error))
                 return
             }
             if let user = result?.user {
                 completion(.success(user))
             }
         }
     }
    
    // Send Firebase's built-in email verification message.
    func sendEmailVerification(completion: @escaping (Error?) -> Void) {
        guard let user = Auth.auth().currentUser else {
            completion(NSError(
                domain: "Boba.Auth",
                code: 1,
                userInfo: [NSLocalizedDescriptionKey: "No authenticated user was found."]
            ))
            return
        }

        user.sendEmailVerification(completion: completion)
    }

    // Send a password reset message for the email-only sign-in flow.
    func sendPasswordReset(email: String, completion: @escaping (Error?) -> Void) {
        Auth.auth().sendPasswordReset(withEmail: email, completion: completion)
    }

    // Refresh Firebase Auth's server-side verification state and mirror it in Firestore.
    func refreshEmailVerificationStatus(completion: @escaping (Result<Bool, Error>) -> Void) {
        guard let user = Auth.auth().currentUser else {
            completion(.failure(NSError(
                domain: "Boba.Auth",
                code: 2,
                userInfo: [NSLocalizedDescriptionKey: "No authenticated user was found."]
            )))
            return
        }

        user.reload { error in
            if let error {
                completion(.failure(error))
                return
            }

            guard let refreshedUser = Auth.auth().currentUser else {
                completion(.failure(NSError(
                    domain: "Boba.Auth",
                    code: 3,
                    userInfo: [NSLocalizedDescriptionKey: "The authenticated user could not be refreshed."]
                )))
                return
            }

            // Refresh the ID token too, so rules that inspect
            // request.auth.token.email_verified see the new value.
            refreshedUser.getIDTokenForcingRefresh(true, completion: { _, tokenError in
                if let tokenError {
                    completion(.failure(tokenError))
                    return
                }

                Firestore.firestore()
                    .collection("users")
                    .document(refreshedUser.uid)
                    .setData([
                        "emailVerified": refreshedUser.isEmailVerified,
                        "updatedAt": FieldValue.serverTimestamp()
                    ], merge: true) { firestoreError in
                        if let firestoreError {
                            completion(.failure(firestoreError))
                        } else {
                            completion(.success(refreshedUser.isEmailVerified))
                        }
                    }
            })
        }
    }

    // Save the account details collected during role selection.
    func createUserProfile(
        user: User,
        firstName: String,
        lastName: String,
        role: String,
        completion: ((Error?) -> Void)? = nil
    ) {
        let db = Firestore.firestore()
        let userRef = db.collection("users").document(user.uid)
        
        var userData: [String: Any] = [
            "uid": user.uid,
            "email": user.email ?? "",
            "firstName": firstName,
            "lastName": lastName,
            "role": role,
            "emailVerified": user.isEmailVerified,
            "createdAt": FieldValue.serverTimestamp()
        ]
        
        guard role == "patient" else {
            // Therapists just get created normally, no counter needed.
            userRef.setData(userData) { error in
                completion?(error)
            }
            return
        }

        let counterRef = db.collection("counters").document("patients")

        db.runTransaction({ (transaction, errorPointer) -> Any? in
            let counterSnapshot: DocumentSnapshot
            do {
                counterSnapshot = try transaction.getDocument(counterRef)
            } catch let fetchError as NSError {
                errorPointer?.pointee = fetchError
                return nil
            }

            let currentNumber = counterSnapshot.exists ? (counterSnapshot.data()?["lastNumber"] as? Int ?? 0) : 0
                let nextNumber = currentNumber + 1

                // Prepare all mutations first
                var updatedUserData = userData
                updatedUserData["patientNumber"] = nextNumber

                // Execute all writes at the very end
                transaction.setData(["lastNumber": nextNumber], forDocument: counterRef, merge: true)
                transaction.setData(updatedUserData, forDocument: userRef)

                return nextNumber
        }) { (_, error) in
            completion?(error)
        }
    }
    

    // Save the patient onboarding fields. The PIN remains deliberately unavailable.
    func updatePatientProfile(
        userID: String,
        firstName: String,
        lastName: String,
        birthday: Date,
        emergencyContactName: String,
        emergencyContactRelationship: String,
        emergencyContactPhone: String,
        wellnessGoals: [String],
        completion: ((Error?) -> Void)? = nil
    ) {
        let patientData: [String: Any] = [
            "firstName": firstName,
            "lastName": lastName,
            "birthday": Timestamp(date: birthday),
            "emergencyContactName": emergencyContactName,
            "emergencyContactRelationship": emergencyContactRelationship,
            "emergencyContactPhone": emergencyContactPhone,
            "wellnessGoals": wellnessGoals,
            "entryPinStatus": "comingSoon",
            "patientOnboardingComplete": true,
            "updatedAt": FieldValue.serverTimestamp()
        ]

        Firestore.firestore()
            .collection("users")
            .document(userID)
            .setData(patientData, merge: true, completion: completion)
    }

    // Save therapist text fields while the document-upload feature is deferred.
    func updateTherapistProfile(
        userID: String,
        clinicalTitle: String,
        licenseNumber: String,
        issuingBoard: String,
        licenseExpirationDate: Date,
        practiceName: String,
        npi: String,
        specialties: [String],
        completion: ((Error?) -> Void)? = nil
    ) {
        let therapistData: [String: Any] = [
            "clinicalTitle": clinicalTitle,
            "licenseNumber": licenseNumber,
            "issuingBoard": issuingBoard,
            "licenseExpirationDate": Timestamp(date: licenseExpirationDate),
            "practiceName": practiceName,
            "npi": npi,
            "practiceSpecialties": specialties,
            "licenseDocumentStatus": "comingSoon",
            "verificationStatus": "placeholder",
            "therapistOnboardingComplete": true,
            "updatedAt": FieldValue.serverTimestamp()
        ]

        Firestore.firestore()
            .collection("users")
            .document(userID)
            .setData(therapistData, merge: true, completion: completion)
    }

    // Sign out
    func signOut() throws {
        try Auth.auth().signOut()
    }

    // Get currently logged in user ID
    var currentUserID: String? {
        return Auth.auth().currentUser?.uid
    }
}
