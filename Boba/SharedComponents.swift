/**
 * SharedComponents.swift
 *
 * Overview: Provides reusable SwiftUI building blocks shared by the Boba app's
 * screens and navigation flows.
 *
 * Contains:
 * - The top application bar and bottom navigation bar.
 * - Shared cards, buttons, shapes, indicators, and supporting view helpers.
 * - Firestore-backed display details and styling based on the design system.
 *
 * Date: September 10, 2026
 * Attribution: BOBA t team
 * Copyright: Copyright © 2026 BOBA t. All rights reserved.
 */
import SwiftUI
import FirebaseFirestore

// Top application bar with title and actions, styled with Liquid Glass
struct TopAppBar: View {
    @EnvironmentObject private var session: SessionManager
    @State private var patientFirstName = ""

    var title: String? = nil
    
    var body: some View {
        // Leading avatar, title, and trailing notification action
        HStack(spacing: 12) {
            Image(systemName: "person.circle.fill")
                .resizable()
                .frame(width: 40, height: 40)
                .foregroundColor(.themeSurfaceContainerHighest)
                .clipShape(Circle())
            
            Text(displayedTitle)
                .headlineText(size: 24, weight: .bold)
                .foregroundColor(.themePrimary)
                .tracking(-0.5)
            
            Spacer()
            
            Button(action: {}) {
                Image(systemName: "bell.fill")
                    .foregroundColor(.themePrimary)
                    .font(.system(size: 24))
            }
        }
        // Comfortable hit-target padding for the bar
        .padding(.horizontal, 24)
        .padding(.vertical, 16)
        // Liquid Glass background spanning under the status bar
        .background(
            Color.themeSurface.opacity(0.7)
                .background(.ultraThinMaterial)
                .ignoresSafeArea(edges: .top)
        )
        .task(id: session.currentUserId) {
            loadPatientName()
        }
    }

    private var displayedTitle: String {
        if let title {
            return title
        }

        return patientFirstName.isEmpty
            ? "Good morning"
            : "Good morning, \(patientFirstName)"
    }

    private func loadPatientName() {
        guard let userID = session.currentUserId else {
            patientFirstName = ""
            return
        }

        Firestore.firestore()
            .collection("users")
            .document(userID)
            .getDocument { snapshot, _ in
                guard let data = snapshot?.data() else {
                    return
                }

                let firstName = data["firstName"] as? String
                    ?? data["username"] as? String
                    ?? ""

                DispatchQueue.main.async {
                    patientFirstName = firstName
                }
            }
    }
}

// Bottom navigation bar with four primary destinations
struct BottomNavBar: View {
    @Binding var selectedIndex: Int
    
    var body: some View {
        HStack {
            // Iterate icons and apply selected state styling
            ForEach(0..<5) { index in
                Spacer()
                Button(action: {
                    withAnimation(.spring()) {
                        selectedIndex = index
                    }
                }) {
                    Image(systemName: iconName(for: index))
                        .font(.system(size: 24, weight: selectedIndex == index ? .black : .regular))
                        .foregroundColor(selectedIndex == index ? .white : .themeOnSurface.opacity(0.5))
                        .frame(width: 56, height: 56)
                        .background(
                            Group {
                                if selectedIndex == index {
                                    Color.primaryGradient
                                        .clipShape(Circle())
                                        .shadow(color: .themePrimary.opacity(0.3), radius: 10, x: 0, y: 5)
                                } else {
                                    Color.clear
                                        .clipShape(Circle())
                                }
                            }
                        )
                }
                Spacer()
            }
        }
        .padding(.vertical, 8)
        // Liquid Glass capsule background with design system elevation
        .glassEffect(.regular.tint(Color.themeSurface.opacity(0.2)).interactive(), in: .capsule)
        .shadow(color: DS.Shadow.card.color, radius: DS.Shadow.card.radius, x: DS.Shadow.card.x, y: DS.Shadow.card.y)
        .padding(.horizontal, 20)
    }
    
    func iconName(for index: Int) -> String {
        switch index {
        case 0: return "house.fill"
        case 1: return "list.bullet"
        case 2: return "calendar"
        case 3: return "message.fill"
        case 4: return "person.fill"
        default: return "house.fill"
        }
    }
}

// Utility shape to round specific corners (for chat bubbles, tags, etc.)
struct RoundedCornerStyle: Shape {
    var radius: CGFloat = .infinity
    var corners: UIRectCorner = .allCorners

    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(roundedRect: rect, byRoundingCorners: corners, cornerRadii: CGSize(width: radius, height: radius))
        return Path(path.cgPath)
    }
}
