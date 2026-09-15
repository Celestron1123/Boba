/**
 * SessionManager.swift
 *
 * Overview: Coordinates the authenticated user's session and exposes session
 * state to SwiftUI views throughout the Boba app.
 *
 * Contains:
 * - Observable login state and the current Firebase user identifier.
 * - Login, logout, session activation, and email-verification refresh flows.
 * - Local session cleanup when authentication is no longer valid.
 *
 * Date: September 10, 2026
 * Attribution: BOBA t team
 * Copyright: Copyright © 2026 BOBA t. All rights reserved.
 */
import FirebaseAuth
import FirebaseFirestore
import SwiftUI
import Combine

class SessionManager: ObservableObject {
    @Published var isLoggedIn: Bool = false
    @Published var currentUserId: String?
    @Published var userRole: UserRole?
    @Published var isLoadingRole = false
    
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

                    self?.activateSession(for: user)
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
        userRole = nil
        isLoadingRole = true
        loadRole(for: user.uid)
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
        userRole = nil
        isLoadingRole = false
    }

    private func loadRole(for userID: String) {
        Firestore.firestore()
            .collection("users")
            .document(userID)
            .getDocument { [weak self] snapshot, error in
                DispatchQueue.main.async {
                    guard let self else { return }
                    self.isLoadingRole = false
                    if let error {
                        print("Unable to load user role: \(error.localizedDescription)")
                        return
                    }
                    guard let roleValue = snapshot?.data()?["role"] as? String,
                          let role = UserRole(rawValue: roleValue) else {
                        print("User profile does not contain a valid role.")
                        return
                    }
                    self.userRole = role
                }
            }
    }
}
