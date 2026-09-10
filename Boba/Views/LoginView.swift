/**
 * LoginView.swift
 *
 * Overview: Provides the sign-in screen for returning Boba users and supports
 * account recovery when a password has been forgotten.
 *
 * Contains:
 * - Email and password input with validation and loading state.
 * - Password visibility controls and Firebase sign-in handling.
 * - Password-reset feedback and navigation into account creation.
 *
 * Date: September 10, 2026
 * Attribution: BOBA t team
 * Copyright: Copyright © 2026 BOBA t. All rights reserved.
 */

import SwiftUI

struct LoginView: View {
    @EnvironmentObject var session: SessionManager

    @State private var email = ""
    @State private var password = ""
    @State private var isLoading = false
    @State private var isResettingPassword = false
    @State private var showPassword = false
    @State private var errorMessage: String?
    @State private var resetMessage: String?

    var body: some View {
        ZStack {
            AuthBackground()

            ScrollView {
                VStack(spacing: 0) {
                    AuthTopBar(title: "SIGN IN")
                        .padding(.bottom, 28)

                    BobaMark()
                        .padding(.bottom, 20)

                    Text("Welcome Back")
                        .font(.system(size: 30, weight: .bold, design: .rounded))
                        .foregroundStyle(Color.themeOnSurface)

                    Text("Find your calm and enter your sanctuary.")
                        .bodyTextStyle()
                        .foregroundStyle(Color.themeOnSurfaceVariant)
                        .multilineTextAlignment(.center)
                        .padding(.top, 6)
                        .padding(.bottom, 34)

                    VStack(alignment: .leading, spacing: 18) {
                        AuthFieldLabel(icon: "envelope", title: "Email Address")
                        TextField("your.sanctuary@domain.com", text: $email)
                            .authFieldStyle()
                            .keyboardType(.emailAddress)
                            .textInputAutocapitalization(.never)
                            .autocorrectionDisabled()
                            .textContentType(.emailAddress)

                        HStack {
                            AuthFieldLabel(icon: "lock", title: "Password")
                            Spacer()
                            Button("Forgot Password?") {
                                resetPassword()
                            }
                            .font(.system(size: 12, weight: .medium))
                            .foregroundStyle(Color.themePrimary)
                            .disabled(isResettingPassword)
                        }

                        HStack(spacing: 8) {
                            Group {
                                if showPassword {
                                    TextField("••••••••••••", text: $password)
                                } else {
                                    SecureField("••••••••••••", text: $password)
                                }
                            }
                            .textContentType(.password)

                            Button {
                                showPassword.toggle()
                            } label: {
                                Image(systemName: showPassword ? "eye.slash" : "eye")
                                    .foregroundStyle(Color.themeOnSurfaceVariant)
                            }
                            .accessibilityLabel(showPassword ? "Hide password" : "Show password")
                        }
                        .authFieldStyle()

                        if let errorMessage {
                            Text(errorMessage)
                                .font(.caption)
                                .foregroundStyle(Color.themeError)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }

                        Button(action: handleLogin) {
                            HStack(spacing: 10) {
                                if isLoading {
                                    ProgressView().tint(.white)
                                } else {
                                    Text("Sign In")
                                    Image(systemName: "arrow.right")
                                }
                            }
                            .font(.system(size: 16, weight: .bold))
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 17)
                            .background(Color.primaryGradient, in: Capsule())
                        }
                        .disabled(isLoading)
                    }
                    .padding(24)
                    .authPanel()

                    HStack(spacing: 5) {
                        Text("Don't have an account?")
                        NavigationLink("Create one", destination: SignUpView())
                            .fontWeight(.semibold)
                            .foregroundStyle(Color.themePrimary)
                    }
                    .font(.system(size: 12))
                    .foregroundStyle(Color.themeOnSurfaceVariant)
                    .padding(.top, 34)

                    if let resetMessage {
                        Text(resetMessage)
                            .font(.caption)
                            .foregroundStyle(Color.themeTertiary)
                            .multilineTextAlignment(.center)
                            .padding(.top, 12)
                    }
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 30)
            }
        }
        .navigationBarBackButtonHidden(true)
    }

    private func handleLogin() {
        isLoading = true
        errorMessage = nil

        session.login(email: email, password: password) { error in
            isLoading = false
            errorMessage = error
        }
    }

    private func resetPassword() {
        let trimmedEmail = email.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedEmail.isEmpty else {
            errorMessage = "Enter your email address first."
            return
        }

        isResettingPassword = true
        errorMessage = nil
        AuthManager.shared.sendPasswordReset(email: trimmedEmail) { error in
            isResettingPassword = false
            if let error {
                errorMessage = error.localizedDescription
            } else {
                resetMessage = "A password reset link is on its way."
            }
        }
    }
}

#Preview {
    NavigationStack {
        LoginView()
    }
    .environmentObject(SessionManager())
}
