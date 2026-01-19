//
//  ContentView.swift
//  Boba
//
//  Created by Elijah Potter on 1/19/26.
//

import SwiftUI

struct ContentView: View {
    @State private var mood: Double = 5.0
    
    var body: some View {
        TabView {
            // Tab 1: Check In
            VStack(spacing: 20) {
                Text("How are you feeling?")
                    .font(.title)
                
                Text(mood < 4 ? "😔" : (mood < 7 ? "😐" : "😁"))
                    .font(.system(size: 80))
                
                Slider(value: $mood, in: 1...10, step: 1)
                    .tint(mood < 4 ? .blue : (mood < 7 ? .orange : .green))
                    .padding()
                
                Button("Log Check-in") {
                    // Logic to save to Firebase goes here later
                }
                .buttonStyle(.borderedProminent)
            }
            .tabItem {
                Label("Track", systemImage: "checkmark.circle.fill")
            }
            
            // Tab 2: Journal
            Text("Journal History List")
                .tabItem {
                    Label("Journal", systemImage: "book.fill")
                }
        }
    }
}

#Preview {
    ContentView()
}
