/**
 * ContentView.swift
 *
 * Overview: Acts as the authenticated root container for the app's primary
 * sections and keeps tab navigation in one place.
 *
 * Contains:
 * - Selection-based routing to the dashboard, logs, appointments, chat, and
 *   patient profile views.
 * - The custom bottom navigation bar anchored with a safe-area inset.
 *
 * Date: September 10, 2026
 * Attribution: BOBA t team
 * Copyright: Copyright © 2026 BOBA t. All rights reserved.
 */
import SwiftUI

/**
 A SwiftUI view that manages top-level navigation between major app areas.
 */
struct ContentView: View {
    // Tracks the currently selected tab index for the bottom navigation bar
    @State private var selectedIndex: Int = 0

    // Root layout: shows the selected section and overlays the bottom nav bar
    var body: some View {
        ZStack {
            Group {
                // Route to the appropriate top-level screen based on the selected tab
                switch selectedIndex {
                // Home dashboard
                case 0: HomeDashboardView()
                // Past logs
                case 1: DailyLogListView()
                // Appointments
                case 2: AppointmentsView()
                // Secure chat
                case 3: SecureChatView()
                // Patient profile
                case 4: PatientProfileView()
                // Fallback to home
                default: HomeDashboardView()
                }
            }
        }
        // Pin the custom bottom navigation to the safe area at the bottom
        .safeAreaInset(edge: .bottom) {
            // Two-way bind the selected index so taps update the displayed view
            BottomNavBar(selectedIndex: $selectedIndex)
                .padding(.bottom, 16)
        }
    }
}
// Preview for Xcode canvas
#Preview {
    ContentView()
}
