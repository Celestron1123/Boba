//
//  SignUpView.swift
//  Boba
//
//  Created by Julia Maia on 9/8/26.
//  Modified by Yudith Mendoza on 9/8/26

import SwiftUI
import FirebaseAuth

struct SignUpView: View {
    @Environment(\.dismiss) private var dismiss

    @State private var firstName = ""
    @State private var lastName = ""
    @State private var email = ""
    @State private var birthday = Calendar.current.date(
        byAdding: .year,
        value: -18,
        to: Date()
    ) ?? Date()
    @State private var password = ""
    @State private var isLoading = false
    @State private var errorMessage: String?

    var body: some View {
        ZStack {
            Color.themeBackground
                .ignoresSafeArea()

            Circle()
                .fill(Color.themeSecondaryContainer.opacity(0.4))
                .frame(width: 300, height: 300)
                .offset(x: 100, y: -300)

            ScrollView {
                VStack(spacing: DS.Spacing.xl) {
                    // Header Section
                    VStack(spacing: DS.Spacing.xs) {
                        Text("Create Account")
                            .headlineTextStyle()
                            .foregroundColor(.themeOnSurface)

                        Text("Sign up to get started")
                            .bodyTextStyle()
                            .foregroundColor(.themeOnSurfaceVariant)
                    }
                    .padding(.top, DS.Spacing.xl)

                    VStack(spacing: DS.Spacing.lg) {
                        // Input Fields
                        VStack(alignment: .leading, spacing: DS.Spacing.sm) {
                            Label("First Name", systemImage: "person")
                                .bodyTextStyle(weight: .medium)
                                .foregroundColor(.themePrimary)

                            TextField("Enter your first name", text: $firstName)
                                .padding()
                                .background(Color.themeSurface.opacity(0.5))
                                .cornerRadius(DS.Radius.sm)
                                .textContentType(.givenName)
                        }

                        VStack(alignment: .leading, spacing: DS.Spacing.sm) {
                            Label("Last Name", systemImage: "person")
                                .bodyTextStyle(weight: .medium)
                                .foregroundColor(.themePrimary)

                            TextField("Enter your last name", text: $lastName)
                                .padding()
                                .background(Color.themeSurface.opacity(0.5))
                                .cornerRadius(DS.Radius.sm)
                                .textContentType(.familyName)
                        }

                        VStack(alignment: .leading, spacing: DS.Spacing.sm) {
                            Label("Email", systemImage: "envelope")
                                .bodyTextStyle(weight: .medium)
                                .foregroundColor(.themePrimary)

                            TextField("Enter your email", text: $email)
                                .padding()
                                .background(Color.themeSurface.opacity(0.5))
                                .cornerRadius(DS.Radius.sm)
                                .keyboardType(.emailAddress)
                                .textInputAutocapitalization(.never)
                                .autocorrectionDisabled()
                                .textContentType(.emailAddress)
                        }

                        VStack(alignment: .leading, spacing: DS.Spacing.sm) {
                            Label("Birthday", systemImage: "calendar")
                                .bodyTextStyle(weight: .medium)
                                .foregroundColor(.themePrimary)

                            DatePicker(
                                "Select your birthday",
                                selection: $birthday,
                                in: ...Date(),
                                displayedComponents: .date
                            )
                            .datePickerStyle(.compact)
                            .padding()
                            .background(Color.themeSurface.opacity(0.5))
                            .cornerRadius(DS.Radius.sm)
                        }

                        VStack(alignment: .leading, spacing: DS.Spacing.sm) {
                            Label("Password", systemImage: "lock")
                                .bodyTextStyle(weight: .medium)
                                .foregroundColor(.themePrimary)

                            SecureField("••••••••", text: $password)
                                .padding()
                                .background(Color.themeSurface.opacity(0.5))
                                .cornerRadius(DS.Radius.sm)
                                .textContentType(.newPassword)
                        }

                        if let errorMessage {
                            Text(errorMessage)
                                .font(.caption)
                                .foregroundColor(.themeError)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }

                        Button(action: handleSignUp) {
                            HStack {
                                if isLoading {
                                    ProgressView()
                                        .tint(.white)
                                } else {
                                    Text("Sign Up")
                                        .bodyTextStyle(weight: .bold)
                                }
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.themePrimary)
                            .foregroundColor(.white)
                            .cornerRadius(DS.Radius.md)
                        }
                        .disabled(isLoading)
                    }
                    .padding(DS.Spacing.xl)
                    .glassCard()

                    // Footer
                    HStack(spacing: DS.Spacing.xs) {
                        Text("Already have an account?")
                            .foregroundColor(.themeOnSurfaceVariant)

                        Button("Sign In") {
                            dismiss()
                        }
                        .bodyTextStyle(weight: .bold)
                        .foregroundColor(.themeSecondary)
                    }
                    .bodyTextStyle(weight: .medium)
                }
                .padding(.horizontal, DS.Spacing.lg)
                .padding(.bottom, DS.Spacing.xl)
            }
        }
    }

    private func handleSignUp() {
        let trimmedFirstName = firstName.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedLastName = lastName.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedEmail = email.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !trimmedFirstName.isEmpty,
              !trimmedLastName.isEmpty,
              !trimmedEmail.isEmpty,
              !password.isEmpty else {
            errorMessage = "Please complete all fields."
            return
        }

        isLoading = true
        errorMessage = nil

        AuthManager.shared.signUp(email: trimmedEmail, password: password) { result in
            switch result {
            case .success(let user):
                AuthManager.shared.createUserProfile(
                    user: user,
                    firstName: trimmedFirstName,
                    lastName: trimmedLastName,
                    birthday: birthday
                ) { error in
                    isLoading = false

                    if let error {
                        errorMessage = error.localizedDescription
                    } else {
                        dismiss()
                    }
                }

            case .failure(let error):
                isLoading = false
                errorMessage = error.localizedDescription
            }
        }
    }
}

struct SignUpView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationStack {
            SignUpView()
        }
    }
}
