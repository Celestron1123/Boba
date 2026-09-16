/**
 * AppointmentsView.swift
 *
 * Overview: Lets a patient book an appointment from a connected provider's
 * live availability.
 */

import SwiftUI
import Combine
import FirebaseFirestore

struct AppointmentsView: View {
    @EnvironmentObject private var session: SessionManager
    @StateObject private var model = PatientSchedulingViewModel()
    @State private var selectedDate = Date()
    @State private var visibleMonth = Calendar.current.dateInterval(of: .month, for: Date())?.start ?? Date()
    @State private var selectedSlot: BookableAppointmentSlot?
    @State private var confirmedSlot: BookableAppointmentSlot?
    @State private var showConfirmation = false

    private let calendar = Calendar.current
    private let weekdaySymbols = ["SUN", "MON", "TUE", "WED", "THU", "FRI", "SAT"]

    var body: some View {
        ZStack {
            Color.themeSurface.ignoresSafeArea()

            Circle()
                .fill(Color.themeSecondary.opacity(0.05))
                .frame(width: 384, height: 384)
                .blur(radius: 60)
                .position(x: 350, y: 100)

            Circle()
                .fill(Color.themeTertiary.opacity(0.05))
                .frame(width: 256, height: 256)
                .blur(radius: 50)
                .position(x: 50, y: 700)

            VStack(spacing: 0) {
                TopAppBar(title: "Appointments")

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 24) {
                        if !model.upcomingAppointments.isEmpty {
                            upcomingAppointmentsSection
                        }

                        if model.isLoadingProviders {
                            if model.upcomingAppointments.isEmpty {
                                loadingCard
                            }
                        } else if model.providers.isEmpty {
                            noProviderCard
                        } else {
                            providerInfoSection
                            calendarSection
                            timeSlotsSection
                            ctaSection
                        }

                        if let errorMessage = model.errorMessage {
                            Text(errorMessage)
                                .bodyText(size: 13, weight: .medium)
                                .foregroundStyle(Color.themeError)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(.horizontal, 8)
                        }

                        Spacer().frame(height: 120)
                    }
                    .padding(.horizontal, 24)
                    .padding(.top, 24)
                }
            }
        }
        .task(id: session.currentUserId) {
            guard let patientId = session.currentUserId else { return }
            model.start(patientId: patientId)
        }
        .onDisappear { model.stop() }
        /// If we want patients te be able to have multiple providers
        .onChange(of: model.selectedProviderId) { _, _ in
            selectedSlot = nil
            selectedDate = Date()
            visibleMonth = calendar.dateInterval(of: .month, for: Date())?.start ?? Date()
        }
        .alert("Appointment Confirmed", isPresented: $showConfirmation) {
            Button("Done", role: .cancel) { }
        } message: {
            if let confirmedSlot {
                Text("You're scheduled with \(model.selectedProvider?.displayName ?? "your provider") on \(Self.confirmationFormatter.string(from: confirmedSlot.startAt)).")
            }
        }
    }

    private var loadingCard: some View {
        HStack(spacing: 14) {
            ProgressView().tint(.themePrimary)
            Text("Loading your care team…")
                .bodyText(size: 15, weight: .medium)
                .foregroundStyle(Color.themeOnSurfaceVariant)
            Spacer()
        }
        .padding(24)
        .glassCard()
    }

    private var noProviderCard: some View {
        VStack(spacing: 14) {
            Image(systemName: "person.crop.circle.badge.questionmark")
                .font(.system(size: 42))
                .foregroundStyle(Color.themePrimary)
            Text("No provider connected yet")
                .headlineText(size: 20, weight: .bold)
                .foregroundStyle(Color.themeOnSurface)
            Text("Once a provider connects with your account, their available appointments will appear here.")
                .bodyText(size: 14)
                .foregroundStyle(Color.themeOnSurfaceVariant)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(28)
        .glassCard()
    }

    private var upcomingAppointmentsSection: some View {
        VStack(alignment: .leading, spacing: 18) {
            HStack {
                VStack(alignment: .leading, spacing: 3) {
                    Text("UPCOMING")
                        .font(.system(size: 10, weight: .bold))
                        .tracking(1.1)
                        .foregroundStyle(Color.themePrimary)
                    Text("Your Appointments")
                        .headlineText(size: 21, weight: .bold)
                        .foregroundStyle(Color.themeOnSurface)
                }
                Spacer()
                Image(systemName: "calendar.badge.clock")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundStyle(Color.themePrimary)
                    .frame(width: 42, height: 42)
                    .background(Color.themePrimaryContainer.opacity(0.3), in: Circle())
            }

            ForEach(Array(model.upcomingAppointments.prefix(3).enumerated()), id: \.offset) { index, appointment in
                if index > 0 {
                    Divider().opacity(0.45)
                }
                upcomingAppointmentRow(appointment)
            }
        }
        .padding(24)
        .glassCard()
    }

    private func upcomingAppointmentRow(_ appointment: Appointment) -> some View {
        HStack(spacing: 15) {
            VStack(spacing: 1) {
                Text(Self.appointmentMonthFormatter.string(from: appointment.startAt).uppercased())
                    .font(.system(size: 10, weight: .bold))
                    .foregroundStyle(Color.themePrimary)
                Text(Self.appointmentDayFormatter.string(from: appointment.startAt))
                    .headlineText(size: 24, weight: .heavy)
                    .foregroundStyle(Color.themeOnSurface)
            }
            .frame(width: 52, height: 58)
            .background(Color.themePrimaryContainer.opacity(0.22), in: RoundedRectangle(cornerRadius: 12))

            VStack(alignment: .leading, spacing: 4) {
                Text(appointment.providerName)
                    .bodyText(size: 15, weight: .bold)
                    .foregroundStyle(Color.themeOnSurface)
                Text(Self.appointmentDateFormatter.string(from: appointment.startAt))
                    .bodyText(size: 13)
                    .foregroundStyle(Color.themeOnSurfaceVariant)
                HStack(spacing: 5) {
                    Image(systemName: "clock")
                    Text(Self.timeFormatter.string(from: appointment.startAt))
                    if let duration = appointment.durationMinutes {
                        Text("• \(duration) min")
                    }
                }
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(Color.themePrimary)
            }

            Spacer(minLength: 0)
        }
    }

    private var providerInfoSection: some View {
        HStack(spacing: 20) {
            ZStack(alignment: .bottomTrailing) {
                Image(systemName: "person.crop.circle.fill")
                    .resizable()
                    .frame(width: 80, height: 80)
                    .foregroundStyle(Color.themeSurfaceContainerHighest)
                    .background(Circle().fill(Color.white).padding(-4))

                Circle()
                    .fill(Color.themeTertiary)
                    .frame(width: 20, height: 20)
                    .overlay(Circle().stroke(Color.white, lineWidth: 2))
            }

            VStack(alignment: .leading, spacing: 5) {
                Text("YOUR PRACTITIONER")
                    .bodyText(size: 12, weight: .semibold)
                    .foregroundStyle(Color.themeSecondary)
                    .tracking(1)

                if model.providers.count > 1 {
                    Menu {
                        ForEach(model.providers) { provider in
                            Button(provider.displayName) {
                                model.selectProvider(provider.providerId)
                            }
                        }
                    } label: {
                        HStack(spacing: 6) {
                            Text(model.selectedProvider?.displayName ?? "Select provider")
                                .headlineText(size: 23, weight: .heavy)
                            Image(systemName: "chevron.down")
                                .font(.system(size: 12, weight: .bold))
                        }
                        .foregroundStyle(Color.themeOnSurface)
                    }
                } else {
                    Text(model.selectedProvider?.displayName ?? "Your provider")
                        .headlineText(size: 23, weight: .heavy)
                        .foregroundStyle(Color.themeOnSurface)
                }

                let details = model.selectedProvider?.professionalDetails ?? ""
                if !details.isEmpty {
                    Text(details)
                        .bodyText(size: 14)
                        .foregroundStyle(Color.themeOnSurfaceVariant.opacity(0.8))
                }
            }

            Spacer(minLength: 0)
        }
        .padding(24)
        .glassEffect(
            .regular.tint(Color.themeSurface.opacity(0.2)).interactive(),
            in: .rect(cornerRadius: DS.Radius.lg)
        )
        .shadow(
            color: DS.Shadow.card.color,
            radius: DS.Shadow.card.radius,
            x: DS.Shadow.card.x,
            y: DS.Shadow.card.y
        )
    }

    private var calendarSection: some View {
        VStack(spacing: 16) {
            HStack {
                Text(Self.monthFormatter.string(from: visibleMonth))
                    .headlineText(size: 20, weight: .bold)
                    .foregroundStyle(Color.themeOnSurface)
                Spacer()
                Button { moveMonth(by: -1) } label: {
                    Image(systemName: "chevron.left")
                        .frame(width: 36, height: 36)
                }
                .buttonStyle(.plain)
                .foregroundStyle(Color.themeOnSurface)

                Button { moveMonth(by: 1) } label: {
                    Image(systemName: "chevron.right")
                        .frame(width: 36, height: 36)
                }
                .buttonStyle(.plain)
                .foregroundStyle(Color.themeOnSurface)
            }

            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 7), spacing: 8) {
                ForEach(weekdaySymbols, id: \.self) { day in
                    Text(day)
                        .bodyText(size: 10, weight: .semibold)
                        .foregroundStyle(Color.themeOnSurfaceVariant.opacity(0.6))
                }

                ForEach(Array(monthCells.enumerated()), id: \.offset) { _, date in
                    if let date {
                        calendarDay(date)
                    } else {
                        Color.clear.aspectRatio(1, contentMode: .fit)
                    }
                }
            }
        }
        .padding(24)
        .glassCard()
    }

    private func calendarDay(_ date: Date) -> some View {
        let isSelected = calendar.isDate(date, inSameDayAs: selectedDate)
        let hasAvailability = !model.availableSlots(on: date).isEmpty
        let isPast = calendar.compare(date, to: Date(), toGranularity: .day) == .orderedAscending

        return Button {
            selectedDate = date
            selectedSlot = nil
        } label: {
            ZStack(alignment: .bottom) {
                Text("\(calendar.component(.day, from: date))")
                    .bodyText(size: 14, weight: isSelected ? .bold : .regular)
                    .foregroundStyle(isSelected ? Color.white : Color.themeOnSurface)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background {
                        if isSelected {
                            Circle()
                                .fill(Color.themeSecondary)
                                .shadow(color: Color.themeSecondary.opacity(0.2), radius: 10, y: 5)
                        }
                    }

                if hasAvailability && !isSelected {
                    Circle()
                        .fill(Color.themeTertiary)
                        .frame(width: 5, height: 5)
                        .padding(.bottom, 2)
                }
            }
            .aspectRatio(1, contentMode: .fit)
            .opacity(isPast ? 0.35 : 1)
        }
        .buttonStyle(.plain)
        .disabled(isPast)
    }

    private var timeSlotsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                VStack(alignment: .leading, spacing: 3) {
                    Text("Available Times")
                        .headlineText(size: 18, weight: .bold)
                    Text(Self.dayFormatter.string(from: selectedDate))
                        .bodyText(size: 13)
                        .foregroundStyle(Color.themeOnSurfaceVariant)
                }
                Spacer()
                if model.isLoadingAvailability {
                    ProgressView().tint(.themePrimary)
                }
            }
            .padding(.horizontal, 8)

            let slots = model.availableSlots(on: selectedDate)
            if !model.isLoadingAvailability && slots.isEmpty {
                Text("No appointments are available on this day. Days with openings have a dot beneath the date.")
                    .bodyText(size: 14)
                    .foregroundStyle(Color.themeOnSurfaceVariant)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: .infinity)
                    .padding(24)
                    .glassCard()
            } else {
                LazyVGrid(
                    columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())],
                    spacing: 14
                ) {
                    ForEach(slots) { slot in
                        slotButton(slot)
                    }
                }
            }
        }
    }

    private func slotButton(_ slot: BookableAppointmentSlot) -> some View {
        let isSelected = selectedSlot?.id == slot.id

        return Button {
            selectedSlot = slot
        } label: {
            VStack(spacing: 3) {
                Text(Self.timeFormatter.string(from: slot.startAt))
                    .bodyText(size: 14, weight: isSelected ? .bold : .medium)
                Text("\(slot.durationMinutes) min")
                    .font(.system(size: 10, weight: .medium))
                    .opacity(0.75)
            }
            .foregroundStyle(isSelected ? Color.white : Color.themeOnSurface)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 13)
            .background {
                if isSelected {
                    Color.primaryGradient
                } else {
                    Color.themeSurface.opacity(0.7).background(.ultraThinMaterial)
                }
            }
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.white.opacity(0.4), lineWidth: 1)
            )
            .shadow(
                color: isSelected ? Color.themePrimary.opacity(0.2) : .clear,
                radius: 10,
                y: 5
            )
        }
        .buttonStyle(.plain)
    }

    private var ctaSection: some View {
        VStack(spacing: 14) {
            Button {
                guard let selectedSlot else { return }
                model.book(slot: selectedSlot) { success in
                    guard success else { return }
                    confirmedSlot = selectedSlot
                    self.selectedSlot = nil
                    showConfirmation = true
                    UINotificationFeedbackGenerator().notificationOccurred(.success)
                }
            } label: {
                HStack(spacing: 10) {
                    if model.isBooking {
                        ProgressView().tint(.white)
                    }
                    Text(model.isBooking ? "Scheduling…" : "Schedule Appointment")
                        .headlineText(size: 18, weight: .bold)
                }
                .foregroundStyle(Color.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 20)
                .background(Color.primaryGradient)
                .clipShape(Capsule())
                .shadow(color: Color.themePrimary.opacity(0.15), radius: 20, y: 10)
            }
            .buttonStyle(.plain)
            .disabled(selectedSlot == nil || model.isBooking)
            .opacity(selectedSlot == nil ? 0.45 : 1)

            if let selectedSlot {
                Text("\(selectedSlot.durationMinutes)-minute session • Ends at \(Self.timeFormatter.string(from: selectedSlot.endAt))")
                    .bodyText(size: 12)
                    .foregroundStyle(Color.themeOnSurfaceVariant.opacity(0.7))
            } else {
                Text("Choose an available time to continue")
                    .bodyText(size: 12)
                    .foregroundStyle(Color.themeOnSurfaceVariant.opacity(0.6))
            }
        }
        .padding(.top, 8)
    }

    private var monthCells: [Date?] {
        guard let dayRange = calendar.range(of: .day, in: .month, for: visibleMonth),
              let firstDay = calendar.date(from: calendar.dateComponents([.year, .month], from: visibleMonth)) else {
            return []
        }

        let leadingBlanks = calendar.component(.weekday, from: firstDay) - 1
        let days = dayRange.compactMap { day in
            calendar.date(byAdding: .day, value: day - 1, to: firstDay)
        }
        return Array(repeating: nil, count: leadingBlanks) + days.map(Optional.some)
    }

    private func moveMonth(by value: Int) {
        guard let month = calendar.date(byAdding: .month, value: value, to: visibleMonth) else { return }
        visibleMonth = month
        selectedSlot = nil
    }

    private static let monthFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"
        return formatter
    }()

    private static let dayFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE, MMMM d"
        return formatter
    }()

    private static let timeFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter
    }()

    private static let confirmationFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .full
        formatter.timeStyle = .short
        return formatter
    }()

    private static let appointmentMonthFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM"
        return formatter
    }()

    private static let appointmentDayFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "d"
        return formatter
    }()

    private static let appointmentDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE, MMMM d"
        return formatter
    }()
}

@MainActor
final class PatientSchedulingViewModel: ObservableObject {
    @Published private(set) var providers: [PatientProviderConnection] = []
    @Published private(set) var upcomingAppointments: [Appointment] = []
    @Published private(set) var selectedProviderId: String?
    @Published private(set) var availability: [TherapistAvailability] = []
    @Published private(set) var reservedSlotIds: Set<String> = []
    @Published private(set) var isLoadingProviders = true
    @Published private(set) var isLoadingAppointments = true
    @Published private(set) var isLoadingAvailability = false
    @Published private(set) var isBooking = false
    @Published var errorMessage: String?

    private let service = PatientSchedulingDataService.shared
    private var patientId: String?
    private var providerListener: ListenerRegistration?
    private var appointmentListener: ListenerRegistration?
    private var availabilityListener: ListenerRegistration?
    private var reservationListener: ListenerRegistration?

    var selectedProvider: PatientProviderConnection? {
        providers.first { $0.providerId == selectedProviderId }
    }

    var availableSlots: [BookableAppointmentSlot] {
        guard let therapistId = selectedProviderId else { return [] }
        let now = Date()

        return availability.flatMap { block in
            guard let availabilityId = block.id else { return [BookableAppointmentSlot]() }
            return block.bookableStartTimes.map { startAt in
                BookableAppointmentSlot(
                    therapistId: therapistId,
                    availabilityId: availabilityId,
                    startAt: startAt,
                    durationMinutes: block.effectiveSessionDurationMinutes,
                    bufferMinutes: block.effectiveBufferMinutes
                )
            }
        }
        .filter { $0.startAt > now && !reservedSlotIds.contains($0.id) }
        .sorted { $0.startAt < $1.startAt }
    }

    func start(patientId: String) {
        stop()
        self.patientId = patientId
        isLoadingProviders = true
        isLoadingAppointments = true
        errorMessage = nil

        appointmentListener = service.observeAppointments(patientId: patientId) { [weak self] appointments, error in
            DispatchQueue.main.async {
                guard let self else { return }
                self.isLoadingAppointments = false
                if let error {
                    self.errorMessage = error.localizedDescription
                } else {
                    self.upcomingAppointments = appointments
                }
            }
        }

        providerListener = service.observeProviders(patientId: patientId) { [weak self] providers, error in
            DispatchQueue.main.async {
                guard let self else { return }
                self.isLoadingProviders = false
                if let error {
                    self.errorMessage = error.localizedDescription
                    return
                }

                self.providers = providers
                let currentStillExists = providers.contains { $0.providerId == self.selectedProviderId }
                if !currentStillExists {
                    self.selectedProviderId = providers.first?.providerId
                    self.observeSelectedProvider()
                }
            }
        }
    }

    func stop() {
        providerListener?.remove()
        appointmentListener?.remove()
        availabilityListener?.remove()
        reservationListener?.remove()
        providerListener = nil
        appointmentListener = nil
        availabilityListener = nil
        reservationListener = nil
    }

    func selectProvider(_ providerId: String) {
        guard providerId != selectedProviderId else { return }
        selectedProviderId = providerId
        observeSelectedProvider()
    }

    func availableSlots(on date: Date) -> [BookableAppointmentSlot] {
        availableSlots.filter { Calendar.current.isDate($0.startAt, inSameDayAs: date) }
    }

    func book(slot: BookableAppointmentSlot, completion: @escaping (Bool) -> Void) {
        guard let patientId,
              slot.therapistId == selectedProviderId,
              let provider = selectedProvider else {
            errorMessage = "Please select a provider and appointment time."
            completion(false)
            return
        }

        isBooking = true
        errorMessage = nil
        service.book(
            slot: slot,
            patientId: patientId,
            providerName: provider.displayName
        ) { [weak self] result in
            DispatchQueue.main.async {
                guard let self else { return }
                self.isBooking = false
                switch result {
                case .success: /// remove slot from view
                    self.reservedSlotIds.insert(slot.id)
                    completion(true)
                case .failure(let error):
                    self.errorMessage = error.localizedDescription
                    completion(false)
                }
            }
        }
    }
    /// In case providers change
    private func observeSelectedProvider() {
        availabilityListener?.remove()
        reservationListener?.remove()
        availability = []
        reservedSlotIds = []

        guard let therapistId = selectedProviderId else {
            isLoadingAvailability = false
            return
        }

        isLoadingAvailability = true
        availabilityListener = service.observeAvailability(therapistId: therapistId) { [weak self] blocks, error in
            DispatchQueue.main.async {
                guard let self, self.selectedProviderId == therapistId else { return }
                self.isLoadingAvailability = false
                if let error {
                    self.errorMessage = error.localizedDescription
                } else {
                    self.availability = blocks
                }
            }
        }

        reservationListener = service.observeReservedSlots(therapistId: therapistId) { [weak self] slotIds, error in
            DispatchQueue.main.async {
                guard let self, self.selectedProviderId == therapistId else { return }
                if let error {
                    self.errorMessage = error.localizedDescription
                } else {
                    self.reservedSlotIds = slotIds
                }
            }
        }
    }
}
