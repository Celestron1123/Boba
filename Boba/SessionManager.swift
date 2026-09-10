//
//  SessionManager.swift
//  Boba
//
//  Created by Julia Maia on 4/15/26.
//
import FirebaseAuth
import SwiftUI
import Combine

class SessionManager: ObservableObject {
    @Published var isLoggedIn: Bool = false
    @Published var currentUserId: String?
    
    func login(email: String, password: String, completion: @escaping (String?) -> Void) {
        let trimmedEmail = email.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !trimmedEmail.isEmpty, !password.isEmpty else {
            completion("Please enter your email and password.")
            return
        }

        AuthManager.shared.logIn(email: trimmedEmail, password: password) { [weak self] result in
            DispatchQueue.main.async {
                switch result {
                case .success(let user):
                    guard user.isEmailVerified else {
                        try? AuthManager.shared.signOut()
                        self?.clearSession()
                        completion("Please verify your email address before signing in.")
                        return
                    }

                    self?.currentUserId = user.uid
                    self?.isLoggedIn = true
                    AuthManager.shared.refreshEmailVerificationStatus { _ in }
                    completion(nil)

                case .failure(let error):
                    self?.clearSession()
                    completion(error.localizedDescription)
                }
            }
        }
    }

    func activateSession(for user: User) {
        currentUserId = user.uid
        isLoggedIn = true
        refreshEmailVerificationStatus()
    }

    func refreshEmailVerificationStatus() {
        guard isLoggedIn else { return }
        AuthManager.shared.refreshEmailVerificationStatus { result in
            if case .failure(let error) = result {
                print("Unable to refresh email verification status: \(error.localizedDescription)")
            }
        }
    }

    func logout() -> String? {
        do {
            try AuthManager.shared.signOut()
            clearSession()
            return nil
        } catch {
            return error.localizedDescription
        }
    }

    private func clearSession() {
        isLoggedIn = false
        currentUserId = nil
    }
}
