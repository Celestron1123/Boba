/**
 * DailyLogView.swift
 *
 * Overview: Provides the daily wellness check-in where a patient records a
 * current mood and optional journal details.
 *
 * Contains:
 * - Mood selection and supporting wellness tracker state.
 * - Journal-note entry and submission controls.
 * - Firestore persistence for the submitted DailyLog record.
 *
 * Date: September 10, 2026
 * Attribution: BOBA t team
 * Copyright: Copyright © 2026 BOBA t. All rights reserved.
 */

import FirebaseAuth
import FirebaseFirestore
import SwiftUI

struct DailyLogView: View {
    @Environment(\.dismiss) private var dismiss

    @State private var selectedMood: String = ""
    @State private var selectedTags: Set<String> = []
    @State private var journalText: String = ""
    @State private var isSubmitting: Bool = false
    @State private var isShowingGoalCreation: Bool = false
    @State private var customGoals: [GoalCreation] = []

    @EnvironmentObject var session: SessionManager
    @State private var isLoadingGoals: Bool = false

    private let moodOptions: [MoodOption] = [
        .init(key: "AWFUL", icon: "face.terrible", color: .moodTerrible),
        .init(key: "BAD", icon: "face.sad", color: .moodBad),
        .init(key: "OKAY", icon: "face.okay", color: .moodOkay),
        .init(key: "GOOD", icon: "face.good", color: .moodGood),
        .init(key: "GREAT", icon: "face.great", color: .moodGreat),
    ]

    private var moodColumns: [GridItem] {
        [GridItem(.adaptive(minimum: 92, maximum: 140), spacing: 12)]
    }

    var body: some View {
        ZStack {
            Color.themeSurface.ignoresSafeArea()

            Circle()
                .fill(Color.themeTertiaryContainer.opacity(0.1))
                .frame(width: 300, height: 300)
                .blur(radius: 80)
                .position(x: 50, y: 800)

            ScrollView(showsIndicators: false) {
                VStack(spacing: 40) {
                    moodSelectorSection
                    emotionTagsSection
                    trackersSection
                    noteSection

                    Button(action: { submitLog() }) {
                        Text(
                            isSubmitting ? "SUBMITTING..." : "SUBMIT DAILY LOG"
                        )
                        .headlineText(size: 18, weight: .heavy)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 20)
                        .background(Color.primaryGradient)
                        .clipShape(Capsule())
                        .shadow(
                            color: .themePrimary.opacity(0.2),
                            radius: 20,
                            x: 0,
                            y: 10
                        )
                    }
                    .disabled(isSubmitting)

                    Spacer().frame(height: 120)
                }
                .padding(.horizontal, 24)
                .padding(.top, 24)
            }
        }
    }

    var moodSelectorSection: some View {
        VStack(alignment: .leading, spacing: 20) {
            VStack(alignment: .leading, spacing: 4) {
                Text("How are you feeling?")
                    .headlineText(size: 28, weight: .heavy)
                Text("Tap the mood that resonates most.")
                    .bodyText(size: 18)
                    .foregroundColor(.themeOnSurfaceVariant)
            }

            LazyVGrid(columns: moodColumns, spacing: 12) {
                ForEach(moodOptions) { mood in
                    MoodCard(
                        mood: mood,
                        isSelected: selectedMood == mood.key
                    ) {
                        withAnimation(
                            .spring(response: 0.25, dampingFraction: 0.85)
                        ) {
                            selectedMood = mood.key
                        }
                    }
                }
            }
            .padding(16)
            .background(Color.white.opacity(0.35))
            .glassCard()
            .overlay(
                RoundedRectangle(cornerRadius: DS.Radius.lg)
                    .stroke(Color.white.opacity(0.2), lineWidth: 1)
            )
        }
    }

    var emotionTagsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(spacing: 8) {
                Text("Identify Emotions")
                    .headlineText(size: 20, weight: .bold)
                Text("(Select all that apply)")
                    .bodyText(size: 14)
                    .foregroundColor(.themeOnSurfaceVariant)
            }

            let tags = [
                ("Calm", Color.themeTertiary, Color.themeTertiary.opacity(0.1)),
                (
                    "Grateful", Color.themeOnSecondaryContainer,
                    Color.themeSecondaryContainer
                ),
                (
                    "Anxious", Color.themeOnSurfaceVariant,
                    Color.themeSurfaceContainerHighest
                ),
                (
                    "Energetic", Color.themeOnSurfaceVariant,
                    Color.themeSurfaceContainerHighest
                ),
                (
                    "Frustrated", Color.themeOnErrorContainer,
                    Color.themeErrorContainer
                ),
                (
                    "Lonely", Color.themeOnSurfaceVariant,
                    Color.themeSurfaceContainerHighest
                ),
                (
                    "Inspired", Color.themeOnPrimaryContainer,
                    Color.themePrimaryContainer
                ),
                (
                    "Tired", Color.themeOnSurfaceVariant,
                    Color.themeSurfaceContainerHighest
                ),
            ]

            LazyVGrid(columns: [GridItem(.adaptive(minimum: 100))], spacing: 12)
            {
                ForEach(tags, id: \.0) { tag in
                    let isSelected = selectedTags.contains(tag.0)

                    Button(action: {
                        toggleTag(tag.0)
                    }) {
                        Text(tag.0)
                            .bodyText(
                                size: 14,
                                weight: isSelected ? .bold : .medium
                            )
                            .foregroundColor(isSelected ? .white : tag.1)
                            .padding(.horizontal, 20)
                            .padding(.vertical, 10)
                            .background(
                                isSelected ? Color.themePrimary : tag.2
                            )
                            .clipShape(Capsule())
                            .overlay(
                                Capsule()
                                    .stroke(
                                        isSelected
                                            ? Color.themePrimary : Color.clear,
                                        lineWidth: 1.5
                                    )
                            )
                            .scaleEffect(isSelected ? 1.05 : 1.0)
                    }
                    .buttonStyle(.plain)
                    .animation(
                        .spring(response: 0.2, dampingFraction: 0.7),
                        value: isSelected
                    )
                }
            }
        }
    }

    var trackersSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(alignment: .center) {
                Text("Wellness Trackers")
                    .headlineText(size: 20, weight: .bold)

                Spacer()

                Button(action: { isShowingGoalCreation = true }) {
                    Label("Add Goal", systemImage: "plus")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(.themePrimary)
                }
            }

            ForEach($customGoals) { $goal in
                VStack {
                    HStack {
                        Image(systemName: goal.systemImage)
                            .foregroundColor(.themePrimary)
                        Text(goal.title)
                        Spacer()

                        // Dynamic input field for this goal
                        TextField(
                            "0",
                            value: $goal.targetValue,
                            format: .number
                        )
                        .keyboardType(.decimalPad)
                        .multilineTextAlignment(.trailing)
                        .frame(width: 60)
                        Text(goal.unit)
                            .foregroundColor(.themeOnSurfaceVariant)
                    }
                    .padding()
                    .glassCard()
                }
            }
        }
    }

    var noteSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Journaling thoughts")
                .headlineText(size: 20, weight: .bold)

            ZStack(alignment: .bottomTrailing) {
                TextEditor(text: $journalText)
                    .font(.system(size: 16))
                    .scrollContentBackground(.hidden)
                    .padding(24)
                    .frame(height: 160)
                    .background(Color.white.opacity(0.4))
                    .glassCard()

                Text("SAFE SPACE")
                    .font(.system(size: 10, weight: .bold))
                    .tracking(1)
                    .foregroundColor(.themeOnSurfaceVariant.opacity(0.4))
                    .padding(16)
            }
            .onAppear {
                fetchPersistedGoals()
            }
        }
        .sheet(isPresented: $isShowingGoalCreation) {
            GoalCreationView { createdGoal in
                customGoals.append(createdGoal)
                saveGoalToUserProfile(createdGoal)
            }
        }
    }
}

private struct MoodOption: Identifiable {
    let id = UUID()
    let key: String
    let icon: String
    let color: Color
}

private struct MoodCard: View {
    let mood: MoodOption
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 10) {
                Circle()
                    .fill(mood.color.opacity(isSelected ? 1.0 : 0.75))
                    .frame(width: 58, height: 58)
                    .overlay(
                        Image(mood.icon)
                            .resizable()
                            .scaledToFit()
                            .frame(width: 28, height: 28)
                            .foregroundColor(.themeOnSurfaceVariant)
                    )
                    .overlay(
                        Circle()
                            .stroke(
                                isSelected ? Color.themePrimary : Color.clear,
                                lineWidth: 2
                            )
                    )
                    .shadow(
                        color: isSelected
                            ? Color.themePrimary.opacity(0.20) : .clear,
                        radius: 10,
                        x: 0,
                        y: 4
                    )

                Text(mood.key)
                    .font(.system(size: 11, weight: .bold))
                    .foregroundColor(
                        isSelected ? .themeOnSurface : .themeOnSurfaceVariant
                    )
                    .tracking(1)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }
            .frame(maxWidth: .infinity, minHeight: 100)
            .padding(.vertical, 8)
            .background(
                RoundedRectangle(cornerRadius: DS.Radius.md)
                    .fill(
                        isSelected
                            ? mood.color.opacity(0.25)
                            : Color.themeSurfaceContainerLow.opacity(0.55)
                    )
            )
            .overlay(
                RoundedRectangle(cornerRadius: DS.Radius.md)
                    .stroke(
                        isSelected
                            ? Color.themePrimary.opacity(0.45)
                            : Color.white.opacity(0.35),
                        lineWidth: isSelected ? 1.5 : 1
                    )
            )
            .scaleEffect(isSelected ? 1.02 : 1.0)
            .animation(
                .spring(response: 0.25, dampingFraction: 0.85),
                value: isSelected
            )
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Mood \(mood.key)")
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }

}

extension DailyLogView {
    /// Fetches the user's saved goal templates from their user document
    func fetchPersistedGoals() {
        guard let userId = session.currentUserId else { return }
        isLoadingGoals = true

        let db = Firestore.firestore()
        db.collection("users").document(userId).getDocument { snapshot, error in
            isLoadingGoals = false
            guard let snapshot = snapshot, snapshot.exists,
                let data = snapshot.data(),
                let rawGoals = data["persistedGoals"] as? [[String: Any]]
            else {
                return
            }

            do {
                let jsonData = try JSONSerialization.data(
                    withJSONObject: rawGoals
                )
                let decodedGoals = try JSONDecoder().decode(
                    [GoalCreation].self,
                    from: jsonData
                )
                DispatchQueue.main.async {
                    self.customGoals = decodedGoals
                }
            } catch {
                print("Error decoding saved goals: \(error)")
            }
        }
    }

    /// Saves newly added goals to the user's profile document so they persist for future logs
    func saveGoalToUserProfile(_ newGoal: GoalCreation) {
        guard let userId = session.currentUserId else { return }

        let db = Firestore.firestore()

        do {
            let data = try JSONEncoder().encode(newGoal)
            if let dict = try JSONSerialization.jsonObject(with: data)
                as? [String: Any]
            {
                db.collection("users").document(userId).setData(
                    [
                        "persistedGoals": FieldValue.arrayUnion([dict])
                    ],
                    merge: true
                ) { error in
                    if let error = error {
                        print("Failed to persist goal profile: \(error)")
                    }
                }
            }
        } catch {
            print("Error encoding goal for persistence: \(error)")
        }
    }

    func submitLog() {
        guard let userId = session.currentUserId else {
            print("No manual session found")
            return
        }

        // Prevent double-submissions
        guard !isSubmitting else { return }
        isSubmitting = true

        let newLog = DailyLog(
            date: Date(),
            mood: selectedMood,
            tags: Array(selectedTags),
            goals: customGoals,
            notes: journalText
        )

        let db = Firestore.firestore()

        do {
            try db.collection("users").document(userId).collection("logs")
                .addDocument(from: newLog) { error in
                    isSubmitting = false
                    if let error = error {
                        print("Error: \(error.localizedDescription)")
                    } else {
                        print("Successfully saved to sub-collection!")
                        dismiss()
                    }
                }
        } catch {
            print("Error encoding log: \(error)")
            isSubmitting = false
        }
    }

    fileprivate func toggleTag(_ tag: String) {
        if selectedTags.contains(tag) {
            selectedTags.remove(tag)
        } else {
            selectedTags.insert(tag)
        }
    }
}
