/**
 * BobaApp.swift
 *
 * Overview: Defines the application entry point and initializes the services
 * needed before the Boba interface is displayed.
 *
 * Contains:
 * - Firebase application configuration through the app delegate.
 * - Session-aware routing between authentication and the main application.
 * - Scene lifecycle handling for email verification refreshes.
 *
 * Date: September 10, 2026
 * Attribution: BOBA t team
 * Copyright: Copyright © 2026 BOBA t. All rights reserved.
 */

import SwiftUI
import FirebaseCore
import FirebaseAuth

class AppDelegate: NSObject, UIApplicationDelegate {
    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        FirebaseApp.configure()
        return true
    }
}

@main
struct BobaApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate
    @StateObject var session = SessionManager()
    @Environment(\.scenePhase) private var scenePhase
    
    var body: some Scene {
        WindowGroup {
            Group {
                if session.isLoggedIn {
                    ContentView()
                } else {
                    NavigationStack {
                        LoginView()
                    }
                }
            }
            .environmentObject(session)
            .onChange(of: scenePhase) { _, newPhase in
                guard newPhase == .active else { return }
                session.refreshEmailVerificationStatus()
            }
        }
    }
}
