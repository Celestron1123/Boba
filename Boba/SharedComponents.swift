import SwiftUI

struct TopAppBar: View {
    var title: String = "Good morning, Alex"
    
    var body: some View {
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
        .padding(.horizontal, 24)
        .padding(.vertical, 16)
        .background(
            Color.themeSurface.opacity(0.7)
                .background(.ultraThinMaterial)
        )
    }
}

struct BottomNavBar: View {
    @Binding var selectedIndex: Int
    
    var body: some View {
        HStack {
            ForEach(0..<4) { index in
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
        .background(
            Color.themeSurface.opacity(0.7)
                .background(.ultraThinMaterial)
                .clipShape(Capsule())
                .overlay(Capsule().stroke(Color.white.opacity(0.2), lineWidth: 1))
                .shadow(color: .black.opacity(0.1), radius: 20, x: 0, y: 10)
        )
        .padding(.horizontal, 20)
    }
    
    func iconName(for index: Int) -> String {
        switch index {
        case 0: return "house.fill"
        case 1: return "calendar"
        case 2: return "message.fill"
        case 3: return "person.fill"
        default: return "house.fill"
        }
    }
}

// Allows masking with specific rounded corners, e.g. chat bubbles
struct RoundedCornerStyle: Shape {
    var radius: CGFloat = .infinity
    var corners: UIRectCorner = .allCorners

    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(roundedRect: rect, byRoundingCorners: corners, cornerRadii: CGSize(width: radius, height: radius))
        return Path(path.cgPath)
    }
}
