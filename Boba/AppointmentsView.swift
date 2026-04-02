import SwiftUI

struct AppointmentsView: View {
    let days = ["MON", "TUE", "WED", "THU", "FRI", "SAT", "SUN"]
    let dates = Array(1...12)
    @State private var selectedDate = 3
    @State private var selectedTime = "10:00 AM"
    
    var body: some View {
        ZStack {
            Color.themeSurface.ignoresSafeArea()
            
            // Background accents
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
                TopAppBar()
                
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 24) {
                        providerInfoSection
                        
                        calendarSection
                        
                        timeSlotsSection
                        
                        ctaSection
                        
                        Spacer().frame(height: 120)
                    }
                    .padding(.horizontal, 24)
                    .padding(.top, 24)
                }
            }
        }
    }
    
    var providerInfoSection: some View {
        HStack(spacing: 20) {
            ZStack(alignment: .bottomTrailing) {
                Image(systemName: "person.crop.circle.fill")
                    .resizable()
                    .frame(width: 80, height: 80)
                    .foregroundColor(.themeSurfaceContainerHighest)
                    .background(Circle().fill(Color.white).padding(-4))
                
                Circle()
                    .fill(Color.themeTertiary)
                    .frame(width: 20, height: 20)
                    .overlay(Circle().stroke(Color.white, lineWidth: 2))
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text("YOUR PRACTITIONER")
                    .bodyText(size: 12, weight: .semibold)
                    .foregroundColor(.themeSecondary)
                    .tracking(1)
                
                Text("Dr. Smith")
                    .headlineText(size: 24, weight: .heavy)
                    .foregroundColor(.themeOnSurface)
                
                HStack(spacing: 8) {
                    Image(systemName: "rosette")
                        .font(.system(size: 14))
                    Text("Cognitive Behavioral Specialist")
                        .bodyText(size: 14)
                }
                .foregroundColor(.themeOnSurfaceVariant.opacity(0.8))
            }
            Spacer()
        }
        .padding(24)
        .glassEffect(.regular.tint(Color.themeSurface.opacity(0.2)).interactive(), in: .rect(cornerRadius: DS.Radius.lg))
        .shadow(color: DS.Shadow.card.color, radius: DS.Shadow.card.radius, x: DS.Shadow.card.x, y: DS.Shadow.card.y)
    }
    
    var calendarSection: some View {
        VStack(spacing: 16) {
            HStack {
                Text("October 2023")
                    .headlineText(size: 20, weight: .bold)
                Spacer()
                HStack(spacing: 16) {
                    Image(systemName: "chevron.left")
                    Image(systemName: "chevron.right")
                }
                .foregroundColor(.themeOnSurface)
            }
            
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 7), spacing: 8) {
                ForEach(days, id: \.self) { day in
                    Text(day)
                        .bodyText(size: 12, weight: .semibold)
                        .foregroundColor(.themeOnSurfaceVariant.opacity(0.6))
                }
                
                // Empty days
                ForEach(25...30, id: \.self) { day in
                    Text("\(day)")
                        .bodyText(size: 14)
                        .foregroundColor(.themeOnSurfaceVariant.opacity(0.2))
                        .frame(maxWidth: .infinity, alignment: .center)
                        .aspectRatio(1, contentMode: .fit)
                }
                
                // Actual days
                ForEach(dates, id: \.self) { date in
                    Text("\(date)")
                        .bodyText(size: 14, weight: date == selectedDate ? .bold : .regular)
                        .foregroundColor(date == selectedDate ? .white : .themeOnSurface)
                        .frame(maxWidth: .infinity, alignment: .center)
                        .aspectRatio(1, contentMode: .fit)
                        .background(
                            Group {
                                if date == selectedDate {
                                    Color.themeSecondary
                                        .clipShape(Circle())
                                        .shadow(color: .themeSecondary.opacity(0.2), radius: 10, x: 0, y: 5)
                                }
                            }
                        )
                        .onTapGesture {
                            selectedDate = date
                        }
                }
            }
        }
        .padding(24)
        .glassCard()
    }
    
    var timeSlotsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Available Time Slots")
                .headlineText(size: 18, weight: .bold)
                .padding(.horizontal, 8)
            
            let slots = ["09:00 AM", "10:00 AM", "11:30 AM", "01:30 PM", "03:00 PM"]
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
                ForEach(slots, id: \.self) { slot in
                    Button(action: {
                        selectedTime = slot
                    }) {
                        Text(slot)
                            .bodyText(size: 14, weight: selectedTime == slot ? .bold : .medium)
                            .foregroundColor(selectedTime == slot ? .white : .themeOnSurface)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(
                                Group {
                                    if selectedTime == slot {
                                        Color.primaryGradient
                                    } else {
                                        Color.themeSurface.opacity(0.7).background(.ultraThinMaterial)
                                    }
                                }
                            )
                            .cornerRadius(12)
                            .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.white.opacity(0.4), lineWidth: 1))
                            .shadow(color: selectedTime == slot ? .themePrimary.opacity(0.2) : .clear, radius: 10, x: 0, y: 5)
                    }
                }
                
                // Disabled slot
                Text("04:30 PM")
                    .bodyText(size: 14, weight: .medium)
                    .foregroundColor(.themeOnSurface)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                //                    .background(Color.themeSurface.opacity(0.7).background(.ultraThinMaterial))
                //                    .cornerRadius(12)
                    .glassEffect(.regular.tint(Color.themeSurface.opacity(0.2)).interactive(),
                                 in: .rect(cornerRadius: DS.Radius.md))
                    .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.white.opacity(0.4), lineWidth: 1))
                    .opacity(0.4)
            }
        }
    }
    
    var ctaSection: some View {
        VStack(spacing: 16) {
            Button(action: {}) {
                Text("Schedule Appointment")
                    .headlineText(size: 18, weight: .bold)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 20)
                    .background(Color.primaryGradient)
                    .clipShape(Capsule())
                    .shadow(color: .themePrimary.opacity(0.15), radius: 20, x: 0, y: 10)
            }
            
            Text("Standard 50-minute virtual session")
                .bodyText(size: 12)
                .foregroundColor(.themeOnSurfaceVariant.opacity(0.6))
        }
        .padding(.top, 8)
    }
}

