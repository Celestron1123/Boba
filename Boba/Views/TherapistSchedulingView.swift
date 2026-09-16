import SwiftUI
import Combine
import FirebaseFirestore

struct TherapistSchedulingView: View {
    @EnvironmentObject private var session: SessionManager
    @StateObject private var model = TherapistSchedulingViewModel()
    @State private var selectedDate = Date()
    @State private var visibleMonth = Calendar.current.dateInterval(of: .month, for: Date())?.start ?? Date()
    @State private var isAddingAvailability = false

    let onClose: () -> Void

    private let calendar = Calendar.current

    var body: some View {
        ZStack {
            Color.themeSurface.ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(spacing: 20) {
                    header
                    summaryCards
                    monthCalendar
                    selectedDaySchedule
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
        .sheet(isPresented: $isAddingAvailability) {
            AvailabilityEditorSheet(date: selectedDate) { startAt, endAt, sessionDuration, buffer in
                model.addAvailability(
                    startAt: startAt,
                    endAt: endAt,
                    sessionDurationMinutes: sessionDuration,
                    bufferMinutes: buffer
                )
            }
            .presentationDetents([.large])
            .presentationDragIndicator(.hidden)
            .presentationCornerRadius(30)
            .presentationBackground(Color.themeSurface)
        }
    }

    private var header: some View {
        HStack(spacing: 14) {
            Button(action: onClose) {
                Image(systemName: "chevron.left")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundStyle(Color.themePrimary)
                    .frame(width: 42, height: 42)
                    .background(Color.themeSurfaceContainerLow, in: Circle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Back to dashboard")

            VStack(alignment: .leading, spacing: 2) {
                Text("BOBA CLINICAL")
                    .font(.system(size: 11, weight: .semibold))
                    .tracking(1.2)
                    .foregroundStyle(Color.themeOnSurfaceVariant.opacity(0.7))
                Text("Scheduling")
                    .headlineText(size: 28, weight: .heavy)
                    .foregroundStyle(Color.themeOnSurface)
            }

            Spacer()

            Button {
                isAddingAvailability = true
            } label: {
                Image(systemName: "calendar.badge.plus")
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundStyle(.white)
                    .frame(width: 42, height: 42)
                    .background(Color.themePrimary, in: Circle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Add availability")
        }
    }

    private var summaryCards: some View {
        HStack(spacing: 12) {
            scheduleMetric(
                title: "TODAY",
                value: "\(model.appointments(on: Date()).count)",
                detail: "appointments",
                icon: "person.2.fill",
                color: .themeSecondary
            )
            scheduleMetric(
                title: "OPEN",
                value: "\(model.upcomingAvailability.count)",
                detail: "time blocks",
                icon: "clock.fill",
                color: .themeTertiary
            )
        }
    }

    private func scheduleMetric(
        title: String,
        value: String,
        detail: String,
        icon: String,
        color: Color
    ) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(title)
                    .font(.system(size: 10, weight: .bold))
                    .tracking(1)
                    .foregroundStyle(Color.themeOnSurfaceVariant.opacity(0.7))
                Spacer()
                Image(systemName: icon)
                    .foregroundStyle(color)
            }
            Text(value)
                .headlineText(size: 28, weight: .heavy)
                .foregroundStyle(Color.themeOnSurface)
            Text(detail)
                .bodyText(size: 13)
                .foregroundStyle(Color.themeOnSurfaceVariant)
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .glassCard()
    }

    private var monthCalendar: some View {
        VStack(spacing: 18) {
            HStack {
                Text(visibleMonth.formatted(.dateTime.month(.wide).year()))
                    .headlineText(size: 20, weight: .bold)
                Spacer()
                Button { moveMonth(by: -1) } label: {
                    Image(systemName: "chevron.left")
                }
                Button { moveMonth(by: 1) } label: {
                    Image(systemName: "chevron.right")
                }
            }
            .foregroundStyle(Color.themeOnSurface)

            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 7), spacing: 10) {
                ForEach(weekdaySymbols, id: \.self) { symbol in
                    Text(symbol.uppercased())
                        .font(.system(size: 10, weight: .bold))
                        .foregroundStyle(Color.themeOnSurfaceVariant.opacity(0.6))
                }

                ForEach(Array(monthDays.enumerated()), id: \.offset) { _, date in
                    if let date {
                        dayCell(date)
                    } else {
                        Color.clear
                            .aspectRatio(1, contentMode: .fit)
                    }
                }
            }
        }
        .padding(22)
        .glassCard()
    }

    private func dayCell(_ date: Date) -> some View {
        let isSelected = calendar.isDate(date, inSameDayAs: selectedDate)
        let hasAppointment = !model.appointments(on: date).isEmpty
        let hasAvailability = !model.availability(on: date).isEmpty

        return Button {
            selectedDate = date
        } label: {
            ZStack(alignment: .bottom) {
                Text("\(calendar.component(.day, from: date))")
                    .font(.system(size: 14, weight: isSelected ? .bold : .medium))
                    .frame(maxWidth: .infinity, maxHeight: .infinity)

                HStack(spacing: 3) {
                    if hasAppointment {
                        Circle().fill(Color.themeSecondary).frame(width: 4, height: 4)
                    }
                    if hasAvailability {
                        Circle().fill(Color.themeTertiary).frame(width: 4, height: 4)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .center)
                .frame(height: 4)
                .padding(.bottom, 3)
            }
            .foregroundStyle(isSelected ? Color.white : Color.themeOnSurface)
            .frame(maxWidth: .infinity)
            .aspectRatio(1, contentMode: .fit)
            .background(isSelected ? Color.themePrimary : Color.clear, in: Circle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(date.formatted(date: .complete, time: .omitted))
    }

    private var selectedDaySchedule: some View {
        let appointments = model.appointments(on: selectedDate)
        let availability = model.availability(on: selectedDate)

        return VStack(alignment: .leading, spacing: 16) {
            HStack {
                VStack(alignment: .leading, spacing: 3) {
                    Text("DAILY SCHEDULE")
                        .font(.system(size: 10, weight: .bold))
                        .tracking(1)
                        .foregroundStyle(Color.themeOnSurfaceVariant.opacity(0.7))
                    Text(selectedDate.formatted(.dateTime.weekday(.wide).month(.wide).day()))
                        .headlineText(size: 20, weight: .bold)
                }
                Spacer()
                Button("Add hours") {
                    isAddingAvailability = true
                }
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(Color.themePrimary)
            }

            if appointments.isEmpty && availability.isEmpty {
                VStack(spacing: 10) {
                    Image(systemName: "calendar.badge.clock")
                        .font(.system(size: 30))
                        .foregroundStyle(Color.themePrimary)
                    Text("Nothing scheduled")
                        .headlineText(size: 17, weight: .bold)
                    Text("Add an availability block to open this day for appointments.")
                        .bodyText(size: 14)
                        .foregroundStyle(Color.themeOnSurfaceVariant)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 22)
            } else {
                ForEach(appointments) { appointment in
                    appointmentRow(appointment)
                }
                ForEach(availability) { slot in
                    availabilityRow(slot)
                }
            }

            if let errorMessage = model.errorMessage {
                Text(errorMessage)
                    .font(.caption)
                    .foregroundStyle(Color.themeError)
            }
        }
        .padding(22)
        .glassCard()
    }

    private func appointmentRow(_ appointment: TherapistScheduledSession) -> some View {
        HStack(spacing: 14) {
            Image(systemName: "person.fill")
                .foregroundStyle(Color.themeSecondary)
                .frame(width: 38, height: 38)
                .background(Color.themeSecondaryContainer.opacity(0.55), in: Circle())
            VStack(alignment: .leading, spacing: 3) {
                Text(appointment.patientName)
                    .font(.system(size: 15, weight: .semibold))
                Text("Patient appointment")
                    .font(.system(size: 12))
                    .foregroundStyle(Color.themeOnSurfaceVariant)
            }
            Spacer()
            Text(appointment.startAt.formatted(date: .omitted, time: .shortened))
                .font(.system(size: 13, weight: .bold))
                .foregroundStyle(Color.themeSecondary)
        }
        .padding(14)
        .background(Color.themeSurfaceContainerLow, in: RoundedRectangle(cornerRadius: DS.Radius.md))
    }

    private func availabilityRow(_ slot: TherapistAvailability) -> some View {
        HStack(spacing: 14) {
            Image(systemName: "clock.fill")
                .foregroundStyle(Color.themeTertiary)
                .frame(width: 38, height: 38)
                .background(Color.themeTertiaryContainer.opacity(0.35), in: Circle())
            VStack(alignment: .leading, spacing: 3) {
                Text("Available")
                    .font(.system(size: 15, weight: .semibold))
                Text("\(slot.startAt.formatted(date: .omitted, time: .shortened))–\(slot.endAt.formatted(date: .omitted, time: .shortened))")
                    .font(.system(size: 12))
                    .foregroundStyle(Color.themeOnSurfaceVariant)
                Text(slotDescription(slot))
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(Color.themeTertiary)
            }
            Spacer()
            if let id = slot.id {
                Button(role: .destructive) {
                    model.deleteAvailability(id: id)
                } label: {
                    Image(systemName: "trash")
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Delete availability")
            }
        }
        .padding(14)
        .background(Color.themeSurfaceContainerLow, in: RoundedRectangle(cornerRadius: DS.Radius.md))
    }

    private func slotDescription(_ slot: TherapistAvailability) -> String {
        let count = slot.bookableStartTimes.count
        let session = slot.effectiveSessionDurationMinutes
        let buffer = slot.effectiveBufferMinutes
        let appointmentLabel = count == 1 ? "session" : "sessions"
        let bufferLabel = buffer == 0 ? "no buffer" : "\(buffer)-min buffer"
        return "\(count) × \(session)-min \(appointmentLabel) • \(bufferLabel)"
    }

    private var monthDays: [Date?] {
        guard let interval = calendar.dateInterval(of: .month, for: visibleMonth),
              let days = calendar.range(of: .day, in: .month, for: visibleMonth) else { return [] }
        let weekday = calendar.component(.weekday, from: interval.start)
        let leadingCount = (weekday - calendar.firstWeekday + 7) % 7
        let dates = days.compactMap { day in
            calendar.date(byAdding: .day, value: day - 1, to: interval.start)
        }
        return Array(repeating: nil, count: leadingCount) + dates.map(Optional.some)
    }

    private var weekdaySymbols: [String] {
        let symbols = calendar.veryShortStandaloneWeekdaySymbols
        let start = max(calendar.firstWeekday - 1, 0)
        return Array(symbols[start...] + symbols[..<start])
    }

    private func moveMonth(by value: Int) {
        guard let month = calendar.date(byAdding: .month, value: value, to: visibleMonth) else { return }
        visibleMonth = month
        selectedDate = month
    }
}

private struct AvailabilityEditorSheet: View {
    @Environment(\.dismiss) private var dismiss
    @State private var startAt: Date
    @State private var endAt: Date
    @State private var sessionDurationMinutes = 50
    @State private var bufferMinutes = 10

    let onSave: (Date, Date, Int, Int) -> Void

    init(date: Date, onSave: @escaping (Date, Date, Int, Int) -> Void) {
        let calendar = Calendar.current
        let start = calendar.date(bySettingHour: 9, minute: 0, second: 0, of: date) ?? date
        _startAt = State(initialValue: start)
        _endAt = State(initialValue: calendar.date(byAdding: .hour, value: 1, to: start) ?? start)
        self.onSave = onSave
    }

    var body: some View {
        ZStack {
            Color.themeSurface.ignoresSafeArea()

            Circle()
                .fill(Color.themeSecondary.opacity(0.06))
                .frame(width: 280, height: 280)
                .blur(radius: 55)
                .offset(x: 150, y: -300)

            ScrollView(showsIndicators: false) {
                VStack(spacing: 22) {
                    sheetHeader

                    VStack(alignment: .leading, spacing: 14) {
                        sectionHeading(
                            icon: "calendar.badge.clock",
                            title: "AVAILABILITY WINDOW",
                            detail: "Choose when you are open for sessions."
                        )

                        VStack(spacing: 0) {
                            datePickerRow(title: "Starts", icon: "sunrise.fill") {
                                DatePicker("Starts", selection: $startAt)
                                    .labelsHidden()
                                    .datePickerStyle(.compact)
                            }

                            Divider()
                                .padding(.leading, 46)

                            datePickerRow(title: "Ends", icon: "sunset.fill") {
                                DatePicker("Ends", selection: $endAt, in: startAt...)
                                    .labelsHidden()
                                    .datePickerStyle(.compact)
                            }
                        }
                        .padding(.horizontal, 16)
                        .background(Color.themeSurfaceContainerLow.opacity(0.72), in: RoundedRectangle(cornerRadius: DS.Radius.md))
                    }
                    .padding(20)
                    .glassCard()

                    VStack(alignment: .leading, spacing: 18) {
                        sectionHeading(
                            icon: "clock.arrow.circlepath",
                            title: "APPOINTMENT SETUP",
                            detail: "Set the rhythm for this availability block."
                        )

                        VStack(alignment: .leading, spacing: 9) {
                            Text("SESSION LENGTH")
                                .font(.system(size: 10, weight: .bold))
                                .tracking(0.8)
                                .foregroundStyle(Color.themeOnSurfaceVariant.opacity(0.7))

                            Picker("Session length", selection: $sessionDurationMinutes) {
                                Text("50 minutes").tag(50)
                                Text("60 minutes").tag(60)
                            }
                            .pickerStyle(.segmented)
                            .tint(Color.themePrimary)
                        }

                        VStack(alignment: .leading, spacing: 9) {
                            Text("TIME BETWEEN SESSIONS")
                                .font(.system(size: 10, weight: .bold))
                                .tracking(0.8)
                                .foregroundStyle(Color.themeOnSurfaceVariant.opacity(0.7))

                            Picker("Time between sessions", selection: $bufferMinutes) {
                                Text("None").tag(0)
                                Text("10 min").tag(10)
                                Text("15 min").tag(15)
                            }
                            .pickerStyle(.segmented)
                            .tint(Color.themePrimary)
                        }
                    }
                    .padding(20)
                    .glassCard()

                    HStack(spacing: 14) {
                        Image(systemName: "sparkles")
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundStyle(Color.themeTertiary)
                            .frame(width: 44, height: 44)
                            .background(Color.themeTertiaryContainer.opacity(0.35), in: Circle())

                        VStack(alignment: .leading, spacing: 3) {
                            Text(slotPreview)
                                .font(.system(size: 15, weight: .bold))
                                .foregroundStyle(Color.themeOnSurface)
                            Text("Patients can request these generated appointment times.")
                                .bodyText(size: 12)
                                .foregroundStyle(Color.themeOnSurfaceVariant)
                        }

                        Spacer(minLength: 0)
                    }
                    .padding(18)
                    .background(Color.themeTertiaryContainer.opacity(0.16), in: RoundedRectangle(cornerRadius: DS.Radius.md))

                    Button {
                        onSave(startAt, endAt, sessionDurationMinutes, bufferMinutes)
                        dismiss()
                    } label: {
                        HStack(spacing: 9) {
                            Image(systemName: "checkmark.circle.fill")
                            Text("Save Availability")
                        }
                        .headlineText(size: 17, weight: .bold)
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 18)
                        .background(Color.primaryGradient)
                        .clipShape(Capsule())
                        .shadow(color: Color.themePrimary.opacity(0.18), radius: 18, x: 0, y: 9)
                    }
                    .buttonStyle(.plain)
                    .disabled(generatedSlotCount == 0)
                    .opacity(generatedSlotCount == 0 ? 0.45 : 1)

                    Text("You can remove this block from your scheduling calendar at any time.")
                        .bodyText(size: 12)
                        .foregroundStyle(Color.themeOnSurfaceVariant.opacity(0.72))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 24)
                }
                .padding(.horizontal, 20)
                .padding(.top, 18)
                .padding(.bottom, 32)
            }
        }
        .tint(Color.themePrimary)
        .onChange(of: startAt) { _, newStart in
            guard endAt <= newStart else { return }
            endAt = Calendar.current.date(byAdding: .hour, value: 1, to: newStart) ?? newStart
        }
    }

    private var sheetHeader: some View {
        HStack(spacing: 14) {
            VStack(alignment: .leading, spacing: 3) {
                Text("PROVIDER SCHEDULE")
                    .font(.system(size: 10, weight: .bold))
                    .tracking(1.2)
                    .foregroundStyle(Color.themeOnSurfaceVariant.opacity(0.7))
                Text("Add Availability")
                    .headlineText(size: 25, weight: .heavy)
                    .foregroundStyle(Color.themeOnSurface)
            }

            Spacer()

            Button {
                dismiss()
            } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(Color.themeOnSurfaceVariant)
                    .frame(width: 40, height: 40)
                    .background(Color.themeSurfaceContainerLow, in: Circle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Close")
        }
        .padding(.horizontal, 12)
    }

    private func sectionHeading(icon: String, title: String, detail: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(Color.themePrimary)
                .frame(width: 38, height: 38)
                .background(Color.themePrimaryContainer.opacity(0.35), in: Circle())

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 10, weight: .bold))
                    .tracking(0.9)
                    .foregroundStyle(Color.themeOnSurfaceVariant.opacity(0.72))
                Text(detail)
                    .bodyText(size: 13)
                    .foregroundStyle(Color.themeOnSurfaceVariant)
            }
        }
    }

    private func datePickerRow<Picker: View>(
        title: String,
        icon: String,
        @ViewBuilder picker: () -> Picker
    ) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundStyle(Color.themePrimary)
                .frame(width: 30)
            Text(title)
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(Color.themeOnSurface)
                .lineLimit(1)
                .fixedSize(horizontal: true, vertical: false)
                .layoutPriority(1)
            Spacer()
            picker()
        }
        .padding(.vertical, 12)
    }

    private var generatedSlotCount: Int {
        TherapistAvailability(
            therapistId: "preview",
            startAt: startAt,
            endAt: endAt,
            sessionDurationMinutes: sessionDurationMinutes,
            bufferMinutes: bufferMinutes
        ).bookableStartTimes.count
    }

    private var slotPreview: String {
        let count = generatedSlotCount
        let label = count == 1 ? "bookable session" : "bookable sessions"
        return "This block creates \(count) \(label)."
    }
}

struct TherapistScheduledSession: Identifiable {
    let appointment: TherapistAppointment
    let patientName: String

    var id: String { appointment.id }
    var startAt: Date { appointment.startAt }
}

@MainActor
final class TherapistSchedulingViewModel: ObservableObject {
    @Published private(set) var sessions: [TherapistScheduledSession] = []
    @Published private(set) var availability: [TherapistAvailability] = []
    @Published var errorMessage: String?

    private let service = TherapistDataService.shared
    private var therapistId: String?
    private var connections: [TherapistPatientConnection] = []
    private var appointmentsByPatient: [String: [TherapistAppointment]] = [:]
    private var connectionListener: ListenerRegistration?
    private var availabilityListener: ListenerRegistration?
    private var appointmentListeners: [String: ListenerRegistration] = [:]

    var upcomingAvailability: [TherapistAvailability] {
        availability.filter { $0.endAt >= Date() }
    }

    func start(therapistId: String) {
        guard self.therapistId != therapistId else { return }
        stop()
        self.therapistId = therapistId

        availabilityListener = service.observeAvailability(therapistId: therapistId) { [weak self] availability, error in
            DispatchQueue.main.async {
                self?.availability = availability
                self?.record(error)
            }
        }

        connectionListener = service.observeConnections(therapistId: therapistId) { [weak self] connections, error in
            DispatchQueue.main.async {
                guard let self else { return }
                self.connections = connections
                self.record(error)
                self.refreshAppointmentListeners()
            }
        }
    }

    func stop() {
        connectionListener?.remove()
        availabilityListener?.remove()
        appointmentListeners.values.forEach { $0.remove() }
        connectionListener = nil
        availabilityListener = nil
        appointmentListeners = [:]
        appointmentsByPatient = [:]
        connections = []
        sessions = []
        availability = []
        therapistId = nil
    }

    func appointments(on date: Date) -> [TherapistScheduledSession] {
        sessions.filter { Calendar.current.isDate($0.startAt, inSameDayAs: date) }
    }

    func availability(on date: Date) -> [TherapistAvailability] {
        availability.filter { Calendar.current.isDate($0.startAt, inSameDayAs: date) }
    }

    func addAvailability(
        startAt: Date,
        endAt: Date,
        sessionDurationMinutes: Int,
        bufferMinutes: Int
    ) {
        guard let therapistId else { return }
        service.addAvailability(
            therapistId: therapistId,
            startAt: startAt,
            endAt: endAt,
            sessionDurationMinutes: sessionDurationMinutes,
            bufferMinutes: bufferMinutes
        ) { [weak self] error in
            DispatchQueue.main.async { self?.record(error) }
        }
    }

    func deleteAvailability(id: String) {
        guard let therapistId else { return }
        service.deleteAvailability(therapistId: therapistId, availabilityId: id) { [weak self] error in
            DispatchQueue.main.async { self?.record(error) }
        }
    }

    private func refreshAppointmentListeners() {
        let patientIds = Set(connections.map(\.patientId))
        let staleIds = appointmentListeners.keys.filter { !patientIds.contains($0) }

        for patientId in staleIds {
            appointmentListeners[patientId]?.remove()
            appointmentListeners.removeValue(forKey: patientId)
            appointmentsByPatient.removeValue(forKey: patientId)
        }

        for connection in connections where appointmentListeners[connection.patientId] == nil {
            appointmentListeners[connection.patientId] = service.observeAppointments(patientId: connection.patientId) { [weak self] appointments, error in
                DispatchQueue.main.async {
                    self?.appointmentsByPatient[connection.patientId] = appointments
                    self?.record(error)
                    self?.rebuildSessions()
                }
            }
        }

        rebuildSessions()
    }

    private func rebuildSessions() {
        sessions = connections.flatMap { connection in
            (appointmentsByPatient[connection.patientId] ?? []).map {
                TherapistScheduledSession(appointment: $0, patientName: connection.displayName)
            }
        }
        .sorted { $0.startAt < $1.startAt }
    }

    private func record(_ error: Error?) {
        if let error {
            errorMessage = error.localizedDescription
        }
    }
}
