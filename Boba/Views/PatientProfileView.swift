/**
 * PatientProfileView.swift
 *
 * Overview: Shows the authenticated patient's profile and care information in
 * a single scrollable screen.
 *
 * Contains:
 * - Firestore-backed identity, birthday, and contact information.
 * - Provider, emergency-contact, medication, and diagnosis cards.
 * - Logout confirmation, error handling, and session termination controls.
 *
 * Date: September 10, 2026
 * Attribution: BOBA t team
 * Copyright: Copyright © 2026 BOBA t. All rights reserved.
 */

import SwiftUI
import FirebaseFirestore

struct PatientProfileView: View {
    @EnvironmentObject private var session: SessionManager
    @State private var isShowingLogoutConfirmation = false
    @State private var logoutError: String?
    @State private var firstName = ""
    @State private var lastName = ""
    @State private var email = ""
    @State private var birthday: Date?
    @State private var isLoadingProfile = true
    @State private var profileLoadError: String?
    @State private var providers: [PatientProviderConnection] = []
    @State private var isLoadingProviders = true
    @State private var providerLoadError: String?
    @State private var providerListener: ListenerRegistration?

    var body: some View {
        ZStack {
            Color.themeSurface.ignoresSafeArea()
            
            VStack(spacing: 0) {
                TopAppBar()
                
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 24) {
                        heroSection
                        
                        currentProviderCard
                        emergencyContactCard
                        medicationsCard
                        diagnosesCard
                        logoutButton
                        
                        Spacer().frame(height: 120)
                    }
                    .padding(.horizontal, 24)
                    .padding(.top, 24)
                }
            }
        }
        .confirmationDialog(
            "Are you sure you want to log out?",
            isPresented: $isShowingLogoutConfirmation,
            titleVisibility: .visible
        ) {
            Button("Log Out", role: .destructive, action: handleLogout)
            Button("Cancel", role: .cancel) { }
        }
        .alert("Unable to Log Out", isPresented: isShowingLogoutError) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(logoutError ?? "Please try again.")
        }
        .task {
            loadProfile()
            observeProviders()
        }
        .onDisappear {
            providerListener?.remove()
            providerListener = nil
        }
    }
    
    var heroSection: some View {
        HStack(alignment: .bottom, spacing: 24) {
            ZStack(alignment: .bottomTrailing) {
                Image(systemName: "person.crop.rectangle.fill")
                    .resizable()
                    .frame(width: 120, height: 120)
                    .foregroundColor(.themeSurfaceContainerHighest)
                    .cornerRadius(16)
                    .shadow(radius: 10)
                
                Circle()
                    .fill(Color.themeTertiaryContainer)
                    .frame(width: 16, height: 16)
                    .overlay(Circle().stroke(Color.white, lineWidth: 2))
                    .offset(x: 8, y: 8)
            }
            
            VStack(alignment: .leading, spacing: 8) {
                if isLoadingProfile {
                    ProgressView("Loading profile...")
                        .tint(.themePrimary)
                } else {
                    Text(displayName)
                        .headlineText(size: 32, weight: .heavy)
                        .foregroundColor(.themeOnSurface)

                    Text(formattedBirthday)
                        .bodyText(size: 16, weight: .medium)
                        .foregroundColor(.themeOnSurfaceVariant)

                    Text(email.isEmpty ? "Email not available" : email)
                        .bodyText(size: 14)
                        .foregroundColor(.themeOnSurfaceVariant)
                }

                if let profileLoadError {
                    Text(profileLoadError)
                        .font(.caption)
                        .foregroundColor(.themeError)
                }
            }
            Spacer()
        }
        .padding(.top, 16)
    }
    
    var currentProviderCard: some View {
        VStack(spacing: 24) {
            HStack {
                Text("Your Care Team")
                    .headlineText(size: 20, weight: .bold)
                    .foregroundColor(.themePrimary)
                Spacer()
                Image(systemName: "checkmark.shield.fill")
                    .foregroundStyle(Color.themeTertiary)
            }

            if isLoadingProviders {
                ProgressView("Loading your provider…")
                    .tint(.themePrimary)
                    .frame(maxWidth: .infinity, alignment: .leading)
            } else if providers.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "person.crop.circle.badge.questionmark")
                        .font(.system(size: 32))
                        .foregroundStyle(Color.themePrimary)
                    Text("No provider connected yet")
                        .headlineText(size: 17, weight: .bold)
                    Text("Your provider will appear here after they've connected with you.")
                        .bodyText(size: 14)
                        .foregroundStyle(Color.themeOnSurfaceVariant)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
            } else {
                ForEach(providers) { provider in
                    providerRow(provider)
                }
            }

            if let providerLoadError {
                Text(providerLoadError)
                    .font(.caption)
                    .foregroundStyle(Color.themeError)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }

            Text("Provider connections are managed by your care team and are view-only from your account.")
                .bodyText(size: 12)
                .foregroundStyle(Color.themeOnSurfaceVariant.opacity(0.72))
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(32)
        .glassCard()
    }

    private func providerRow(_ provider: PatientProviderConnection) -> some View {
        HStack(alignment: .top, spacing: 20) {
            ZStack(alignment: .bottomTrailing) {
                Image(systemName: "person.crop.square.fill")
                    .resizable()
                    .frame(width: 78, height: 78)
                    .foregroundColor(.themeSurfaceContainerHighest)
                    .cornerRadius(12)

                Circle()
                    .fill(Color.themeTertiary)
                    .frame(width: 18, height: 18)
                    .overlay(Circle().stroke(Color.themeSurface, lineWidth: 2))
            }

            VStack(alignment: .leading, spacing: 8) {
                Text(provider.displayName)
                    .headlineText(size: 18, weight: .bold)
                    .foregroundColor(.themeOnSurface)

                if !provider.professionalDetails.isEmpty {
                    Text(provider.professionalDetails)
                        .bodyText(size: 14)
                        .foregroundColor(.themeOnSurfaceVariant)
                }

                if !provider.specialties.isEmpty {
                    Text(provider.specialties.prefix(2).joined(separator: " • "))
                        .bodyText(size: 12, weight: .medium)
                        .foregroundStyle(Color.themeTertiary)
                }

                Label("Connected provider", systemImage: "link")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(Color.themePrimary)
            }

            Spacer()
        }
        .padding(16)
        .background(Color.themeSurfaceContainerLow.opacity(0.65), in: RoundedRectangle(cornerRadius: DS.Radius.md))
    }
    
    var emergencyContactCard: some View {
        VStack(alignment: .leading, spacing: 24) {
            HStack(spacing: 12) {
                Circle()
                    .fill(Color.themeSecondary)
                    .frame(width: 40, height: 40)
                    .overlay(Image(systemName: "staroflife.fill").foregroundColor(.white))
                
                Text("Emergency Contact")
                    .headlineText(size: 20, weight: .bold)
                    .foregroundColor(.themeOnSecondaryContainer)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text("Mark Johnson")
                    .headlineText(size: 18, weight: .bold)
                Text("Relationship: Brother")
                    .bodyText(size: 16)
                    .foregroundColor(.themeOnSurfaceVariant)
                Text("+1 (555) 012-3456")
                    .bodyText(size: 16, weight: .medium)
                    .foregroundColor(.themeOnSurfaceVariant)
                    .padding(.top, 8)
            }
            
            Button("Update Contact") {}
                .bodyText(size: 14, weight: .bold)
                .foregroundColor(.themeSecondary)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(Color.white.opacity(0.5))
                .cornerRadius(12)
                .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.themeSecondary.opacity(0.2), lineWidth: 1))
        }
        .padding(32)
        .background(Color.themeSecondaryContainer.opacity(0.3))
        .cornerRadius(24)
    }
    
    var medicationsCard: some View {
        VStack(spacing: 24) {
            HStack {
                Text("Medications")
                    .headlineText(size: 20, weight: .bold)
                    .foregroundColor(.themePrimary)
                Spacer()
                Image(systemName: "pills.fill")
                    .foregroundColor(.themePrimaryContainer)
            }
            
            VStack(spacing: 16) {
                medicationRow(name: "Prozac", details: "20mg • Daily in Morning", status: "ACTIVE", statusColor: .themeTertiary)
                medicationRow(name: "Melatonin", details: "5mg • Before Sleep", status: "AS NEEDED", statusColor: .themeOnSurfaceVariant.opacity(0.6))
            }
            
            Button("+ Add Medication") {}
                .bodyText(size: 14, weight: .medium)
                .foregroundColor(.themeOnSurfaceVariant)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .overlay(RoundedRectangle(cornerRadius: 12).strokeBorder(style: StrokeStyle(lineWidth: 2, dash: [5])).foregroundColor(.themeOutlineVariant))
        }
        .padding(32)
        .glassCard()
    }
    
    func medicationRow(name: String, details: String, status: String, statusColor: Color) -> some View {
        HStack(spacing: 16) {
            Circle()
                .fill(Color.themePrimaryContainer.opacity(0.3))
                .frame(width: 48, height: 48)
                .overlay(Image(systemName: "pill.fill").foregroundColor(.themePrimary))
            
            VStack(alignment: .leading, spacing: 4) {
                Text(name)
                    .bodyText(size: 16, weight: .bold)
                Text(details)
                    .bodyText(size: 12)
                    .foregroundColor(.themeOnSurfaceVariant)
            }
            Spacer()
            
            Text(status)
                .font(.system(size: 10, weight: .bold))
                .tracking(1)
                .foregroundColor(statusColor)
        }
        .padding(16)
        .background(Color.white.opacity(0.4))
        .cornerRadius(12)
    }
    
    var diagnosesCard: some View {
        VStack(spacing: 24) {
            HStack {
                Text("Diagnoses")
                    .headlineText(size: 20, weight: .bold)
                    .foregroundColor(.themePrimary)
                Spacer()
                Image(systemName: "doc.text.fill")
                    .foregroundColor(.themePrimaryContainer)
            }
            
            HStack(spacing: 12) {
                diagnosisTag(name: "General Anxiety Disorder", date: "Confirmed Oct 2023")
                diagnosisTag(name: "Mild Insomnia", date: "Confirmed Jan 2024")
                diagnosisTag(name: "Social Anxiety", date: "Self-Reported")
                Spacer()
            }
            
            HStack(alignment: .top, spacing: 12) {
                Image(systemName: "info.circle.fill")
                    .foregroundColor(.themeTertiary)
                Text("Your diagnoses are only visible to you and your assigned provider to ensure personalized care.")
                    .bodyText(size: 12)
                    .foregroundColor(.themeOnTertiaryContainer)
            }
            .padding(16)
            .background(Color.themeTertiaryContainer.opacity(0.1))
            .cornerRadius(12)
            .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.themeTertiaryContainer.opacity(0.2), lineWidth: 1))
        }
        .padding(32)
        .glassCard()
    }

    var logoutButton: some View {
        Button {
            isShowingLogoutConfirmation = true
        } label: {
            Label("Log Out", systemImage: "rectangle.portrait.and.arrow.right")
                .bodyText(size: 16, weight: .bold)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
        }
        .foregroundColor(.themeError)
        .background(Color.themeError.opacity(0.08))
        .cornerRadius(DS.Radius.md)
        .overlay(
            RoundedRectangle(cornerRadius: DS.Radius.md)
                .stroke(Color.themeError.opacity(0.25), lineWidth: 1)
        )
    }

    private var isShowingLogoutError: Binding<Bool> {
        Binding(
            get: { logoutError != nil },
            set: { isPresented in
                if !isPresented {
                    logoutError = nil
                }
            }
        )
    }

    private func handleLogout() {
        logoutError = session.logout()
    }

    private var displayName: String {
        let fullName = [firstName, lastName]
            .filter { !$0.isEmpty }
            .joined(separator: " ")

        return fullName.isEmpty ? "Patient" : fullName
    }

    private var formattedBirthday: String {
        guard let birthday else {
            return "Birthday not available"
        }

        return "Birthday: \(birthday.formatted(date: .long, time: .omitted))"
    }

    private func loadProfile() {
        guard let userID = session.currentUserId else {
            isLoadingProfile = false
            profileLoadError = "Unable to find the current patient session."
            return
        }

        Firestore.firestore()
            .collection("users")
            .document(userID)
            .getDocument { snapshot, error in
                DispatchQueue.main.async {
                    isLoadingProfile = false

                    if let error {
                        profileLoadError = "Unable to load profile: \(error.localizedDescription)"
                        return
                    }

                    guard let data = snapshot?.data() else {
                        profileLoadError = "Patient profile information was not found."
                        return
                    }

                    firstName = data["firstName"] as? String
                        ?? data["username"] as? String
                        ?? ""
                    lastName = data["lastName"] as? String ?? ""
                    email = data["email"] as? String ?? ""
                    birthday = (data["birthday"] as? Timestamp)?.dateValue()
                    profileLoadError = nil
                }
            }
    }

    private func observeProviders() {
        guard providerListener == nil, let userID = session.currentUserId else {
            isLoadingProviders = false
            return
        }

        providerListener = Firestore.firestore()
            .collection("users")
            .document(userID)
            .collection("providers")
            .addSnapshotListener { snapshot, error in
                DispatchQueue.main.async {
                    isLoadingProviders = false

                    if let error {
                        providerLoadError = "Unable to load your provider: \(error.localizedDescription)"
                        return
                    }

                    providers = snapshot?.documents.compactMap {
                        try? $0.data(as: PatientProviderConnection.self)
                    }
                    .sorted { $0.displayName < $1.displayName } ?? []
                    providerLoadError = nil
                }
            }
    }
    
    func diagnosisTag(name: String, date: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(name)
                .bodyText(size: 14, weight: .bold)
                .fixedSize(horizontal: false, vertical: true)
            Text(date)
                .bodyText(size: 10)
                .foregroundColor(.themeOnSurfaceVariant)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
        .background(Color.themeSurfaceContainerLow)
        .cornerRadius(12)
        .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.themeOutlineVariant.opacity(0.1), lineWidth: 1))
    }
}
