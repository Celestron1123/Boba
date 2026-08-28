//  LoginView.swift
//  Boba
//
//  Created by Julia Maia on 4/15/26.
//

import SwiftUI
import FirebaseFirestore

struct LoginView: View {
    @EnvironmentObject var session: SessionManager
    @State private var username: String = ""
    @State private var password: String = ""
    @State private var isLoading: Bool = false
    @State private var errorMessage: String? = nil
    
    var body: some View {
        ZStack {
            Color.themeBackground
                .ignoresSafeArea()
            
            Circle()
                .fill(Color.themeSecondaryContainer.opacity(0.4))
                .frame(width: 300, height: 300)
                .offset(x: 100, y: -300)
            
            VStack(spacing: DS.Spacing.xl) {
                
                // Header Section
                VStack(spacing: DS.Spacing.xs) {
                    Text("Welcome Back")
                        .headlineTextStyle()
                        .foregroundColor(.themeOnSurface)
                    
                    Text("Sign in to continue")
                        .bodyTextStyle()
                        .foregroundColor(.themeOnSurfaceVariant)
                }
                .padding(.top, DS.Spacing.xl)

                VStack(spacing: DS.Spacing.lg) {
                    
                    // Input Fields
                    VStack(alignment: .leading, spacing: DS.Spacing.sm) {
                        Label("Username", systemImage: "person")
                            .bodyTextStyle(weight: .medium)
                            .foregroundColor(.themePrimary)
                        
                        TextField("Enter your username", text: $username)
                            .padding()
                            .background(Color.themeSurface.opacity(0.5))
                            .cornerRadius(DS.Radius.sm)
                            .textInputAutocapitalization(.never)
                    }
                    
                    VStack(alignment: .leading, spacing: DS.Spacing.sm) {
                        Label("Password", systemImage: "lock")
                            .bodyTextStyle(weight: .medium)
                            .foregroundColor(.themePrimary)
                        
                        SecureField("••••••••", text: $password)
                            .padding()
                            .background(Color.themeSurface.opacity(0.5))
                            .cornerRadius(DS.Radius.sm)
                    }
                    
                    if let error = errorMessage {
                        Text(error)
                            .font(.caption)
                            .foregroundColor(.themeError)
                    }

                    Button(action: handleLogin) {
                        HStack {
                            if isLoading {
                                ProgressView()
                                    .tint(.white)
                            } else {
                                Text("Sign In")
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

                .bodyTextStyle(weight: .medium)
                .foregroundColor(.themeSecondary)
            }
            .padding(.horizontal, DS.Spacing.lg)
        }
    }
    
    private func handleLogin() {
        isLoading = true
        errorMessage = nil
        
        session.login(email: username, password: password) { error in
                isLoading = false
                if let error = error {
                    self.errorMessage = error
            }

        }
    }
}

// Preview provider for canvas testing
struct LoginView_Previews: PreviewProvider {
    static var previews: some View {
        LoginView()
            .environmentObject(SessionManager())
    }
}

