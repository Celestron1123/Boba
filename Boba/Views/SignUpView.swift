//
//  SignUpView.swift
//  Boba
//
//  Created by Julia Maia on 9/8/26.
//
import SwiftUI
import FirebaseAuth
import FirebaseFirestore

struct SignUpView: View {
    @State private var email = ""
    @State private var password = ""
    @State private var username = ""

    var body: some View {
        VStack {
            TextField("Username", text: $username)
            TextField("Email", text: $email)
            SecureField("Password", text: $password)

            Button("Sign Up") {
                // Call AuthManager when button is pressed
                AuthManager.shared.signUp(email: email, password: password) { result in
                    switch result {
                    case .success(let user):
                        // Save profile to Firestore after successful signup
                        AuthManager.shared.createUserProfile(user: user, username: username)
                    case .failure(let error):
                        print("Error: \(error.localizedDescription)")
                    }
                }
            }
        }
    }
}
