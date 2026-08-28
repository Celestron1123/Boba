import SwiftUI

struct SecureChatView: View {
    @State private var messageText = ""
    
    var body: some View {
        ZStack {
            Color.themeSurface.ignoresSafeArea()
            
            // Background Decorations
            Circle()
                .fill(Color.themePrimaryContainer.opacity(0.1))
                .frame(width: 400, height: 400)
                .blur(radius: 120)
                .position(x: 50, y: 50)
            
            Circle()
                .fill(Color.themeSecondaryContainer.opacity(0.1))
                .frame(width: 300, height: 300)
                .blur(radius: 100)
                .position(x: 350, y: 400)
            
            Circle()
                .fill(Color.themeTertiaryContainer.opacity(0.1))
                .frame(width: 250, height: 250)
                .blur(radius: 80)
                .position(x: 100, y: 700)
            
            VStack(spacing: 0) {
                chatHeader
                
                ScrollView {
                    VStack(spacing: 24) {
                        Text("TODAY, OCT 24")
                            .font(.system(size: 10, weight: .bold))
                            .tracking(1)
                            .foregroundColor(.themeOnSurfaceVariant.opacity(0.7))
                            .padding(.horizontal, 16)
                            .padding(.vertical, 6)
                            .background(Color.themeSurfaceContainerHigh)
                            .clipShape(Capsule())
                            .padding(.top, 24)
                        
                        therapistMessage("Good morning, Alex. How are you feeling after our last session on grounding techniques? 🌿", time: "09:12 AM")
                        
                        patientMessage("I've been trying the 5-4-3-2-1 method when I feel overwhelmed at work. It really helps me stay in the moment.", time: "09:15 AM")
                        
                        therapistMessage("That's wonderful to hear. Consistency is key. Have you noticed any specific triggers during your workday that we should discuss in our next call?", time: "09:16 AM")
                        
                        patientMessage("Mostly early afternoon meetings. I feel like my breath gets shallow before I even enter the room.", time: "09:18 AM")
                        
                        secureIndicator
                        
                        therapistTypingIndicator
                        
                        Spacer().frame(height: 120)
                    }
                    .padding(.horizontal, 24)
                }
                
                chatInput
            }
        }
    }
    
    var chatHeader: some View {
        HStack(spacing: 16) {
            Button(action:{}) {
                Image(systemName: "arrow.left")
                    .font(.system(size: 20))
                    .foregroundColor(.themePrimary)
            }
            
            HStack(spacing: 12) {
                ZStack(alignment: .bottomTrailing) {
                    Image(systemName: "person.crop.circle.fill")
                        .resizable()
                        .frame(width: 48, height: 48)
                        .foregroundColor(.themeSurfaceContainerHighest)
                        .overlay(Circle().stroke(Color.themePrimaryContainer, lineWidth: 2))
                    
                    Circle()
                        .fill(Color.themeTertiary)
                        .frame(width: 12, height: 12)
                        .overlay(Circle().stroke(Color.themeSurface, lineWidth: 2))
                }
                
                VStack(alignment: .leading, spacing: 2) {
                    Text("Dr. Smith")
                        .headlineText(size: 18, weight: .bold)
                    
                    HStack(spacing: 4) {
                        Circle().fill(Color.themeTertiary).frame(width: 6, height: 6)
                        Text("Active now")
                            .bodyText(size: 12, weight: .medium)
                            .foregroundColor(.themeOnSurface.opacity(0.6))
                    }
                }
            }
            
            Spacer()
            
            HStack(spacing: 16) {
                Image(systemName: "video.fill").foregroundColor(.themePrimary)
                Image(systemName: "phone.fill").foregroundColor(.themePrimary)
                Image(systemName: "ellipsis").foregroundColor(.themePrimary)
            }
            .font(.system(size: 20))
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 16)
        .background(
            Color.themeSurface.opacity(0.7)
                .background(.ultraThinMaterial)
                .shadow(color: .themeOnSurface.opacity(0.06), radius: 32, x: 0, y: 12)
        )
    }
    
    func therapistMessage(_ text: String, time: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(text)
                .bodyText(size: 15, weight: .medium)
                .foregroundColor(.themeOnSurface)
                .padding(20)
                .background(
                    LinearGradient(colors: [Color.themeSecondary.opacity(0.1), Color.themeSecondary.opacity(0.05)], startPoint: .topLeading, endPoint: .bottomTrailing)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(Color.themeSecondary.opacity(0.1), lineWidth: 1)
                )
                .clipShape(
                    RoundedCornerStyle(radius: 20, corners: [.topLeft, .topRight, .bottomRight])
                )
            
            Text(time)
                .bodyText(size: 10, weight: .medium)
                .foregroundColor(.themeOnSurface.opacity(0.4))
                .padding(.leading, 4)
        }
        .padding(.trailing, 40)
    }
    
    func patientMessage(_ text: String, time: String) -> some View {
        VStack(alignment: .trailing, spacing: 8) {
            Text(text)
                .bodyText(size: 15, weight: .medium)
                .foregroundColor(.themeOnSurface)
                .padding(20)
                .background(
                    LinearGradient(colors: [Color.themePrimaryContainer.opacity(0.15), Color.themePrimaryContainer.opacity(0.05)], startPoint: .topLeading, endPoint: .bottomTrailing)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(Color.themePrimaryContainer.opacity(0.1), lineWidth: 1)
                )
                .clipShape(
                    RoundedCornerStyle(radius: 20, corners: [.topLeft, .topRight, .bottomLeft])
                )
            
            HStack(spacing: 6) {
                Text(time)
                    .bodyText(size: 10, weight: .medium)
                    .foregroundColor(.themeOnSurface.opacity(0.4))
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 14))
                    .foregroundColor(.themePrimary)
            }
            .padding(.trailing, 4)
        }
        .padding(.leading, 40)
        .frame(maxWidth: .infinity, alignment: .trailing)
    }
    
    var secureIndicator: some View {
        HStack(spacing: 8) {
            Rectangle().fill(Color.themeOutlineVariant.opacity(0.2)).frame(height: 1)
            HStack(spacing: 6) {
                Image(systemName: "lock.fill").font(.system(size: 14))
                Text("End-to-end encrypted")
                    .font(.system(size: 11, weight: .medium))
            }
            .foregroundColor(.themeOnSurfaceVariant.opacity(0.5))
            Rectangle().fill(Color.themeOutlineVariant.opacity(0.2)).frame(height: 1)
        }
        .padding(.vertical, 16)
    }
    
    var therapistTypingIndicator: some View {
        HStack(spacing: 12) {
            HStack(spacing: 6) {
                Circle().fill(Color.themeSecondary.opacity(0.4)).frame(width: 6, height: 6)
                Circle().fill(Color.themeSecondary.opacity(0.4)).frame(width: 6, height: 6)
                Circle().fill(Color.themeSecondary.opacity(0.4)).frame(width: 6, height: 6)
            }
            .padding(12)
            .background(Color.themeSurfaceContainerLow)
            .clipShape(Capsule())
            .shadow(color: .black.opacity(0.05), radius: 5)
            
            Text("Dr. Smith is typing...")
                .font(.system(size: 11, weight: .semibold))
                .foregroundColor(.themeSecondary.opacity(0.6))
            
            Spacer()
        }
    }
    
    var chatInput: some View {
        HStack(spacing: 12) {
            Button(action:{}) {
                Image(systemName: "plus.circle")
                    .font(.system(size: 24))
                    .foregroundColor(.themeOnSurfaceVariant)
            }
            
            HStack {
                TextField("Type your message...", text: $messageText)
                    .font(.system(size: 15, weight: .medium))
                    .foregroundColor(.themeOnSurface)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(Color.themeSurfaceContainerHigh.opacity(0.5))
            .clipShape(Capsule())
            
            Button(action:{}) {
                Image(systemName: "mic")
                    .font(.system(size: 20))
                    .foregroundColor(.themeOnSurfaceVariant)
            }
            
            Button(action:{}) {
                Image(systemName: "paperplane.fill")
                    .font(.system(size: 20))
                    .foregroundColor(.white)
                    .frame(width: 48, height: 48)
                    .background(Color.primaryGradient)
                    .clipShape(Circle())
                    .shadow(radius: 10)
            }
        }
        .padding(16)
        .background(
            Color.themeSurface.opacity(0.7)
                .background(.ultraThinMaterial)
                .clipShape(Capsule())
                .overlay(Capsule().stroke(Color.white.opacity(0.2), lineWidth: 1))
                .shadow(color: .black.opacity(0.08), radius: 40, x: 0, y: 20)
        )
        .padding(.horizontal, 24)
        .padding(.bottom, 16)
    }
}
