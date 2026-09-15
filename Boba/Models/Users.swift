/**
 * Users.swift
 *
 * Overview: Defines the user data model to represent patients and therpists that use the app. 
 *
 * Contains:
 * - A Codable DailyLog model for Firestore serialization.
 * - Document identity, date, mood, and notes fields, with room for future
 *   wellness tracking fields.
 *
 * Date: September 10, 2026
 * Attribution: BOBA t team
 * Copyright: Copyright © 2026 BOBA t. All rights reserved.
 */

import FirebaseFirestore

enum UserRole: String, Codable {
    case patient
    case therapist
}

struct UserProfile: Codable {
    @DocumentID var id: String?
    var uid: String?
    var firstName: String?
    var lastName: String?
    var role: UserRole?
    var patientNumber: Int?
}
