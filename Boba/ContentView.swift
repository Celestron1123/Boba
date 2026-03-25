import SwiftUI

struct ContentView: View {
    @State private var selectedIndex: Int = 0

    var body: some View {
        ZStack {
            Group {
                switch selectedIndex {
                case 0:
                    HomeDashboardView()
                case 1:
                    AppointmentsView()
                case 2:
                    SecureChatView()
                case 3:
                    PatientProfileView()
                default:
                    HomeDashboardView()
                }
            }
        }
        .safeAreaInset(edge: .bottom) {
            BottomNavBar(selectedIndex: $selectedIndex)
                .padding(.bottom, 16)
        }
    }
}
#Preview {
    ContentView()
}
