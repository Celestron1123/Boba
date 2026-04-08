//
//  Appointment.swift
//  Boba
//
//  Created by Yudith Mendoza on 4/8/26.
//
import FirebaseFirestore

struct Appointment: Codable, Identifiable {
    @DocumentID var id: String?
    var Date: Date
    var Patient: String
    var Provider: String
    var Time: String
    
}
