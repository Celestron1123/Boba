import SwiftUI
import Charts
import Combine
import FirebaseFirestore

struct TherapistContentView: View {
    @State private var selectedIndex = 0

    var body: some View {
        ZStack {
            Group {
                if selectedIndex == 0 {
                    TherapistDashboardView {
                        selectedIndex = 2
                    }
                } else if selectedIndex == 1 {
                    TherapistConnectionsView()
                } else {
                    TherapistSchedulingView {
                        selectedIndex = 0
                    }
                }
            }
        }
        .safeAreaInset(edge: .bottom) {
            TherapistBottomNavBar(selectedIndex: $selectedIndex)
                .padding(.bottom, 16)
        }
    }
}

private struct TherapistBottomNavBar: View {
    @Binding var selectedIndex: Int

    var body: some View {
        HStack(spacing: 8) {
            tab("Dashboard", icon: "square.grid.2x2.fill", index: 0)
            tab("Connect", icon: "person.badge.plus", index: 1)
        }
        .padding(8)
        .background(.ultraThinMaterial, in: Capsule())
        .shadow(color: DS.Shadow.card.color, radius: DS.Shadow.card.radius,
                x: DS.Shadow.card.x, y: DS.Shadow.card.y)
        .padding(.horizontal, 56)
    }

    private func tab(_ title: String, icon: String, index: Int) -> some View {
        Button {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                selectedIndex = index
            }
        } label: {
            HStack(spacing: 8) {
                Image(systemName: icon)
                Text(title)
            }
            .font(.system(size: 13, weight: .semibold))
            .foregroundStyle(selectedIndex == index ? .white : Color.themeOnSurfaceVariant)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background {
                if selectedIndex == index {
                    Color.primaryGradient
                        .clipShape(Capsule())
                }
            }
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(selectedIndex == index ? .isSelected : [])
    }
}

struct TherapistDashboardView: View {
    /// Scheduling view is selected
    let onSchedulingSelected: () -> Void

    @EnvironmentObject private var session: SessionManager
    @StateObject private var model = TherapistDashboardViewModel()
    @State private var selectedLog: LogSelection?
    @State private var composer: AnnotationComposer?

    var body: some View {
        ZStack {
            Color.themeSurface.ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(spacing: 20) {
                    header

                    if model.connections.isEmpty && !model.isLoading {
                        emptyConnectionState
                    } else if let connection = model.selectedConnection {
                        if let errorMessage = model.errorMessage {
                            Text(errorMessage)
                                .font(.caption)
                                .foregroundStyle(Color.themeError)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                        patientSummary(connection)
                        appointmentCard
                        moodTrendCard
                        analyticsCards
                        deferredCards
                        recentLogs
                    } else {
                        ProgressView("Loading patient workspace…")
                            .tint(.themePrimary)
                            .frame(maxWidth: .infinity, minHeight: 300)
                    }

                    Spacer().frame(height: 100)
                }
                .padding(.horizontal, 20)
                .padding(.top, 8)
            }
        }
        .task {
            guard let therapistId = session.currentUserId else { return }
            model.start(therapistId: therapistId)
        }
        .onDisappear { model.stop() }
        .sheet(item: $selectedLog) { selection in
            if let log = model.logs.first(where: { $0.id == selection.id }) {
                TherapistLogDetailView(log: log, model: model)
            }
        }
        .sheet(item: $composer) { composer in
            AnnotationComposerView(composer: composer, model: model)
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("BOBA CLINICAL")
                        .font(.system(size: 11, weight: .semibold))
                        .tracking(1.2)
                        .foregroundStyle(Color.themeOnSurfaceVariant.opacity(0.7))
                    Text("Dashboard")
                        .headlineText(size: 28, weight: .heavy)
                        .foregroundStyle(Color.themeOnSurface)
                }
                Spacer()
                Image(systemName: "bell.fill")
                    .foregroundStyle(Color.themePrimary)
                    .padding(12)
                    .background(Color.themeSurfaceContainerLow, in: Circle())
                Menu {
                    Button {
                        // Profile destination will be connected when its view is added.
                    } label: {
                        Label("Profile", systemImage: "person.crop.circle")
                    }

                    Button {
                        onSchedulingSelected()
                    } label: {
                        Label("Scheduling", systemImage: "calendar")
                    }
                } label: {
                    Image(systemName: "person.fill")
                        .foregroundStyle(.white)
                        .padding(12)
                        .background(Color.themePrimary, in: Circle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Provider menu")
            }

            Menu {
                ForEach(model.connections) { connection in
                    Button {
                        model.selectPatient(connection.patientId)
                    } label: {
                        Label(connection.displayName, systemImage: connection.patientId == model.selectedPatientId ? "checkmark" : "person")
                    }
                }
                if model.connections.isEmpty {
                    Text("Connect a patient to begin")
                }
            } label: {
                HStack(spacing: 10) {
                    Image(systemName: "person.2.fill")
                        .foregroundStyle(Color.themeTertiary)
                    VStack(alignment: .leading, spacing: 2) {
                        Text("ACTIVE PATIENT")
                            .font(.system(size: 10, weight: .bold))
                            .tracking(1)
                            .foregroundStyle(Color.themeOnSurfaceVariant.opacity(0.7))
                        Text(model.selectedConnection?.displayName ?? "Select a patient")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundStyle(Color.themeOnSurface)
                    }
                    Spacer()
                    Image(systemName: "chevron.down")
                        .foregroundStyle(Color.themePrimary)
                }
                .padding(16)
                .background(Color.themeSurfaceContainerLow, in: RoundedRectangle(cornerRadius: 20))
            }
            .disabled(model.connections.isEmpty)
        }
    }

    private var emptyConnectionState: some View {
        VStack(spacing: 14) {
            Image(systemName: "person.2.slash")
                .font(.system(size: 34))
                .foregroundStyle(Color.themePrimary)
            Text("No connected patients yet")
                .headlineText(size: 21, weight: .bold)
            Text("Use Connect to link a patient by their patient number. Their dashboard will appear here in real time.")
                .bodyText(size: 15)
                .foregroundStyle(Color.themeOnSurfaceVariant)
                .multilineTextAlignment(.center)
        }
        .padding(28)
        .frame(maxWidth: .infinity)
        .glassCard()
    }

    private func patientSummary(_ connection: TherapistPatientConnection) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(connection.displayName)
                        .headlineText(size: 24, weight: .heavy)
                    Text("Patient ID #\(String(format: "%04d", connection.patientNumber))")
                        .font(.system(size: 12, weight: .semibold, design: .monospaced))
                        .foregroundStyle(Color.themeOnSurfaceVariant)
                }
                Spacer()
                Image(systemName: "cross.case.fill")
                    .foregroundStyle(Color.themeTertiary)
                    .padding(14)
                    .background(Color.themeTertiaryContainer.opacity(0.35), in: Circle())
            }

            if !connection.wellnessGoals.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(connection.wellnessGoals, id: \.self) { goal in
                            Text(goal)
                                .font(.system(size: 12, weight: .medium))
                                .foregroundStyle(Color.themeOnSecondaryContainer)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 7)
                                .background(Color.themeSecondaryContainer.opacity(0.55), in: Capsule())
                        }
                    }
                }
            }
        }
        .padding(22)
        .glassCard()
    }

    private var moodTrendCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("EMOTIONAL VALENCE")
                        .font(.system(size: 11, weight: .bold))
                        .tracking(1)
                        .foregroundStyle(Color.themeOnSurfaceVariant.opacity(0.75))
                    Text("7-Day Trajectory")
                        .headlineText(size: 21, weight: .bold)
                }
                Spacer()
                Text(model.moodTrend.last?.mood ?? "No trend")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(Color.themeTertiary)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 7)
                    .background(Color.themeTertiaryContainer.opacity(0.28), in: Capsule())
            }

            if model.moodTrend.isEmpty {
                Text("Mood trend will appear after the patient records check-ins.")
                    .bodyText(size: 14)
                    .foregroundStyle(Color.themeOnSurfaceVariant)
                    .frame(maxWidth: .infinity, minHeight: 140)
            } else {
                Chart(model.moodTrend) { point in
                    AreaMark(
                        x: .value("Date", point.date),
                        y: .value("Mood", point.value)
                    )
                    .foregroundStyle(Color.themeTertiary.opacity(0.12))

                    LineMark(
                        x: .value("Date", point.date),
                        y: .value("Mood", point.value)
                    )
                    .interpolationMethod(.catmullRom)
                    .foregroundStyle(Color.themeTertiary)
                    .lineStyle(StrokeStyle(lineWidth: 3))

                    PointMark(
                        x: .value("Date", point.date),
                        y: .value("Mood", point.value)
                    )
                    .foregroundStyle(Color.themeTertiary)
                }
                .chartYScale(domain: 1...5)
                .chartYAxis {
                    AxisMarks(values: [1, 3, 5]) { value in
                        AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5, dash: [3]))
                            .foregroundStyle(Color.themeOutlineVariant.opacity(0.35))
                        AxisValueLabel {
                            Text(value.as(Int.self).map(String.init) ?? "")
                                .font(.system(size: 10))
                        }
                    }
                }
                .chartXAxis {
                    AxisMarks(values: .stride(by: .day)) { value in
                        AxisValueLabel(format: .dateTime.weekday(.abbreviated))
                            .font(.system(size: 10))
                    }
                }
                .frame(height: 170)
            }
        }
        .padding(22)
        .glassCard()
    }

    private var analyticsCards: some View {
        VStack(spacing: 14) {
            HStack(spacing: 14) {
                MetricCard(title: "CHECK-INS", value: "\(model.checkInsLast30Days)", detail: "last 30 days", icon: "checkmark.circle.fill", color: .themeTertiary)
                MetricCard(title: "ACTIVE DAYS", value: "\(model.activeDaysLast30Days)", detail: "last 30 days", icon: "calendar", color: .themePrimary)
            }

            VStack(alignment: .leading, spacing: 12) {
                Text("RECENT EMOTION PATTERNS")
                    .font(.system(size: 11, weight: .bold))
                    .tracking(1)
                    .foregroundStyle(Color.themeOnSurfaceVariant.opacity(0.75))
                if model.tagCounts.isEmpty {
                    Text("Emotion patterns will appear as tags are logged.")
                        .bodyText(size: 14)
                        .foregroundStyle(Color.themeOnSurfaceVariant)
                } else {
                    ForEach(model.tagCounts, id: \.tag) { item in
                        HStack(spacing: 10) {
                            Text(item.tag)
                                .font(.system(size: 13, weight: .medium))
                                .frame(width: 100, alignment: .leading)
                            GeometryReader { proxy in
                                Capsule()
                                    .fill(Color.themeSecondaryContainer.opacity(0.7))
                                    .overlay(alignment: .leading) {
                                        Capsule()
                                            .fill(Color.themeSecondary)
                                            .frame(width: proxy.size.width * CGFloat(item.count) / CGFloat(max(model.tagCounts.first?.count ?? 1, 1)))
                                    }
                            }
                            .frame(height: 9)
                            Text("\(item.count)")
                                .font(.system(size: 12, weight: .bold, design: .monospaced))
                        }
                    }
                }
            }
            .padding(20)
            .glassCard()
        }
    }

    private var appointmentCard: some View {
        ComingSoonCard(title: "UPCOMING SESSION", icon: "calendar.badge.clock", isComingSoon: false, message: model.appointments.first.map {
            "\($0.providerName) • \($0.startAt.formatted(date: .abbreviated, time: .shortened))"
        } ?? "No upcoming appointment scheduled")
    }

    private var deferredCards: some View {
        VStack(spacing: 14) {
            HStack(spacing: 14) {
                ComingSoonCard(title: "AI INSIGHTS", icon: "sparkles", message: "Coming soon")
                ComingSoonCard(title: "SLEEP & HYDRATION", icon: "drop.fill", message: "Coming soon")
            }
            ComingSoonCard(title: "TELEHEALTH ROOM", icon: "video.fill", message: "Video visits coming soon")
        }
    }

    private var recentLogs: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Text("Recent Patient Check-ins")
                    .headlineText(size: 21, weight: .bold)
                Spacer()
                Text("\(model.logs.count) loaded")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(Color.themePrimary)
            }

            if model.logs.isEmpty {
                Text("No check-ins have been recorded yet.")
                    .bodyText(size: 15)
                    .foregroundStyle(Color.themeOnSurfaceVariant)
                    .padding(22)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .glassCard()
            } else {
                ForEach(Array(model.logs.prefix(10).enumerated()), id: \.offset) { _, log in
                    TherapistLogCard(log: log, summary: model.annotationSummary(for: log),
                                     openDetail: { selectedLog = LogSelection(id: log.id ?? UUID().uuidString) },
                                     addPrivateNote: { composer = AnnotationComposer(log: log, mode: .privateNote) },
                                     addComment: { composer = AnnotationComposer(log: log, mode: .comment) })
                }
            }
        }
    }
}

private struct MetricCard: View {
    let title: String
    let value: String
    let detail: String
    let icon: String
    let color: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Image(systemName: icon)
                .foregroundStyle(color)
            Text(title)
                .font(.system(size: 10, weight: .bold))
                .tracking(1)
                .foregroundStyle(Color.themeOnSurfaceVariant.opacity(0.7))
            Text(value)
                .font(.system(size: 27, weight: .bold, design: .rounded))
                .foregroundStyle(Color.themeOnSurface)
            Text(detail)
                .font(.system(size: 11))
                .foregroundStyle(Color.themeOnSurfaceVariant)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(18)
        .glassCard()
    }
}

private struct ComingSoonCard: View {
    let title: String
    let icon: String
    var isComingSoon = true
    let message: String

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundStyle(Color.themeOnSurfaceVariant.opacity(0.45))
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(size: 10, weight: .bold))
                    .tracking(1)
                    .foregroundStyle(Color.themeOnSurfaceVariant.opacity(0.55))
                Text(message)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(Color.themeOnSurfaceVariant.opacity(0.65))
            }
            Spacer()
            if isComingSoon {
                Text("COMING SOON")
                    .font(.system(size: 9, weight: .bold))
                    .foregroundStyle(Color.themeOnSurfaceVariant.opacity(0.55))
                    .padding(.horizontal, 8)
                    .padding(.vertical, 6)
                    .background(Color.themeSurfaceContainerHighest, in: Capsule())
            }
        }
        .padding(16)
        .opacity(0.7)
        .background(Color.themeSurfaceContainerLow, in: RoundedRectangle(cornerRadius: 20))
    }
}

struct TherapistLogCard: View {
    let log: DailyLog
    let summary: LogAnnotationSummary
    let openDetail: () -> Void
    let addPrivateNote: () -> Void
    let addComment: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Button(action: openDetail) {
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(log.date.formatted(date: .abbreviated, time: .shortened))
                            .font(.system(size: 15, weight: .bold))
                            .foregroundStyle(Color.themeOnSurface)
                        Text(log.tags.isEmpty ? "Patient check-in" : log.tags.joined(separator: " • "))
                            .font(.system(size: 12))
                            .foregroundStyle(Color.themeOnSurfaceVariant)
                    }
                    Spacer()
                    MoodPill(mood: log.mood)
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)

            if !log.notes.isEmpty {
                Text(log.notes)
                    .font(.system(size: 14, weight: .regular, design: .default))
                    .italic()
                    .foregroundStyle(Color.themeOnSurfaceVariant)
                    .lineLimit(3)
                    .padding(14)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color.themeSurfaceContainerLow, in: RoundedRectangle(cornerRadius: 16))
            }

            if let note = summary.privateNotes.first {
                Label(note.text, systemImage: "lock.fill")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(Color.themePrimary)
                    .lineLimit(2)
            }

            HStack(spacing: 10) {
                Button(action: addPrivateNote) {
                    Label("Private Note", systemImage: "lock.fill")
                }
                Button(action: addComment) {
                    Label("Comment\(summary.comments.isEmpty ? "" : " (\(summary.comments.count))")", systemImage: "bubble.left")
                }
            }
            .font(.system(size: 12, weight: .semibold))
            .foregroundStyle(Color.themePrimary)
        }
        .padding(20)
        .glassCard()
    }
}

private struct MoodPill: View {
    let mood: String

    var body: some View {
        Text(mood.capitalized)
            .font(.system(size: 11, weight: .bold))
            .foregroundStyle(Color.themeOnSurface)
            .padding(.horizontal, 10)
            .padding(.vertical, 7)
            .background(color.opacity(0.55), in: Capsule())
    }

    private var color: Color {
        switch mood.uppercased() {
        case "AWFUL": return .moodTerrible
        case "BAD": return .moodBad
        case "OKAY": return .moodOkay
        case "GOOD": return .moodGood
        case "GREAT": return .moodGreat
        default: return .themeSurfaceContainerHighest
        }
    }
}

struct LogSelection: Identifiable {
    let id: String
}

struct TherapistLogDetailView: View {
    @Environment(\.dismiss) private var dismiss
    let log: DailyLog
    @ObservedObject var model: TherapistDashboardViewModel
    @State private var composer: AnnotationComposer?

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    HStack {
                        Text(log.date.formatted(date: .long, time: .shortened))
                            .headlineText(size: 20, weight: .bold)
                        Spacer()
                        MoodPill(mood: log.mood)
                    }

                    if !log.tags.isEmpty {
                        LazyVGrid(columns: [GridItem(.adaptive(minimum: 120), alignment: .leading)], alignment: .leading, spacing: 8) {
                            ForEach(log.tags, id: \.self) { tag in
                                Text(tag)
                                    .font(.system(size: 13, weight: .medium))
                                    .padding(.horizontal, 11)
                                    .padding(.vertical, 8)
                                    .background(Color.themeSurfaceContainerHigh, in: Capsule())
                            }
                        }
                    }

                    Text(log.notes.isEmpty ? "The patient did not add a journal reflection." : log.notes)
                        .bodyText(size: 16)
                        .foregroundStyle(Color.themeOnSurfaceVariant)
                        .lineSpacing(5)
                        .padding(20)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color.themeSurfaceContainerLow, in: RoundedRectangle(cornerRadius: 20))

                    let summary = model.annotationSummary(for: log)
                    if !summary.privateNotes.isEmpty {
                        annotationSection(title: "Your Private Notes", icon: "lock.fill", annotations: summary.privateNotes)
                    }
                    if !summary.comments.isEmpty {
                        annotationSection(title: "Comments to Patient", icon: "bubble.left.fill", annotations: summary.comments)
                    }

                    HStack(spacing: 12) {
                        Button {
                            composer = AnnotationComposer(log: log, mode: .privateNote)
                        } label: {
                            Label("Private Note", systemImage: "lock.fill")
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(Color.themePrimary)

                        Button {
                            composer = AnnotationComposer(log: log, mode: .comment)
                        } label: {
                            Label("Comment", systemImage: "bubble.left")
                        }
                        .buttonStyle(.bordered)
                        .tint(Color.themePrimary)
                    }
                }
                .padding(22)
            }
            .background(Color.themeSurface.ignoresSafeArea())
            .navigationTitle("Patient Log")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
            .sheet(item: $composer) { composer in
                AnnotationComposerView(composer: composer, model: model)
            }
        }
    }

    private func annotationSection(title: String, icon: String, annotations: [TherapistAnnotation]) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Label(title, systemImage: icon)
                .font(.system(size: 13, weight: .bold))
                .foregroundStyle(Color.themePrimary)
            ForEach(annotations) { annotation in
                VStack(alignment: .leading, spacing: 5) {
                    Text(annotation.text)
                        .bodyText(size: 14)
                    Text(annotation.createdAt.formatted(date: .abbreviated, time: .shortened))
                        .font(.system(size: 11))
                        .foregroundStyle(Color.themeOnSurfaceVariant.opacity(0.7))
                }
                .padding(14)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color.themeSurfaceContainerLow, in: RoundedRectangle(cornerRadius: 16))
            }
        }
    }
}

enum AnnotationMode {
    case privateNote
    case comment

    var title: String { self == .privateNote ? "Add Private Note" : "Comment to Patient" }
    var description: String {
        self == .privateNote
            ? "Only you can read this note while connected to this patient."
            : "This comment will be visible to the patient."
    }
    var icon: String { self == .privateNote ? "lock.fill" : "bubble.left.fill" }
}

struct AnnotationComposer: Identifiable {
    let id = UUID()
    let log: DailyLog
    let mode: AnnotationMode
}

struct AnnotationComposerView: View {
    @Environment(\.dismiss) private var dismiss
    let composer: AnnotationComposer
    @ObservedObject var model: TherapistDashboardViewModel
    @State private var text = ""
    @State private var isSaving = false
    @State private var errorMessage: String?

    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 18) {
                Label(composer.mode.title, systemImage: composer.mode.icon)
                    .headlineText(size: 22, weight: .bold)
                Text(composer.mode.description)
                    .bodyText(size: 14)
                    .foregroundStyle(Color.themeOnSurfaceVariant)

                TextEditor(text: $text)
                    .font(.system(size: 16))
                    .scrollContentBackground(.hidden)
                    .padding(14)
                    .background(Color.themeSurfaceContainerLow, in: RoundedRectangle(cornerRadius: 18))
                    .frame(minHeight: 180)

                if let errorMessage {
                    Text(errorMessage)
                        .font(.caption)
                        .foregroundStyle(Color.themeError)
                }
                Spacer()
            }
            .padding(22)
            .background(Color.themeSurface.ignoresSafeArea())
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button(isSaving ? "Saving…" : "Save") { save() }
                        .disabled(isSaving || text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
        }
    }

    private func save() {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        isSaving = true
        errorMessage = nil
        let completion: (Error?) -> Void = { error in
            DispatchQueue.main.async {
                isSaving = false
                if let error {
                    errorMessage = error.localizedDescription
                } else {
                    dismiss()
                }
            }
        }
        switch composer.mode {
        case .privateNote:
            model.savePrivateNote(text: trimmed, for: composer.log, completion: completion)
        case .comment:
            model.saveComment(text: trimmed, for: composer.log, completion: completion)
        }
    }
}

@MainActor
final class TherapistConnectionsViewModel: ObservableObject {
    @Published private(set) var connections: [TherapistPatientConnection] = []
    @Published var patientNumber = ""
    @Published var isLoading = true
    @Published var isSubmitting = false
    @Published var errorMessage: String?
    @Published var successMessage: String?

    private let service = TherapistDataService.shared
    private var listener: ListenerRegistration?
    private var therapistId: String?

    func start(therapistId: String) {
        guard listener == nil else { return }
        self.therapistId = therapistId
        listener = service.observeConnections(therapistId: therapistId) { [weak self] connections, error in
            DispatchQueue.main.async {
                self?.isLoading = false
                self?.connections = connections
                self?.errorMessage = error?.localizedDescription
            }
        }
    }

    func stop() {
        listener?.remove()
        listener = nil
        therapistId = nil
    }

    func connect() {
        guard let number = Int(patientNumber.trimmingCharacters(in: .whitespacesAndNewlines)), number > 0 else {
            errorMessage = "Enter a valid patient number."
            return
        }
        isSubmitting = true
        errorMessage = nil
        successMessage = nil
        guard let therapistId else { return }
        service.connectPatient(therapistId: therapistId, patientNumber: number) { [weak self] result in
            DispatchQueue.main.async {
                guard let self else { return }
                self.isSubmitting = false
                switch result {
                case .success:
                    self.patientNumber = ""
                    self.successMessage = "Patient connected successfully."
                case .failure(let error):
                    self.errorMessage = Self.readableError(error)
                }
            }
        }
    }

    func disconnect(_ connection: TherapistPatientConnection, completion: @escaping (Error?) -> Void) {
        guard let therapistId else { return }
        service.disconnectPatient(therapistId: therapistId, patientId: connection.patientId) { result in
            DispatchQueue.main.async {
                switch result {
                case .success: completion(nil)
                case .failure(let error): completion(error)
                }
            }
        }
    }

    private static func readableError(_ error: Error) -> String {
        let message = error.localizedDescription
        return message.isEmpty ? "The request could not be completed." : message
    }
}

struct TherapistConnectionsView: View {
    @EnvironmentObject private var session: SessionManager
    @StateObject private var model = TherapistConnectionsViewModel()
    @State private var connectionToRemove: TherapistPatientConnection?
    @State private var isRemoving = false

    var body: some View {
        ZStack {
            Color.themeSurface.ignoresSafeArea()
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 22) {
                    pageHeader
                    connectCard
                    pendingCard
                    currentConnections
                    Spacer().frame(height: 100)
                }
                .padding(.horizontal, 20)
                .padding(.top, 8)
            }
        }
        .task {
            guard let therapistId = session.currentUserId else { return }
            model.start(therapistId: therapistId)
        }
        .onDisappear { model.stop() }
        .confirmationDialog("Remove this patient connection?", isPresented: Binding(
            get: { connectionToRemove != nil },
            set: { if !$0 { connectionToRemove = nil } }
        )) {
            Button("Remove Connection", role: .destructive) {
                guard let connection = connectionToRemove else { return }
                isRemoving = true
                model.disconnect(connection) { _ in
                    isRemoving = false
                    connectionToRemove = nil
                }
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("You will immediately lose access to \(connectionToRemove?.displayName ?? "this patient's") logs and private notes.")
        }
    }

    private var pageHeader: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("BOBA CLINICAL")
                .font(.system(size: 11, weight: .semibold))
                .tracking(1.2)
                .foregroundStyle(Color.themeOnSurfaceVariant.opacity(0.7))
            Text("Connect")
                .headlineText(size: 28, weight: .heavy)
        }
    }

    private var connectCard: some View {
        VStack(alignment: .leading, spacing: 18) {
            Label("CONNECT NEW PATIENT", systemImage: "person.badge.plus")
                .font(.system(size: 12, weight: .bold))
                .tracking(0.8)
                .foregroundStyle(Color.themePrimary)
            Text("Enter the patient number shown in their Boba profile to link their clinical check-ins.")
                .bodyText(size: 15)
                .foregroundStyle(Color.themeOnSurfaceVariant)

            HStack(spacing: 10) {
                Image(systemName: "number")
                    .foregroundStyle(Color.themeOnSurfaceVariant)
                TextField("Patient number", text: $model.patientNumber)
                    .keyboardType(.numberPad)
                    .textInputAutocapitalization(.never)
            }
            .padding(15)
            .background(Color.themeSurfaceContainerHigh, in: Capsule())

            if let errorMessage = model.errorMessage {
                Text(errorMessage)
                    .font(.caption)
                    .foregroundStyle(Color.themeError)
            }
            if let successMessage = model.successMessage {
                Text(successMessage)
                    .font(.caption)
                    .foregroundStyle(Color.themeTertiary)
            }

            Button(action: model.connect) {
                HStack {
                    if model.isSubmitting { ProgressView().tint(.white) }
                    Text(model.isSubmitting ? "Connecting…" : "Connect Patient")
                    Spacer()
                    Image(systemName: "arrow.right")
                }
                .font(.system(size: 15, weight: .bold))
                .foregroundStyle(.white)
                .padding(.horizontal, 18)
                .padding(.vertical, 16)
                .background(Color.primaryGradient, in: Capsule())
            }
            .disabled(model.isSubmitting)
        }
        .padding(22)
        .glassCard()
    }

    private var pendingCard: some View {
        HStack(spacing: 12) {
            Image(systemName: "clock.arrow.circlepath")
                .foregroundStyle(Color.themeOnSurfaceVariant.opacity(0.45))
            VStack(alignment: .leading, spacing: 4) {
                Text("PENDING CONNECTIONS")
                    .font(.system(size: 11, weight: .bold))
                    .tracking(1)
                    .foregroundStyle(Color.themeOnSurfaceVariant.opacity(0.55))
                Text("Coming soon")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(Color.themeOnSurfaceVariant.opacity(0.65))
            }
            Spacer()
            Text("COMING SOON")
                .font(.system(size: 9, weight: .bold))
                .foregroundStyle(Color.themeOnSurfaceVariant.opacity(0.55))
                .padding(.horizontal, 8)
                .padding(.vertical, 6)
                .background(Color.themeSurfaceContainerHighest, in: Capsule())
        }
        .padding(18)
        .opacity(0.7)
        .background(Color.themeSurfaceContainerLow, in: RoundedRectangle(cornerRadius: 20))
    }

    private var currentConnections: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Current Connections")
                .headlineText(size: 21, weight: .bold)

            if model.isLoading {
                ProgressView().tint(.themePrimary)
            } else if model.connections.isEmpty {
                Text("Your connected patients will appear here.")
                    .bodyText(size: 14)
                    .foregroundStyle(Color.themeOnSurfaceVariant)
            } else {
                ForEach(model.connections) { connection in
                    HStack(spacing: 13) {
                        Text(String(connection.displayName.prefix(1)).uppercased())
                            .font(.system(size: 16, weight: .bold))
                            .foregroundStyle(Color.themeSecondary)
                            .frame(width: 42, height: 42)
                            .background(Color.themeSecondaryContainer, in: Circle())
                        VStack(alignment: .leading, spacing: 4) {
                            Text(connection.displayName)
                                .font(.system(size: 15, weight: .semibold))
                            Text("#\(String(format: "%04d", connection.patientNumber))")
                                .font(.system(size: 11, weight: .semibold, design: .monospaced))
                                .foregroundStyle(Color.themeOnSurfaceVariant)
                        }
                        Spacer()
                        Button("Remove") {
                            connectionToRemove = connection
                        }
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(Color.themeError)
                        .disabled(isRemoving)
                    }
                    .padding(16)
                    .background(Color.themeSurfaceContainerLow, in: RoundedRectangle(cornerRadius: 18))
                }
            }
        }
    }
}
