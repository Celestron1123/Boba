/**
 * SignUpView.swift
 *
 * Overview: Guides new users through selecting an account role and entering
 * the information required to create a Boba account.
 *
 * Contains:
 * - Patient and therapist role definitions and account draft data.
 * - Account-detail, consent, validation, and loading state.
 * - Firebase user creation and transition to the next onboarding step.
 *
 * Date: September 10, 2026
 * Attribution: BOBA t team
 * Copyright: Copyright © 2026 BOBA t. All rights reserved.
 */

import SwiftUI
import FirebaseAuth

enum SignupRole: String {
    case patient
    case therapist

    var title: String {
        self == .patient ? "Patient / Individual" : "Therapist / Clinician"
    }

    var buttonTitle: String {
        self == .patient ? "Continue as Individual" : "Continue as Clinician"
    }
}

struct SignupDraft {
    let firstName: String
    let lastName: String
}

struct SignUpView: View {
    @Environment(\.dismiss) private var dismiss

    @State private var role: SignupRole = .patient
    @State private var firstName = ""
    @State private var lastName = ""
    @State private var email = ""
    @State private var password = ""
    @State private var showPassword = false
    @State private var termsAccepted = false
    @State private var privacyAccepted = false
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var createdUser: User?
    @State private var showNextStep = false

    var body: some View {
        ZStack {
            AuthBackground()

            ScrollView {
                VStack(spacing: 0) {
                    AuthTopBar(title: "CREATE ACCOUNT")
                        .padding(.bottom, 28)

                    Text("STEP 1 OF 2 • WELCOME")
                        .font(.system(size: 11, weight: .bold))
                        .tracking(1.2)
                        .foregroundStyle(Color.themePrimary)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 8)
                        .background(Color.themeSurfaceContainer, in: Capsule())

                    Text("Join Boba")
                        .font(.system(size: 30, weight: .bold, design: .rounded))
                        .foregroundStyle(Color.themeOnSurface)
                        .padding(.top, 18)

                    Text("Choose how you'd like to experience your care sanctuary.")
                        .bodyTextStyle()
                        .foregroundStyle(Color.themeOnSurfaceVariant)
                        .multilineTextAlignment(.center)
                        .padding(.top, 6)
                        .padding(.bottom, 26)

                    VStack(spacing: 14) {
                        RoleCard(role: .patient, selectedRole: $role)
                        RoleCard(role: .therapist, selectedRole: $role)
                    }

                    VStack(alignment: .leading, spacing: 16) {
                        HStack {
                            Text("Account Details")
                                .font(.system(size: 16, weight: .medium))
                            Spacer()
                            Text("Your account")
                                .font(.system(size: 12))
                                .foregroundStyle(Color.themeOnSurfaceVariant)
                        }

                        HStack(spacing: 12) {
                            AuthLabeledField(title: "Legal First Name", icon: "person", text: $firstName, placeholder: "First name")
                            AuthLabeledField(title: "Legal Last Name", icon: "person", text: $lastName, placeholder: "Last name")
                        }

                        AuthFieldLabel(icon: "envelope", title: "Email Address")
                        TextField("name@sanctuary.com", text: $email)
                            .authFieldStyle()
                            .keyboardType(.emailAddress)
                            .textInputAutocapitalization(.never)
                            .autocorrectionDisabled()
                            .textContentType(.emailAddress)

                        AuthFieldLabel(icon: "lock", title: "Password")
                        HStack(spacing: 8) {
                            Group {
                                if showPassword {
                                    TextField("At least 8 gentle characters", text: $password)
                                } else {
                                    SecureField("At least 8 gentle characters", text: $password)
                                }
                            }
                            .textContentType(.newPassword)

                            Button {
                                showPassword.toggle()
                            } label: {
                                Image(systemName: showPassword ? "eye.slash" : "eye")
                                    .foregroundStyle(Color.themeOnSurfaceVariant)
                            }
                            .accessibilityLabel(showPassword ? "Hide password" : "Show password")
                        }
                        .authFieldStyle()

                        ConsentRow(isSelected: $termsAccepted) {
                            Text("I agree to the \(Text("Terms of Sanctuary").underline()).")
                        }

                        ConsentRow(isSelected: $privacyAccepted) {
                            Text("I acknowledge the \(Text("Privacy Policy").underline()).")
                        }

                        if let errorMessage {
                            Text(errorMessage)
                                .font(.caption)
                                .foregroundStyle(Color.themeError)
                        }

                        Button(action: createAccount) {
                            HStack(spacing: 10) {
                                if isLoading {
                                    ProgressView().tint(.white)
                                } else {
                                    Text(role.buttonTitle)
                                    Image(systemName: "arrow.right")
                                }
                            }
                            .font(.system(size: 15, weight: .bold))
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(Color.primaryGradient, in: Capsule())
                        }
                        .disabled(isLoading)
                    }
                    .padding(20)
                    .authPanel()
                    .padding(.top, 24)

                    HStack(spacing: 5) {
                        Text("Already have an account?")
                        Button("Log In") {
                            dismiss()
                        }
                        .fontWeight(.semibold)
                        .foregroundStyle(Color.themePrimary)
                    }
                    .font(.system(size: 12))
                    .foregroundStyle(Color.themeOnSurfaceVariant)
                    .padding(.vertical, 30)

                }
                .padding(.horizontal, 24)
            }
        }
        .navigationBarBackButtonHidden(true)
        .navigationDestination(isPresented: $showNextStep) {
            nextStep
        }
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                BackButton()
            }
        }
    }

    @ViewBuilder
    private var nextStep: some View {
        if let createdUser {
            if role == .patient {
                PatientOnboardingView(
                    user: createdUser,
                    draft: SignupDraft(firstName: firstName, lastName: lastName)
                )
            } else {
                TherapistVerificationView(
                    user: createdUser,
                    draft: SignupDraft(firstName: firstName, lastName: lastName)
                )
            }
        } else {
            EmptyView()
        }
    }

    private func createAccount() {
        let cleanFirstName = firstName.trimmingCharacters(in: .whitespacesAndNewlines)
        let cleanLastName = lastName.trimmingCharacters(in: .whitespacesAndNewlines)
        let cleanEmail = email.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !cleanFirstName.isEmpty, !cleanLastName.isEmpty, !cleanEmail.isEmpty, password.count >= 8 else {
            errorMessage = "Please complete both names, a valid email, and an 8-character password."
            return
        }

        guard termsAccepted && privacyAccepted else {
            errorMessage = "Please acknowledge both account notices to continue."
            return
        }

        isLoading = true
        errorMessage = nil

        AuthManager.shared.signUp(email: cleanEmail, password: password) { result in
            switch result {
            case .failure(let error):
                DispatchQueue.main.async {
                    isLoading = false
                    errorMessage = error.localizedDescription
                }

            case .success(let user):
                AuthManager.shared.createUserProfile(
                    user: user,
                    firstName: cleanFirstName,
                    lastName: cleanLastName,
                    role: role.rawValue
                ) { profileError in
                    if let profileError {
                        DispatchQueue.main.async {
                            isLoading = false
                            errorMessage = profileError.localizedDescription
                        }
                        return
                    }

                    AuthManager.shared.sendEmailVerification { verificationError in
                        DispatchQueue.main.async {
                            isLoading = false
                            if let verificationError {
                                errorMessage = verificationError.localizedDescription
                            } else {
                                createdUser = user
                                showNextStep = true
                            }
                        }
                    }
                }
            }
        }
    }
}

private struct RoleCard: View {
    let role: SignupRole
    @Binding var selectedRole: SignupRole

    private var isSelected: Bool { selectedRole == role }

    var body: some View {
        Button {
            selectedRole = role
        } label: {
            HStack(alignment: .top, spacing: 14) {
                Image(systemName: role == .patient ? "leaf.fill" : "cross.case.fill")
                    .font(.system(size: 17, weight: .bold))
                    .foregroundStyle(role == .patient ? Color.themeTertiary : Color.themeSecondary)
                    .frame(width: 42, height: 42)
                    .background(
                        (role == .patient ? Color.themeTertiaryContainer : Color.themeSecondaryContainer).opacity(0.55),
                        in: Circle()
                    )

                VStack(alignment: .leading, spacing: 5) {
                    Text(role == .patient ? "PERSONAL CARE" : "CLINICAL SUITE")
                        .font(.system(size: 10, weight: .bold))
                        .tracking(1)
                        .foregroundStyle(role == .patient ? Color.themeTertiary : Color.themeSecondary)

                    Text(role.title)
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundStyle(Color.themeOnSurface)

                    Text(role == .patient
                         ? "Daily micro-journaling, mood reflection, gentle habits, and direct connection with your clinician."
                         : "Real-time client trajectories, secure sessions, clinical notes, and care coordination.")
                        .font(.system(size: 12))
                        .foregroundStyle(Color.themeOnSurfaceVariant)
                        .multilineTextAlignment(.leading)

                    HStack(spacing: 6) {
                        SmallTag(text: role == .patient ? "Mindful Check-ins" : "Trajectory Tracking")
                        SmallTag(text: role == .patient ? "Private Journal" : "Credential Profile")
                    }
                }

                Spacer(minLength: 0)

                Image(systemName: isSelected ? "checkmark" : "circle.fill")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(isSelected ? .white : Color.themeOnSurface.opacity(0.12))
                    .frame(width: 24, height: 24)
                    .background(isSelected ? Color.themeTertiary : .clear, in: Circle())
            }
            .padding(16)
            .background(
                isSelected
                    ? Color.themeTertiaryContainer.opacity(0.32)
                    : Color.themeSurfaceContainerLow.opacity(0.72),
                in: RoundedRectangle(cornerRadius: 26)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 26)
                    .stroke(isSelected ? Color.themeTertiary.opacity(0.14) : .clear, lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }
}

struct PatientOnboardingView: View {
    @EnvironmentObject private var session: SessionManager

    let user: User
    @State private var firstName: String
    @State private var lastName: String
    @State private var birthday = Calendar.current.date(byAdding: .year, value: -18, to: Date()) ?? Date()
    @State private var emergencyContactName = ""
    @State private var emergencyContactRelationship = "Partner / Spouse"
    @State private var emergencyContactPhone = ""
    @State private var selectedGoals: Set<String> = []
    @State private var isLoading = false
    @State private var errorMessage: String?

    private let goals = ["Managing Anxiety", "Improving Sleep", "CBT Habits", "Daily Logging", "Depression Support", "Stress Relief"]

    init(user: User, draft: SignupDraft) {
        self.user = user
        _firstName = State(initialValue: draft.firstName)
        _lastName = State(initialValue: draft.lastName)
    }

    var body: some View {
        ZStack {
            AuthBackground()

            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    AuthTopBar(title: "SANCTUARY SETUP")

                    ProgressHeader(step: "STEP 2 OF 2 • PATIENT PROFILE", completion: "100% Complete", progress: 1)
                        .padding(.top, 24)

                    Text("Your Care Profile")
                        .authTitle()
                        .padding(.top, 24)

                    Text("Personalize your healing journey and connect with care.")
                        .bodyTextStyle()
                        .foregroundStyle(Color.themeOnSurfaceVariant)
                        .padding(.top, 6)
                        .padding(.bottom, 24)

                    InfoCard(
                        icon: "lock.fill",
                        title: "Private & Personal",
                        message: "Your personal reflections and care preferences stay connected to your Boba account."
                    )

                    VStack(alignment: .leading, spacing: 16) {
                        SectionHeading(icon: "cross.case.fill", title: "PATIENT ANCHOR & SAFETY NET")

                        DatePicker("Date of Birth", selection: $birthday, in: ...Date(), displayedComponents: .date)
                            .datePickerStyle(.compact)
                            .authInputBackground()

                        HStack(spacing: 12) {
                            AuthLabeledField(title: "Legal First Name", icon: "person", text: $firstName, placeholder: "First name")
                            AuthLabeledField(title: "Legal Last Name", icon: "person", text: $lastName, placeholder: "Last name")
                        }

                        Text("Emergency Intervention Contact")
                            .font(.system(size: 12, weight: .medium))
                        Text("Designated contact if our rapid check-ins detect urgent clinical distress signals.")
                            .font(.system(size: 11))
                            .foregroundStyle(Color.themeOnSurfaceVariant)

                        AuthLabeledField(title: "Contact Name", icon: "person", text: $emergencyContactName, placeholder: "e.g. Alex Rivera")

                        HStack(spacing: 12) {
                            VStack(alignment: .leading, spacing: 6) {
                                Text("Relationship")
                                    .font(.system(size: 12))
                                Menu {
                                    ForEach(["Partner / Spouse", "Parent / Guardian", "Friend", "Sibling", "Other"], id: \.self) { value in
                                        Button(value) { emergencyContactRelationship = value }
                                    }
                                } label: {
                                    HStack {
                                        Text(emergencyContactRelationship)
                                        Spacer()
                                        Image(systemName: "chevron.down")
                                    }
                                    .font(.system(size: 13))
                                    .foregroundStyle(Color.themeOnSurface)
                                    .padding(13)
                                    .background(Color.themeSurfaceContainerHigh, in: Capsule())
                                }
                            }

                            AuthLabeledField(title: "Phone Number", icon: "phone", text: $emergencyContactPhone, placeholder: "(555) 019-2834")
                        }
                    }
                    .padding(20)
                    .authPanel()

                    VStack(alignment: .leading, spacing: 16) {
                        SectionHeading(icon: "leaf.fill", title: "PRIMARY WELLNESS GOALS")
                        Text("Shapes your daily micro-journal prompt cadences and reflections.")
                            .font(.system(size: 12))
                            .foregroundStyle(Color.themeOnSurfaceVariant)

                        FlowLayout(spacing: 8) {
                            ForEach(goals, id: \.self) { goal in
                                GoalChip(title: goal, isSelected: selectedGoals.contains(goal)) {
                                    if selectedGoals.contains(goal) {
                                        selectedGoals.remove(goal)
                                    } else {
                                        selectedGoals.insert(goal)
                                    }
                                }
                            }
                        }
                    }
                    .padding(20)
                    .authPanel()
                    .padding(.top, 16)

                    VStack(alignment: .leading, spacing: 16) {
                        HStack {
                            SectionHeading(icon: "key.fill", title: "FAST 10-SECOND ENTRY PIN")
                            Spacer()
                            Text("COMING SOON")
                                .font(.system(size: 9, weight: .bold))
                                .foregroundStyle(Color.themeOnSurfaceVariant)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 5)
                                .background(Color.themeSurfaceContainerHigh, in: Capsule())
                        }
                        Text("Set a rapid 4-digit code to log spontaneous moods without signing in every time.")
                            .font(.system(size: 12))
                            .foregroundStyle(Color.themeOnSurfaceVariant)

                        HStack(spacing: 12) {
                            ForEach(0..<4, id: \.self) { _ in
                                Text("•")
                                    .font(.system(size: 25, weight: .bold))
                                    .frame(maxWidth: .infinity)
                                    .frame(height: 54)
                                    .background(Color.themeSurfaceContainerHigh, in: Circle())
                            }
                        }
                        .foregroundStyle(Color.themeOnSurfaceVariant.opacity(0.45))

                        Text("PIN and biometric unlock will be available in a future update.")
                            .font(.system(size: 11))
                            .foregroundStyle(Color.themeOnSurfaceVariant)
                    }
                    .padding(20)
                    .opacity(0.7)
                    .authPanel()
                    .padding(.top, 16)

                    if let errorMessage {
                        Text(errorMessage)
                            .font(.caption)
                            .foregroundStyle(Color.themeError)
                            .padding(.top, 14)
                    }

                    Button(action: completeOnboarding) {
                        HStack {
                            if isLoading {
                                ProgressView().tint(.white)
                            } else {
                                Text("Complete Sanctuary Setup")
                                Image(systemName: "arrow.right")
                            }
                        }
                        .font(.system(size: 15, weight: .bold))
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 17)
                        .background(Color.primaryGradient, in: Capsule())
                    }
                    .disabled(isLoading)
                    .padding(.top, 24)
                    .padding(.bottom, 30)
                }
                .padding(.horizontal, 24)
            }
        }
        .navigationBarBackButtonHidden(true)
    }

    private func completeOnboarding() {
        guard !firstName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
              !lastName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
              !emergencyContactName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
              !emergencyContactPhone.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            errorMessage = "Please complete your name and emergency contact details."
            return
        }

        isLoading = true
        errorMessage = nil

        AuthManager.shared.updatePatientProfile(
            userID: user.uid,
            firstName: firstName,
            lastName: lastName,
            birthday: birthday,
            emergencyContactName: emergencyContactName,
            emergencyContactRelationship: emergencyContactRelationship,
            emergencyContactPhone: emergencyContactPhone,
            wellnessGoals: Array(selectedGoals)
        ) { error in
            DispatchQueue.main.async {
                isLoading = false
                if let error {
                    errorMessage = error.localizedDescription
                } else {
                    session.activateSession(for: user)
                }
            }
        }
    }
}

struct TherapistVerificationView: View {
    let user: User
    let draft: SignupDraft

    @State private var clinicalTitle = "Psychologist"
    @State private var licenseNumber = ""
    @State private var issuingBoard = ""
    @State private var expirationDate = Calendar.current.date(byAdding: .year, value: 1, to: Date()) ?? Date()
    @State private var practiceName = ""
    @State private var npi = ""
    @State private var selectedSpecialties: Set<String> = ["CBT (Cognitive Behavioral)"]
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var showPending = false

    private let specialties = [
        "CBT (Cognitive Behavioral)",
        "Mindfulness-Based (MBCT)",
        "DBT (Dialectical Behavior)",
        "Psychodynamic",
        "Somatic Therapy",
        "EMDR"
    ]

    var body: some View {
        ZStack {
            AuthBackground()

            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    AuthTopBar(title: "EMOTIONAL BASELINE")
                    ProgressHeader(step: "STEP 2 OF 2 • CLINICAL PROFILE", completion: "100% Complete", progress: 1)
                        .padding(.top, 24)

                    Text("Welcome to the Boba Clinical Sanctuary")
                        .authTitle()
                        .padding(.top, 24)

                    Text("Tell us about your practice so your future clinical dashboard can feel like home.")
                        .bodyTextStyle()
                        .foregroundStyle(Color.themeOnSurfaceVariant)
                        .padding(.top, 6)
                        .padding(.bottom, 24)

                    InfoCard(
                        icon: "checkmark.seal.fill",
                        title: "PRACTITIONER PROFILE",
                        message: "Your credentials will be saved to your account. Formal verification is a future feature.",
                        badge: "Placeholder"
                    )

                    VStack(alignment: .leading, spacing: 16) {
                        SectionHeading(icon: "person.text.rectangle", title: "PROFESSIONAL CREDENTIALS")
                        AuthLabeledMenu(title: "Clinical Title & Designation", selection: $clinicalTitle, options: ["Psychologist", "Psychiatrist", "LCSW", "LMFT", "LPC", "Other"])
                        AuthLabeledField(title: "State / National License Number", icon: "number", text: $licenseNumber, placeholder: "e.g. PSY-9284102-CA")
                        AuthLabeledField(title: "Issuing Board", icon: "building.columns", text: $issuingBoard, placeholder: "e.g. California Board of Psychology")
                        DatePicker("Expiration Date", selection: $expirationDate, displayedComponents: .date)
                            .datePickerStyle(.compact)
                            .authInputBackground()
                    }
                    .padding(20)
                    .authPanel()

                    VStack(alignment: .leading, spacing: 16) {
                        SectionHeading(icon: "building.2.fill", title: "CLINICAL PRACTICE & AFFILIATION")
                        AuthLabeledField(title: "Clinic or Private Practice Name", icon: "building.2", text: $practiceName, placeholder: "e.g. Serenity Behavioral Group")
                        AuthLabeledField(title: "NPI (National Provider Identifier)", icon: "number", text: $npi, placeholder: "10-digit standard registry ID")
                        Text("Practice Specialties & Frameworks")
                            .font(.system(size: 12, weight: .medium))

                        FlowLayout(spacing: 8) {
                            ForEach(specialties, id: \.self) { specialty in
                                GoalChip(title: specialty, isSelected: selectedSpecialties.contains(specialty), selectedColor: Color.themeSecondary) {
                                    if selectedSpecialties.contains(specialty) {
                                        selectedSpecialties.remove(specialty)
                                    } else {
                                        selectedSpecialties.insert(specialty)
                                    }
                                }
                            }
                        }
                    }
                    .padding(20)
                    .authPanel()
                    .padding(.top, 16)

                    VStack(alignment: .leading, spacing: 14) {
                        HStack {
                            SectionHeading(icon: "doc.text.fill", title: "LICENSE DOCUMENT")
                            Spacer()
                            Text("COMING SOON")
                                .font(.system(size: 9, weight: .bold))
                                .foregroundStyle(Color.themeOnSurfaceVariant)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 5)
                                .background(Color.themeSurfaceContainerHigh, in: Capsule())
                        }
                        Text("Upload proof of an active clinical license")
                            .font(.system(size: 12))
                            .foregroundStyle(Color.themeOnSurfaceVariant)

                        VStack(spacing: 8) {
                            Image(systemName: "icloud.and.arrow.up")
                                .font(.system(size: 22))
                            Text("Upload Medical License / Certificate")
                                .font(.system(size: 14, weight: .medium))
                            Text("Document upload will be available in a future update.")
                                .font(.system(size: 11))
                                .multilineTextAlignment(.center)
                        }
                        .foregroundStyle(Color.themeOnSurfaceVariant.opacity(0.62))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 28)
                        .background(Color.themeSurfaceContainerLow, in: RoundedRectangle(cornerRadius: 28))
                    }
                    .padding(20)
                    .opacity(0.7)
                    .authPanel()
                    .padding(.top, 16)

                    if let errorMessage {
                        Text(errorMessage)
                            .font(.caption)
                            .foregroundStyle(Color.themeError)
                            .padding(.top, 14)
                    }

                    Button(action: submitVerification) {
                        HStack {
                            if isLoading {
                                ProgressView().tint(.white)
                            } else {
                                Text("Submit Clinical Profile")
                                Image(systemName: "arrow.right")
                            }
                        }
                        .font(.system(size: 15, weight: .bold))
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 17)
                        .background(
                            LinearGradient(colors: [Color.themePrimary, Color.themePrimaryContainer, Color.themeSecondary], startPoint: .leading, endPoint: .trailing),
                            in: Capsule()
                        )
                    }
                    .disabled(isLoading)
                    .padding(.top, 24)
                    .padding(.bottom, 30)

                }
                .padding(.horizontal, 24)
            }
        }
        .navigationBarBackButtonHidden(true)
        .navigationDestination(isPresented: $showPending) {
            PendingVerificationView(user: user)
        }
    }

    private func submitVerification() {
        guard !licenseNumber.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
              !issuingBoard.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
              !practiceName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            errorMessage = "Please complete your license and practice details."
            return
        }

        isLoading = true
        errorMessage = nil

        AuthManager.shared.updateTherapistProfile(
            userID: user.uid,
            clinicalTitle: clinicalTitle,
            licenseNumber: licenseNumber,
            issuingBoard: issuingBoard,
            licenseExpirationDate: expirationDate,
            practiceName: practiceName,
            npi: npi,
            specialties: Array(selectedSpecialties)
        ) { error in
            DispatchQueue.main.async {
                isLoading = false
                if let error {
                    errorMessage = error.localizedDescription
                } else {
                    showPending = true
                }
            }
        }
    }
}

struct PendingVerificationView: View {
    @EnvironmentObject private var session: SessionManager
    let user: User

    @State private var pulse = false

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [Color.themeSecondaryContainer, Color.themeTertiaryContainer, Color.themePrimaryContainer],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            VStack(spacing: 22) {
                Text("TOTALLY REAL\nVERIFICATION DEPARTMENT")
                    .font(.system(size: 13, weight: .black, design: .rounded))
                    .tracking(1.5)
                    .multilineTextAlignment(.center)
                    .foregroundStyle(Color.themeSecondary)

                ZStack {
                    Circle()
                        .stroke(Color.white.opacity(0.7), lineWidth: 14)
                        .frame(width: 190, height: 190)
                        .rotationEffect(.degrees(pulse ? 360 : 0))
                        .animation(.linear(duration: 4).repeatForever(autoreverses: false), value: pulse)

                    VStack(spacing: 4) {
                        Text("99.9%")
                            .font(.system(size: 42, weight: .black, design: .rounded))
                        Text("probably verified")
                            .font(.system(size: 12, weight: .bold))
                    }
                    .foregroundStyle(Color.themePrimary)
                }

                Text("Your clinical sanctuary is\nbeing ceremonially prepared.")
                    .font(.system(size: 24, weight: .bold, design: .rounded))
                    .multilineTextAlignment(.center)
                    .foregroundStyle(Color.themeOnSurface)

                Text("This placeholder is loud on purpose. There is no actual approval queue yet—future therapists will go straight to their dashboard.")
                    .font(.system(size: 14))
                    .multilineTextAlignment(.center)
                    .foregroundStyle(Color.themeOnSurfaceVariant)
                    .padding(.horizontal, 16)

                Button {
                    session.activateSession(for: user)
                } label: {
                    HStack {
                        Text("Skip the Imaginary Queue")
                        Image(systemName: "sparkles")
                    }
                    .font(.system(size: 15, weight: .bold))
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 17)
                    .background(Color.themeSecondary, in: Capsule())
                }
                .padding(.top, 8)
            }
            .padding(28)
            .background(.white.opacity(0.76), in: RoundedRectangle(cornerRadius: 36))
            .padding(24)
        }
        .navigationBarBackButtonHidden(true)
        .onAppear { pulse = true }
    }
}

private struct ConsentRow<Content: View>: View {
    @Binding var isSelected: Bool
    @ViewBuilder let content: () -> Content

    var body: some View {
        Button {
            isSelected.toggle()
        } label: {
            HStack(alignment: .top, spacing: 10) {
                Image(systemName: isSelected ? "checkmark.square.fill" : "square")
                    .foregroundStyle(isSelected ? Color.themePrimary : Color.themeOnSurfaceVariant)
                content()
                    .font(.system(size: 12))
                    .foregroundStyle(Color.themeOnSurfaceVariant)
                    .multilineTextAlignment(.leading)
                Spacer(minLength: 0)
            }
        }
        .buttonStyle(.plain)
    }
}

private struct SmallTag: View {
    let text: String

    var body: some View {
        Text(text)
            .font(.system(size: 10))
            .foregroundStyle(Color.themeOnSurfaceVariant)
            .padding(.horizontal, 8)
            .padding(.vertical, 5)
            .background(.white.opacity(0.75), in: Capsule())
    }
}

private struct GoalChip: View {
    let title: String
    let isSelected: Bool
    var selectedColor: Color = .themePrimary
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 5) {
                if isSelected {
                    Image(systemName: "checkmark")
                        .font(.system(size: 9, weight: .bold))
                }
                Text(title)
            }
            .font(.system(size: 11, weight: isSelected ? .medium : .regular))
            .foregroundStyle(isSelected ? .white : Color.themeOnSurfaceVariant)
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(isSelected ? selectedColor : Color.themeSurfaceContainerHigh, in: Capsule())
        }
        .buttonStyle(.plain)
    }
}

private struct AuthLabeledField: View {
    let title: String
    let icon: String
    @Binding var text: String
    let placeholder: String

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.system(size: 12, weight: .medium))
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 13))
                    .foregroundStyle(Color.themeOnSurfaceVariant)
                TextField(placeholder, text: $text)
                    .font(.system(size: 13))
            }
            .authFieldStyle()
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

private struct AuthLabeledMenu: View {
    let title: String
    @Binding var selection: String
    let options: [String]

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.system(size: 12, weight: .medium))
            Menu {
                ForEach(options, id: \.self) { option in
                    Button(option) { selection = option }
                }
            } label: {
                HStack {
                    Text(selection)
                    Spacer()
                    Image(systemName: "chevron.down")
                }
                .font(.system(size: 13))
                .foregroundStyle(Color.themeOnSurface)
                .authFieldStyle()
            }
        }
    }
}

struct AuthFieldLabel: View {
    let icon: String
    let title: String

    var body: some View {
        Label(title, systemImage: icon)
            .font(.system(size: 12, weight: .medium))
            .foregroundStyle(Color.themeOnSurfaceVariant)
    }
}

struct AuthTopBar: View {
    let title: String

    var body: some View {
        HStack {
            HStack(spacing: 7) {
                Circle()
                    .fill(Color.themePrimaryContainer)
                    .frame(width: 10, height: 10)
                Text("boba")
                    .font(.system(size: 16, weight: .medium, design: .rounded))
            }

            Spacer()

            Text(title)
                .font(.system(size: 12, weight: .medium))
                .tracking(1.5)
                .foregroundStyle(Color.themeOnSurfaceVariant)
        }
        .foregroundStyle(Color.themeOnSurface)
        .padding(.top, 14)
    }
}

private struct BackButton: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        Button {
            dismiss()
        } label: {
            Image(systemName: "chevron.left")
                .foregroundStyle(Color.themePrimary)
        }
        .accessibilityLabel("Back")
    }
}

struct BobaMark: View {
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 20)
                .fill(.white.opacity(0.85))
                .frame(width: 80, height: 80)
                .shadow(color: Color.themePrimary.opacity(0.14), radius: 14, y: 8)

            VStack(spacing: 0) {
                Capsule()
                    .fill(Color.themeTertiary)
                    .frame(width: 5, height: 24)
                    .rotationEffect(.degrees(20))
                    .offset(x: 8, y: 7)
                ZStack {
                    RoundedRectangle(cornerRadius: 5)
                        .fill(Color.themeSecondary.opacity(0.65))
                        .frame(width: 24, height: 28)
                    HStack(spacing: 3) {
                        Circle().frame(width: 4, height: 4)
                        Circle().frame(width: 4, height: 4)
                        Circle().frame(width: 4, height: 4)
                    }
                    .foregroundStyle(Color.themeOnSurface)
                    .offset(y: 6)
                }
            }
        }
    }
}

struct AuthBackground: View {
    var body: some View {
        ZStack {
            Color.themeBackground
                .ignoresSafeArea()

            Circle()
                .fill(Color.themePrimaryContainer.opacity(0.62))
                .frame(width: 290, height: 290)
                .blur(radius: 30)
                .offset(x: -145, y: -285)

            Circle()
                .fill(Color.themeSecondaryContainer.opacity(0.55))
                .frame(width: 300, height: 300)
                .blur(radius: 34)
                .offset(x: 155, y: -30)

            Circle()
                .fill(Color.themeTertiaryContainer.opacity(0.28))
                .frame(width: 220, height: 220)
                .blur(radius: 30)
                .offset(x: 80, y: 350)
        }
    }
}

private struct ProgressHeader: View {
    let step: String
    let completion: String
    let progress: CGFloat

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(step)
                    .font(.system(size: 12, weight: .bold))
                    .tracking(1.2)
                    .foregroundStyle(Color.themePrimary)
                Spacer()
                Text(completion)
                    .font(.system(size: 12))
                    .foregroundStyle(Color.themeOnSurfaceVariant)
            }
            GeometryReader { proxy in
                Capsule()
                    .fill(Color.themeSurfaceContainerHigh)
                    .overlay(alignment: .leading) {
                        Capsule()
                            .fill(Color.primaryGradient)
                            .frame(width: proxy.size.width * progress)
                    }
            }
            .frame(height: 6)
        }
    }
}

private struct InfoCard: View {
    let icon: String
    let title: String
    let message: String
    var badge: String? = nil

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 15, weight: .bold))
                .foregroundStyle(Color.themeTertiary)
                .frame(width: 38, height: 38)
                .background(Color.themeTertiaryContainer.opacity(0.36), in: Circle())

            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(title)
                        .font(.system(size: 13, weight: .bold))
                    if let badge {
                        Spacer()
                        Text(badge)
                            .font(.system(size: 10, weight: .semibold))
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color.themeTertiaryContainer, in: Capsule())
                    }
                }
                Text(message)
                    .font(.system(size: 12))
                    .foregroundStyle(Color.themeOnSurfaceVariant)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(16)
        .background(Color.themeTertiaryContainer.opacity(0.25), in: RoundedRectangle(cornerRadius: 28))
    }
}

private struct SectionHeading: View {
    let icon: String
    let title: String

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: icon)
                .font(.system(size: 14, weight: .bold))
                .foregroundStyle(Color.themePrimary)
                .frame(width: 32, height: 32)
                .background(Color.themePrimaryContainer.opacity(0.35), in: Circle())
            Text(title)
                .font(.system(size: 14, weight: .bold))
                .tracking(0.3)
                .foregroundStyle(Color.themeOnSurface)
        }
    }
}

private struct FlowLayout: Layout {
    var spacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let maxWidth = proposal.width ?? .infinity
        var lineWidth: CGFloat = 0
        var lineHeight: CGFloat = 0
        var totalHeight: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if lineWidth > 0 && lineWidth + spacing + size.width > maxWidth {
                totalHeight += lineHeight + spacing
                lineWidth = 0
                lineHeight = 0
            }
            lineWidth += (lineWidth == 0 ? 0 : spacing) + size.width
            lineHeight = max(lineHeight, size.height)
        }

        return CGSize(width: maxWidth, height: totalHeight + lineHeight)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        var x = bounds.minX
        var y = bounds.minY
        var lineHeight: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if x > bounds.minX && x + size.width > bounds.maxX {
                x = bounds.minX
                y += lineHeight + spacing
                lineHeight = 0
            }
            subview.place(at: CGPoint(x: x, y: y), anchor: .topLeading, proposal: ProposedViewSize(size))
            x += size.width + spacing
            lineHeight = max(lineHeight, size.height)
        }
    }
}

extension View {
    func authTitle() -> some View {
        font(.system(size: 26, weight: .bold, design: .rounded))
            .foregroundStyle(Color.themeOnSurface)
    }

    func authFieldStyle() -> some View {
        padding(.horizontal, 14)
            .frame(minHeight: 46)
            .background(Color.themeSurfaceContainerHigh.opacity(0.85), in: Capsule())
    }

    func authInputBackground() -> some View {
        padding(.horizontal, 14)
            .frame(minHeight: 46)
            .background(Color.themeSurfaceContainerHigh.opacity(0.85), in: Capsule())
    }

    func authPanel() -> some View {
        background(.white.opacity(0.78), in: RoundedRectangle(cornerRadius: 30))
            .overlay {
                RoundedRectangle(cornerRadius: 30)
                    .stroke(.white.opacity(0.7), lineWidth: 1)
            }
            .shadow(color: Color.themeOnSurface.opacity(0.08), radius: 18, y: 10)
    }
}
