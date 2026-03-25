import SwiftUI

struct PatientProfileView: View {
    var body: some View {
        ZStack {
            Color.themeSurface.ignoresSafeArea()
            
            VStack(spacing: 0) {
                TopAppBar()
                
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 24) {
                        heroSection
                        
                        currentProviderCard
                        emergencyContactCard
                        medicationsCard
                        diagnosesCard
                        
                        Spacer().frame(height: 120)
                    }
                    .padding(.horizontal, 24)
                    .padding(.top, 24)
                }
            }
        }
    }
    
    var heroSection: some View {
        HStack(alignment: .bottom, spacing: 24) {
            ZStack(alignment: .bottomTrailing) {
                Image(systemName: "person.crop.rectangle.fill")
                    .resizable()
                    .frame(width: 120, height: 120)
                    .foregroundColor(.themeSurfaceContainerHighest)
                    .cornerRadius(16)
                    .shadow(radius: 10)
                
                Circle()
                    .fill(Color.themeTertiaryContainer)
                    .frame(width: 16, height: 16)
                    .overlay(Circle().stroke(Color.white, lineWidth: 2))
                    .offset(x: 8, y: 8)
            }
            
            VStack(alignment: .leading, spacing: 8) {
                Text("Alex Johnson")
                    .headlineText(size: 32, weight: .heavy)
                    .foregroundColor(.themeOnSurface)
                
                Text("Birthday: April 12, 1994")
                    .bodyText(size: 16, weight: .medium)
                    .foregroundColor(.themeOnSurfaceVariant)
                
                HStack {
                    Text("Patient ID: #BOBA-9921")
                        .bodyText(size: 12, weight: .semibold)
                        .foregroundColor(.themePrimary)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 6)
                        .background(Color.themeSurfaceContainerHighest)
                        .clipShape(Capsule())
                    
                    HStack(spacing: 4) {
                        Image(systemName: "checkmark.seal.fill")
                        Text("Verified Account")
                    }
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(.themeOnTertiaryContainer)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 6)
                    .background(Color.themeTertiaryContainer.opacity(0.2))
                    .clipShape(Capsule())
                }
            }
            Spacer()
        }
        .padding(.top, 16)
    }
    
    var currentProviderCard: some View {
        VStack(spacing: 24) {
            HStack {
                Text("Current Provider")
                    .headlineText(size: 20, weight: .bold)
                    .foregroundColor(.themePrimary)
                Spacer()
                Button("Change") { }
                    .bodyText(size: 14, weight: .bold)
                    .foregroundColor(.themePrimary)
            }
            
            HStack(alignment: .top, spacing: 24) {
                Image(systemName: "person.crop.square.fill")
                    .resizable()
                    .frame(width: 96, height: 96)
                    .foregroundColor(.themeSurfaceContainerHighest)
                    .cornerRadius(12)
                
                VStack(alignment: .leading, spacing: 8) {
                    Text("Dr. Sarah Chen, PhD")
                        .headlineText(size: 18, weight: .bold)
                        .foregroundColor(.themeOnSurface)
                    
                    Text("Clinical Psychologist • CBT Specialist")
                        .bodyText(size: 14)
                        .foregroundColor(.themeOnSurfaceVariant)
                    
                    HStack {
                        Image(systemName: "calendar.badge.clock")
                            .foregroundColor(.themeTertiary)
                        Text("Next Session: Friday, 10:00 AM")
                            .bodyText(size: 14, weight: .medium)
                    }
                    .padding(.vertical, 4)
                    
                    HStack(spacing: 8) {
                        Button("Message") { }
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(.white)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(Color.themePrimary)
                            .clipShape(Capsule())
                        
                        Button("View Notes") { }
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(.themeOnSurface)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(Color.themeSurfaceContainerHighest)
                            .clipShape(Capsule())
                    }
                }
                Spacer()
            }
        }
        .padding(32)
        .glassCard()
        .overlay(RoundedRectangle(cornerRadius: 24).stroke(Color.white.opacity(0.2), lineWidth: 1))
    }
    
    var emergencyContactCard: some View {
        VStack(alignment: .leading, spacing: 24) {
            HStack(spacing: 12) {
                Circle()
                    .fill(Color.themeSecondary)
                    .frame(width: 40, height: 40)
                    .overlay(Image(systemName: "staroflife.fill").foregroundColor(.white))
                
                Text("Emergency Contact")
                    .headlineText(size: 20, weight: .bold)
                    .foregroundColor(.themeOnSecondaryContainer)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text("Mark Johnson")
                    .headlineText(size: 18, weight: .bold)
                Text("Relationship: Brother")
                    .bodyText(size: 16)
                    .foregroundColor(.themeOnSurfaceVariant)
                Text("+1 (555) 012-3456")
                    .bodyText(size: 16, weight: .medium)
                    .foregroundColor(.themeOnSurfaceVariant)
                    .padding(.top, 8)
            }
            
            Button("Update Contact") {}
                .bodyText(size: 14, weight: .bold)
                .foregroundColor(.themeSecondary)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(Color.white.opacity(0.5))
                .cornerRadius(12)
                .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.themeSecondary.opacity(0.2), lineWidth: 1))
        }
        .padding(32)
        .background(Color.themeSecondaryContainer.opacity(0.3))
        .cornerRadius(24)
    }
    
    var medicationsCard: some View {
        VStack(spacing: 24) {
            HStack {
                Text("Medications")
                    .headlineText(size: 20, weight: .bold)
                    .foregroundColor(.themePrimary)
                Spacer()
                Image(systemName: "pills.fill")
                    .foregroundColor(.themePrimaryContainer)
            }
            
            VStack(spacing: 16) {
                medicationRow(name: "Prozac", details: "20mg • Daily in Morning", status: "ACTIVE", statusColor: .themeTertiary)
                medicationRow(name: "Melatonin", details: "5mg • Before Sleep", status: "AS NEEDED", statusColor: .themeOnSurfaceVariant.opacity(0.6))
            }
            
            Button("+ Add Medication") {}
                .bodyText(size: 14, weight: .medium)
                .foregroundColor(.themeOnSurfaceVariant)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .overlay(RoundedRectangle(cornerRadius: 12).strokeBorder(style: StrokeStyle(lineWidth: 2, dash: [5])).foregroundColor(.themeOutlineVariant))
        }
        .padding(32)
        .glassCard()
        .overlay(RoundedRectangle(cornerRadius: 24).stroke(Color.white.opacity(0.2), lineWidth: 1))
    }
    
    func medicationRow(name: String, details: String, status: String, statusColor: Color) -> some View {
        HStack(spacing: 16) {
            Circle()
                .fill(Color.themePrimaryContainer.opacity(0.3))
                .frame(width: 48, height: 48)
                .overlay(Image(systemName: "pill.fill").foregroundColor(.themePrimary))
            
            VStack(alignment: .leading, spacing: 4) {
                Text(name)
                    .bodyText(size: 16, weight: .bold)
                Text(details)
                    .bodyText(size: 12)
                    .foregroundColor(.themeOnSurfaceVariant)
            }
            Spacer()
            
            Text(status)
                .font(.system(size: 10, weight: .bold))
                .tracking(1)
                .foregroundColor(statusColor)
        }
        .padding(16)
        .background(Color.white.opacity(0.4))
        .cornerRadius(12)
    }
    
    var diagnosesCard: some View {
        VStack(spacing: 24) {
            HStack {
                Text("Diagnoses")
                    .headlineText(size: 20, weight: .bold)
                    .foregroundColor(.themePrimary)
                Spacer()
                Image(systemName: "doc.text.fill")
                    .foregroundColor(.themePrimaryContainer)
            }
            
            HStack(spacing: 12) {
                diagnosisTag(name: "General Anxiety Disorder", date: "Confirmed Oct 2023")
                diagnosisTag(name: "Mild Insomnia", date: "Confirmed Jan 2024")
                diagnosisTag(name: "Social Anxiety", date: "Self-Reported")
                Spacer()
            }
            
            HStack(alignment: .top, spacing: 12) {
                Image(systemName: "info.circle.fill")
                    .foregroundColor(.themeTertiary)
                Text("Your diagnoses are only visible to you and your assigned provider to ensure personalized care.")
                    .bodyText(size: 12)
                    .foregroundColor(.themeOnTertiaryContainer)
            }
            .padding(16)
            .background(Color.themeTertiaryContainer.opacity(0.1))
            .cornerRadius(12)
            .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.themeTertiaryContainer.opacity(0.2), lineWidth: 1))
        }
        .padding(32)
        .glassCard()
        .overlay(RoundedRectangle(cornerRadius: 24).stroke(Color.white.opacity(0.2), lineWidth: 1))
    }
    
    func diagnosisTag(name: String, date: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(name)
                .bodyText(size: 14, weight: .bold)
                .fixedSize(horizontal: false, vertical: true)
            Text(date)
                .bodyText(size: 10)
                .foregroundColor(.themeOnSurfaceVariant)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
        .background(Color.themeSurfaceContainerLow)
        .cornerRadius(12)
        .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.themeOutlineVariant.opacity(0.1), lineWidth: 1))
    }
}

