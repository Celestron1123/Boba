//
//  AuthManager.swift
//  Boba
//
//  Created by Julia Maia on 9/8/26.
//

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

    // Save profile details to Firestore
    func createUserProfile(user: User, username: String, completion: ((Error?) -> Void)? = nil) {
        let db = Firestore.firestore()
        let userData: [String: Any] = [
            "uid": user.uid,
            "email": user.email ?? "",
            "username": username,
            "createdAt": FieldValue.serverTimestamp()
        ]
        
        db.collection("users").document(user.uid).setData(userData) { error in
            if let error = error {
                print("Error saving profile: \(error.localizedDescription)")
            } else {
                print("Profile saved successfully!")
            }
            completion?(error)
        }
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
