/**
 * DailyLog.swift
 *
 * Overview: Defines the persisted daily wellness journal entry used to record
 * a patient's mood and reflections.
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

struct DailyLog: Codable {
    @DocumentID var id: String?
    var date: Date
    var mood: String
    var tags: [String]
    var hydration: Double
    var sleep: Double
    var notes: String
}
