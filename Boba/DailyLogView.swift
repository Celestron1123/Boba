import SwiftUI
import FirebaseFirestore

struct DailyLogView: View {
    @State private var selectedMood: String = ""
    //@State private var selectedTags: Set<String> = [] // Set avoids duplicates
    @State private var journalText: String = ""
    //@State private var hydrationLevel: Double = 1.2
    //@State private var sleepHours: Double = 7.5
    @State private var isSubmitting: Bool = false
    
    private let moodOptions: [MoodOption] = [
        .init(key: "AWFUL", icon: "face.terrible", color: .moodTerrible),
        .init(key: "BAD", icon: "face.sad", color: .moodBad),
        .init(key: "OKAY", icon: "face.okay", color: .moodOkay),
        .init(key: "GOOD", icon: "face.good", color: .moodGood),
        .init(key: "GREAT", icon: "face.great", color: .moodGreat)
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
                        Text(isSubmitting ? "SUBMITTING..." : "SUBMIT DAILY LOG")
                            .headlineText(size: 18, weight: .heavy)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 20)
                            .background(Color.primaryGradient)
                            .clipShape(Capsule())
                            .shadow(color: .themePrimary.opacity(0.2), radius: 20, x: 0, y: 10)
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
                        withAnimation(.spring(response: 0.25, dampingFraction: 0.85)) {
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
                ("Grateful", Color.themeOnSecondaryContainer, Color.themeSecondaryContainer),
                ("Anxious", Color.themeOnSurfaceVariant, Color.themeSurfaceContainerHighest),
                ("Energetic", Color.themeOnSurfaceVariant, Color.themeSurfaceContainerHighest),
                ("Frustrated", Color.themeOnErrorContainer, Color.themeErrorContainer),
                ("Lonely", Color.themeOnSurfaceVariant, Color.themeSurfaceContainerHighest),
                ("Inspired", Color.themeOnPrimaryContainer, Color.themePrimaryContainer),
                ("Tired", Color.themeOnSurfaceVariant, Color.themeSurfaceContainerHighest)
            ]
            
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 100))], spacing: 12) {
                ForEach(tags, id: \.0) { tag in
                    Text(tag.0)
                        .bodyText(size: 14, weight: .medium)
                        .foregroundColor(tag.1)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 10)
                        .background(tag.2)
                        .clipShape(Capsule())
                }
            }
        }
    }
    
    var trackersSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Wellness Trackers")
                .headlineText(size: 20, weight: .bold)
            
            HStack(spacing: 16) {
                trackerCard(
                    icon: "drop.fill",
                    iconColor: .themeTertiaryContainer,
                    value: "1.2",
                    unit: "L",
                    title: "HYDRATION",
                    progress: 0.6,
                    progressGradient: LinearGradient(
                        colors: [.themeTertiaryContainer, .themeTertiary],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                
                trackerCard(
                    icon: "moon.fill",
                    iconColor: .themeSecondary,
                    value: "7.5",
                    unit: "hrs",
                    title: "SLEEP QUALITY",
                    progress: 0.85,
                    progressGradient: LinearGradient(
                        colors: [.themeSecondaryContainer, .themeSecondary],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
            }
        }
    }
    
    func trackerCard(
        icon: String,
        iconColor: Color,
        value: String,
        unit: String,
        title: String,
        progress: Double,
        progressGradient: LinearGradient
    ) -> some View {
        VStack(alignment: .leading) {
            HStack(alignment: .top) {
                Image(systemName: icon)
                    .font(.system(size: 24))
                    .foregroundColor(iconColor)
                
                Spacer()
                
                HStack(spacing: 0) {
                    Text(value)
                        .font(.system(size: 24, weight: .bold))
                    Text(unit)
                        .font(.system(size: 14))
                        .foregroundColor(.themeOnSurfaceVariant.opacity(0.6))
                }
            }
            
            Spacer()
            
            VStack(spacing: 8) {
                HStack {
                    Text(title)
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(.themeOnSurfaceVariant.opacity(0.8))
                    Spacer()
                    Text("\(Int(progress * 100))%")
                }
                .font(.system(size: 10, weight: .bold))
                .tracking(1)
                .foregroundColor(.themeOnSurfaceVariant.opacity(0.8))
                
                GeometryReader { geo in
                    Capsule()
                        .fill(Color.themeSurfaceContainer)
                        .frame(height: 12)
                        .overlay(
                            Capsule()
                                .fill(progressGradient)
                                .frame(width: geo.size.width * CGFloat(progress)),
                            alignment: .leading
                        )
                }
                .frame(height: 12)
            }
        }
        .padding(20)
        .frame(height: 160)
        .glassCard()
        .overlay(
            RoundedRectangle(cornerRadius: DS.Radius.lg)
                .stroke(Color.white.opacity(0.3), lineWidth: 1)
        )
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
                            .stroke(isSelected ? Color.themePrimary : Color.clear, lineWidth: 2)
                    )
                    .shadow(
                        color: isSelected ? Color.themePrimary.opacity(0.20) : .clear,
                        radius: 10,
                        x: 0,
                        y: 4
                    )
                
                Text(mood.key)
                    .font(.system(size: 11, weight: .bold))
                    .foregroundColor(isSelected ? .themeOnSurface : .themeOnSurfaceVariant)
                    .tracking(1)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }
            .frame(maxWidth: .infinity, minHeight: 100)
            .padding(.vertical, 8)
            .background(
                RoundedRectangle(cornerRadius: DS.Radius.md)
                    .fill(isSelected ? mood.color.opacity(0.25) : Color.themeSurfaceContainerLow.opacity(0.55))
            )
            .overlay(
                RoundedRectangle(cornerRadius: DS.Radius.md)
                    .stroke(
                        isSelected ? Color.themePrimary.opacity(0.45) : Color.white.opacity(0.35),
                        lineWidth: isSelected ? 1.5 : 1
                    )
            )
            .scaleEffect(isSelected ? 1.02 : 1.0)
            .animation(.spring(response: 0.25, dampingFraction: 0.85), value: isSelected)
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Mood \(mood.key)")
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}

extension DailyLogView {
    func submitLog() {
        // Prevent double-submissions
        guard !isSubmitting else { return }
        isSubmitting = true
        
        let newLog = DailyLog(
            date: Date(),
            mood: selectedMood,
            //tags: Array(selectedTags),
            //hydration: hydrationLevel,
            //sleep: sleepHours,
            notes: journalText
        )
        
        let db = Firestore.firestore()
        
        do {
            try db.collection("logs").addDocument(from: newLog) { error in
                isSubmitting = false
                if let error = error {
                    print("Error saving log: \(error.localizedDescription)")
                } else {
                    print("Successfully saved daily log!")
                }
            }
        } catch {
            print("Error encoding log: \(error)")
            isSubmitting = false
        }
    }
}

