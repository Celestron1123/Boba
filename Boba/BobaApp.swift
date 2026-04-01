//
//  BobaApp.swift
//  Boba
//
//  Created by Elijah Potter on 1/19/26.
//

import SwiftUI
import FirebaseCore
import FirebaseFirestore
import FirebaseAuth

// connecting Boba to firebase
class AppDelegate: NSObject, UIApplicationDelegate {
    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        FirebaseApp.configure()
        // Simple one-liner for testing in simulator
        Auth.auth().signInAnonymously { authResult, error in
            if let user = authResult?.user {
                print("Signed in anonymously with ID: \(user.uid)")
            }
        }
        return true
    }
}

@main
struct BobaApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
