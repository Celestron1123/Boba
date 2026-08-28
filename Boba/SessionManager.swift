//
//  SessionManager.swift
//  Boba
//
//  Created by Julia Maia on 4/15/26.
//
import FirebaseAuth
import FirebaseFirestore
import SwiftUI
import Combine

class SessionManager: ObservableObject {
    @Published var isLoggedIn: Bool = false
    @Published var currentUserId: String?
    
    private let db = Firestore.firestore()
    
    func login(email: String, password: String, completion: @escaping (String?) -> Void) {
        
        db.collection("users")
            .whereField("username", isEqualTo: email)
            .whereField("password", isEqualTo: password)
            .getDocuments { snapshot, error in
                if let error = error {
                    completion(error.localizedDescription)
                    return
                }
                
                if let document = snapshot?.documents.first {
                    DispatchQueue.main.async {
                        self.currentUserId = document.documentID // Use the Firestore Doc ID
                        self.isLoggedIn = true
                        completion(nil)
                    }
                } else {
                    completion("Invalid username or password.")
                }
            }
    }
}
