/**
 SharedComponents.swift
 
 Common UI components shared across screens (top app bar, bottom navigation, shapes).
 - Uses Liquid Glass for bars and surfaces
 - Applies design system tokens for elevation and consistency
 
 Last Updated: April 2, 2026
 */
import SwiftUI

// Top application bar with title and actions, styled with Liquid Glass
struct TopAppBar: View {
    var title: String = "Good morning, Alex"
    
    var body: some View {
        // Leading avatar, title, and trailing notification action
        HStack(spacing: 12) {
            Image(systemName: "person.circle.fill")
                .resizable()
                .frame(width: 40, height: 40)
                .foregroundColor(.themeSurfaceContainerHighest)
                .clipShape(Circle())
            
            Text(title)
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
