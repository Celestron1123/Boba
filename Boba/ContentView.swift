import SwiftUI

struct ContentView: View {
    var body: some View {
        NavigationView {
            List {
                NavigationLink("Home Dashboard", destination: HomeDashboardView())
                NavigationLink("Appointments", destination: AppointmentsView())
                NavigationLink("Daily Log", destination: DailyLogView())
                NavigationLink("Secure Chat", destination: SecureChatView())
                NavigationLink("Patient Profile", destination: PatientProfileView())
            }
            .navigationTitle("Boba Therapy UI")
        }
    }
}
#Preview {
    ContentView()
}
