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
    
    func login(email: String, password: String, completion: @escaping (String?) -> Void) {
        AuthManager.shared.logIn(email: email, password: password) { [weak self] result in
            DispatchQueue.main.async {
                switch result {
                case .success(let user):
                    self?.currentUserId = user.uid
                    self?.isLoggedIn = true
                    completion(nil)
                    
                case .failure(let error):
                    self?.isLoggedIn = false
                    self?.currentUserId = nil
                    completion(error.localizedDescription)
                }
            }
        }
    }
}
