//
//  DailyLog.swift
//  Boba
//
//  Created by Julia Maia on 4/1/26.
//
import FirebaseFirestore

struct DailyLog: Codable {
    @DocumentID var id: String?
    var date: Date
    var mood: String
    //var tags: [String]
    //var hydration: Double
    //var sleep: Double
    var notes: String
}
