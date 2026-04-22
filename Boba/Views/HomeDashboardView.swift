import SwiftUI

struct HomeDashboardView: View {

    @State private var showDailyLog = false

    var body: some View {
        ZStack {
            // Liquid background
            LinearGradient(
                colors: [.themeSurface, .themePrimaryContainer.opacity(0.2), .themeSecondaryContainer.opacity(0.2)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            ).ignoresSafeArea()
            
            VStack(spacing: 0) {
                TopAppBar()
                
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 32) {
                        heroSection
                        dailyLogCard
                        
                        // To achieve a side by side in wider screens, we can use an HStack or LazyVGrid. Based on prompt Grid of 1 or 2.
                        VStack(spacing: 24) {
                            upcomingAppointmentCard
                            medicationRemindersCard
                        }
                        
                        breathingExerciseCard
                        
                        Spacer().frame(height: 120)
                    }
                    .padding(.horizontal, 24)
                    .padding(.top, 24)
                }
            }
            
        }
        .sheet(isPresented: $showDailyLog) {
            DailyLogView()
        }
    }
    
    var heroSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("How are you feeling today?")
                .bodyText(size: 18, weight: .medium)
                .foregroundColor(.themeOnSurfaceVariant)
            
            VStack(alignment: .leading, spacing: 0) {
                Text("Your mind deserves serenity.")
                    .headlineText(size: 36, weight: .heavy)
            }
            .onAppear {
                // Color is applied per-character by AttributedString in production
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
    
    var dailyLogCard: some View {
        VStack(spacing: 24) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Daily Log")
                        .headlineText(size: 20, weight: .bold)
                        .foregroundColor(.themeOnSurface)
                    Text("Capture your current mood")
                        .bodyText(size: 14)
                        .foregroundColor(.themeOnSurfaceVariant)
                }
                Spacer()
                Circle()
                    .fill(Color.themeTertiaryContainer.opacity(0.3))
                    .frame(width: 40, height: 40)
                    .overlay(Image(systemName: "square.and.pencil").foregroundColor(.themeTertiary))
            }
            
            HStack(spacing: 0) {
                moodButton(icon: "face.terrible", label: "Awful", isCustom: true, color: .moodTerrible)
                Spacer()
                moodButton(icon: "face.sad", label: "Bad", isCustom: true, color: .moodBad)
                Spacer()
                moodButton(icon: "face.okay", label: "Okay", isCustom: true, color: .moodOkay)
                Spacer()
                moodButton(icon: "face.good", label: "Good", isCustom: true, color: .moodGood)
                Spacer()
                moodButton(icon: "face.great", label: "Great", isCustom: true, color: .moodGreat)
            }
            
            Button("Check in Now") { showDailyLog = true }
                .headlineText(size: 16, weight: .bold)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(Color.primaryGradient)
                .clipShape(Capsule())
                .shadow(color: .themePrimary.opacity(0.2), radius: 10, x: 0, y: 5)
        }
        .padding(32)
        .glassCard()
    }
    
    func moodButton(icon: String, label: String, isCustom: Bool = false, color: Color) -> some View {
        VStack(spacing: 8) {
            Circle()
                .fill(color)
                .frame(width: 56, height: 56)
                .overlay(
                    // Dynamically choose the correct Image initializer
                    (isCustom ? Image(icon) : Image(systemName: icon))
                        .font(.system(size: 24))
                        .foregroundColor(.themeOnSurfaceVariant)
                )
                
            Text(label)
                .bodyText(size: 12, weight: .medium)
                .foregroundColor(.themeOnSurfaceVariant)
        }
    }
    
    var upcomingAppointmentCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Next Session")
                    .headlineText(size: 18, weight: .bold)
                Spacer()
                Text("TOMORROW")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(.themePrimary)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(Color.themePrimaryContainer.opacity(0.2))
                    .clipShape(Capsule())
            }
            
            HStack(spacing: 16) {
                Image(systemName: "person.crop.square.fill")
                    .resizable()
                    .frame(width: 64, height: 64)
                    .foregroundColor(.themeSurfaceContainerHighest)
                    .cornerRadius(12)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("Dr. Sarah Jenkins")
                        .bodyText(size: 14, weight: .bold)
                    Text("Cognitive Behavioral")
                        .bodyText(size: 12)
                        .foregroundColor(.themeOnSurfaceVariant)
                    
                    HStack(spacing: 4) {
                        Image(systemName: "clock")
                        Text("2:30 PM")
                    }
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(.themePrimary)
                }
            }
        }
        .padding(24)
        .glassCard()
    }
    
    var medicationRemindersCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Medications")
                .headlineText(size: 18, weight: .bold)
            
            VStack(spacing: 16) {
                medicationRow(name: "Prozac", time: "9:00 AM", details: "20mg • Daily", icon: "pill", color: .themeSecondary)
                medicationRow(name: "Melatonin", time: "10:00 PM", details: "5mg • Nightly", icon: "drop.fill", color: .themeTertiary)
            }
        }
        .padding(24)
        .glassCard()
    }
    
    func medicationRow(name: String, time: String, details: String, icon: String, color: Color) -> some View {
        HStack {
            Circle()
                .fill(color.opacity(0.2))
                .frame(width: 40, height: 40)
                .overlay(Image(systemName: icon).foregroundColor(color))
            
            VStack(alignment: .leading, spacing: 2) {
                Text(name).bodyText(size: 14, weight: .bold)
                Text(details).bodyText(size: 12).foregroundColor(.themeOnSurfaceVariant)
            }
            Spacer()
            Text(time)
                .font(.system(size: 10, weight: .bold))
                .foregroundColor(.themeOnSurfaceVariant.opacity(0.6))
        }
        .padding(12)
        .background(Color.themeSurfaceContainerLow.opacity(0.5))
        .cornerRadius(12)
    }
    
    var breathingExerciseCard: some View {
        HStack {
            VStack(alignment: .leading, spacing: 16) {
                Text("Take a moment.")
                    .headlineText(size: 24, weight: .heavy)
                    .foregroundColor(.themeOnSecondaryContainer)
                
                Text("A 2-minute breathing session to reset your focus.")
                    .bodyText(size: 14)
                    .foregroundColor(.themeOnSecondaryContainer.opacity(0.8))
                
                Button("Start Now") {}
                    .headlineText(size: 14, weight: .bold)
                    .foregroundColor(.white)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 12)
                    .background(Color.themeOnSecondaryContainer)
                    .clipShape(Capsule())
            }
            Spacer()
            
            Circle()
                .fill(LinearGradient(colors: [.themeSecondary, .themeSecondaryContainer], startPoint: .topLeading, endPoint: .bottomTrailing))
                .frame(width: 96, height: 96)
                .opacity(0.4)
                .overlay(Circle().stroke(Color.white.opacity(0.5), lineWidth: 2))
        }
        .padding(32)
        .background(Color.themeSecondaryContainer)
        .cornerRadius(24)
        .shadow(color: .black.opacity(0.05), radius: 20, x: 0, y: 10)
    }
}

