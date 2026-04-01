import SwiftUI
import FirebaseFirestore

struct DailyLogView: View {
    @State private var selectedMood: String = ""
    //@State private var selectedTags: Set<String> = [] // Set avoids duplicates
    @State private var journalText: String = ""
    //@State private var hydrationLevel: Double = 1.2
    //@State private var sleepHours: Double = 7.5
    @State private var isSubmitting: Bool = false
    
    var body: some View {
        ZStack {
            Color.themeSurface.ignoresSafeArea()
            
            // liquid bg
            Circle()
                .fill(Color.themeTertiaryContainer.opacity(0.1))
                .frame(width: 300, height: 300)
                .blur(radius: 80)
                .position(x: 50, y: 800)
            
            VStack(spacing: 0) {
                TopAppBar()
                
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 40) {
                        moodSelectorSection
                        emotionTagsSection
                        trackersSection
                        noteSection
                        
                        Button(action: {
                            submitLog()
                        }) {
                            Text("Submit Daily Log")
                                .headlineText(size: 18, weight: .heavy)
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 20)
                                .background(Color.primaryGradient)
                                .clipShape(Capsule())
                                .shadow(color: .themePrimary.opacity(0.2), radius: 20, x: 0, y: 10)
                        }.disabled(isSubmitting)
                        
                        Spacer().frame(height: 120)
                    }
                    .padding(.horizontal, 24)
                    .padding(.top, 24)
                }
            }
        }
    }
    
    var moodSelectorSection: some View {
        VStack(alignment: .leading, spacing: 24) {
            VStack(alignment: .leading, spacing: 4) {
                Text("How are you feeling?")
                    .headlineText(size: 28, weight: .heavy)
                Text("Tap the mood that resonates most.")
                    .bodyText(size: 18)
                    .foregroundColor(.themeOnSurfaceVariant)
            }
            
            HStack(spacing: 0) {
                moodEmoji(icon: "face.smiling", label: "AWFUL", color: .themeError.opacity(0.6))
                Spacer()
                moodEmoji(icon: "face.dashed", label: "BAD", color: .themePrimary.opacity(0.4))
                Spacer()
                
                VStack(spacing: 8) {
                    Circle()
                        .fill(Color.primaryGradient)
                        .frame(width: 64, height: 64)
                        .overlay(Image(systemName: "face.smiling.fill").font(.system(size: 32)).foregroundColor(.white))
                        .shadow(radius: 10)
                    Text("OKAY")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(.themePrimary)
                        .tracking(1)
                }
                .scaleEffect(1.1)
                
                Spacer()
                moodEmoji(icon: "face.smiling", label: "GOOD", color: .themeTertiary.opacity(0.4))
                Spacer()
                moodEmoji(icon: "star.fill", label: "GREAT", color: .themeTertiaryContainer)
            }
            .padding(24)
            .background(Color.white.opacity(0.4))
            .glassCard()
            .overlay(RoundedRectangle(cornerRadius: 24).stroke(Color.white.opacity(0.2), lineWidth: 1))
        }
    }
    
    func moodEmoji(icon: String, label: String, color: Color) -> some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 32))
                .foregroundColor(color)
            Text(label)
                .font(.system(size: 10, weight: .medium))
                .foregroundColor(.black.opacity(0.6))
                .tracking(1)
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
                trackerCard(icon: "drop.fill", iconColor: .themeTertiaryContainer, value: "1.2", unit: "L", title: "HYDRATION", progress: 0.6, progressGradient: LinearGradient(colors: [.themeTertiaryContainer, .themeTertiary], startPoint: .leading, endPoint: .trailing))
                
                trackerCard(icon: "moon.fill", iconColor: .themeSecondary, value: "7.5", unit: "hrs", title: "SLEEP QUALITY", progress: 0.85, progressGradient: LinearGradient(colors: [.themeSecondaryContainer, .themeSecondary], startPoint: .leading, endPoint: .trailing))
            }
        }
    }
    
    func trackerCard(icon: String, iconColor: Color, value: String, unit: String, title: String, progress: Double, progressGradient: LinearGradient) -> some View {
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
        .overlay(RoundedRectangle(cornerRadius: 24).stroke(Color.white.opacity(0.3), lineWidth: 1))
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

extension DailyLogView {
    func submitLog() {
        // Prevent double-submissions
        guard !isSubmitting else { return }
        isSubmitting = true
        
        let newLog = DailyLog(
            date: Date(),
            mood: selectedMood,
            //tags: Array(selectedTags), // Convert Set back to Array for Firebase
            //hydration: hydrationLevel,
            //sleep: sleepHours,
            notes: journalText
        )
        
        // 2. Reference your Firestore database
        let db = Firestore.firestore()
        
        // 3. Push to a collection named "daily_logs"
        do {
            try db.collection("logs").addDocument(from: newLog) { error in
                isSubmitting = false
                if let error = error {
                    print("Error saving log: \(error.localizedDescription)")
                    // Handle error (e.g., show an alert)
                } else {
                    print("Successfully saved daily log!")
                    // Handle success (e.g., clear the form or dismiss the view)
                }
            }
        } catch {
            print("Error encoding log: \(error)")
            isSubmitting = false
        }
    }
}

