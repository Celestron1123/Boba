//
//  Users.swift
//  Boba
//
//  Created by Julia Maia on 4/8/26.
//
import FirebaseFirestore

struct Users: Codable {
    @DocumentID var id: String?
    var firstName: String
    var lasName: String
    var email: String
    var birthday: Date?
}
