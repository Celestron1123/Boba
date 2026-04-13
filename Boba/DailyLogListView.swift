import SwiftUI
import FirebaseFirestore

struct DailyLogListView: View {
    @State private var logs: [DailyLog] = []
    @State private var isLoading: Bool = true
    @State private var errorMessage: String? = nil

    var body: some View {
        ZStack {
            // Foundational Canvas
            Color.themeSurface.ignoresSafeArea()
            
            // Ambient atmospheric glows from DESIGN.md principles
            Circle()
                .fill(Color.themeTertiaryContainer.opacity(0.15))
                .frame(width: 300, height: 300)
                .blur(radius: 80)
                .position(x: 350, y: 150)
            
            Circle()
                .fill(Color.themeSecondaryContainer.opacity(0.15))
                .frame(width: 250, height: 250)
                .blur(radius: 60)
                .position(x: 50, y: 600)
                
            VStack(spacing: 0) {
                headerSection
                
                if isLoading {
                    Spacer()
                    ProgressView()
                        .tint(.themePrimary)
                        .scaleEffect(1.5)
                    Spacer()
                } else if let errorMessage = errorMessage {
                    Spacer()
                    Text(errorMessage)
                        .bodyText()
                        .foregroundColor(.themeError)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 24)
                    Spacer()
                } else if logs.isEmpty {
                    Spacer()
                    Text("No logs found.")
                        .bodyText(size: 18)
                        .foregroundColor(.themeOnSurfaceVariant.opacity(0.7))
                    Spacer()
                } else {
                    ScrollView(showsIndicators: false) {
                        LazyVStack(spacing: 16) {
                            ForEach(logs, id: \.id) { log in
                                LogCard(log: log)
                            }
                        }
                        .padding(.horizontal, 24)
                        .padding(.top, 16)
                        .padding(.bottom, 120) // Breathing room and space for bottom nav
                    }
                }
            }
        }
        .onAppear {
            fetchLogs()
        }
    }
    
    var headerSection: some View {
        HStack {
            Text("Past Logs")
                .headlineText(size: 36, weight: .heavy) // Display-lg editorial feel
                .foregroundColor(.themePrimary)
                .tracking(-0.5)
            Spacer()
        }
        .padding(.horizontal, 24)
        .padding(.top, 24)
        .padding(.bottom, 16)
        // Liquid Glass header spanning under the status bar
        .background(
            Color.themeSurface.opacity(0.7)
                .background(.ultraThinMaterial)
                .ignoresSafeArea(edges: .top)
        )
    }
    
    @MainActor private func fetchLogs() {
        let db = Firestore.firestore()
        db.collection("logs").order(by: "date", descending: true).getDocuments { snapshot, error in
            DispatchQueue.main.async {
                self.isLoading = false
                if let error = error {
                    self.errorMessage = "Error loading logs: \(error.localizedDescription)"
                    return
                }

                self.logs = snapshot?.documents.compactMap { doc in
                    try? doc.data(as: DailyLog.self)
                } ?? []
            }
        }
    }
}

// Custom Glassmorphic Card for a single Log
struct LogCard: View {
    let log: DailyLog
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header Row: Date & Mood Tag
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(formatDate(log.date))
                        .headlineText(size: 18, weight: .bold) // Hierarchical empathy
                        .foregroundColor(.themeOnSurface)
                    
                    Text(formatTime(log.date))
                        .bodyText(size: 14)
                        .foregroundColor(.themeOnSurfaceVariant.opacity(0.8))
                }
                
                Spacer()
                
                // Mood Pill/Badge
                HStack(spacing: 6) {
                    Image(moodIcon(for: log.mood))
                        .resizable()
                        .scaledToFit()
                        .frame(width: 16, height: 16)
                        .foregroundColor(.themeOnSurfaceVariant)
                    
                    Text(log.mood)
                        .font(.system(size: 11, weight: .bold)) // Clean label
                        .tracking(1)
                        .foregroundColor(.themeOnSurface)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(moodColor(for: log.mood).opacity(0.4))
                .clipShape(Capsule())
            }
            
            if !log.notes.isEmpty {
                Divider()
                    .background(Color.themeOutlineVariant.opacity(0.15)) // Ghost Border fallback style
                
                Text(log.notes)
                    .bodyText(size: 16)
                    .foregroundColor(.themeOnSurfaceVariant) // Workhorse text style
                    .lineSpacing(4)
            }
        }
        .padding(24)
        .glassCard() // Reused component to maintain Liquid Glass strategy
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM d, yyyy"
        return formatter.string(from: date)
    }
    
    private func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
    
    private func moodColor(for moodString: String) -> Color {
        switch moodString.uppercased() {
        case "AWFUL": return .moodTerrible
        case "BAD": return .moodBad
        case "OKAY": return .moodOkay
        case "GOOD": return .moodGood
        case "GREAT": return .moodGreat
        default: return .themeSurfaceContainerHighest
        }
    }
    
    private func moodIcon(for moodString: String) -> String {
        switch moodString.uppercased() {
        case "AWFUL": return "face.terrible"
        case "BAD": return "face.sad"
        case "OKAY": return "face.okay"
        case "GOOD": return "face.good"
        case "GREAT": return "face.great"
        default: return "face.okay"
        }
    }
}

struct DailyLogListView_Previews: PreviewProvider {
    static var previews: some View {
        DailyLogListView()
    }
}
