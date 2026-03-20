//
//  BobaApp.swift
//  Boba
//
//  Created by Elijah Potter on 1/19/26.
//

import SwiftUI
import FirebaseCore
import FirebaseFirestore

// connecting Boba to firebase
class AppDelegate: NSObject, UIApplicationDelegate {
  func application(_ application: UIApplication,
                   didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
    FirebaseApp.configure()
    return true
  }
}

@main
struct BobaApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
