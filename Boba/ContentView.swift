//
//  ContentView.swift
//  Boba
//
//  Created by Elijah Potter on 1/19/26.
//

import SwiftUI

struct ContentView: View {
    @State private var mood: Double = 5.0
    @State private var selectedEmotions: Set<String> = []
    @State private var notes: String = ""
    
    private let emotions: [(id: String, label: String, icon: String)] = [
        ("happy", "Happy", "face.smiling"),
        ("calm", "Calm", "wind"),
        ("stressed", "Stressed", "exclamationmark.triangle"),
        ("tired", "Tired", "moon.zzz"),
        ("motivated", "Motivated", "bolt.fill"),
        ("grateful", "Grateful", "hands.sparkles"),
        ("anxious", "Anxious", "waveform.path.ecg"),
        ("sad", "Sad", "cloud.drizzle.fill"),
        ("angry", "Angry", "flame.fill")
    ]
    
    var body: some View {
        TabView {
            // Tab 1: Check In
            ScrollView {
                VStack(spacing: 20) {
                    Text("How are you feeling?")
                        .font(.title)
                    
                    Text(mood < 4 ? "😔" : (mood < 7 ? "😐" : "😁"))
                        .font(.system(size: 80))
                    
                    Slider(value: $mood, in: 1...10, step: 1)
                        .tint(mood < 4 ? .blue : (mood < 7 ? .orange : .green))
                        .padding()
                    
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Emotions")
                            .font(.headline)
                        
                        LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 12), count: 3), spacing: 12) {
                            ForEach(emotions, id: \.id) { emotion in
                                let isSelected = selectedEmotions.contains(emotion.id)
                                Button {
                                    if isSelected {
                                        selectedEmotions.remove(emotion.id)
                                    } else {
                                        selectedEmotions.insert(emotion.id)
                                    }
                                } label: {
                                    HStack(spacing: 6) {
                                        Image(systemName: emotion.icon)
                                        Text(emotion.label)
                                    }
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 10)
                                    .foregroundStyle(isSelected ? .white : .primary)
                                    .background(
                                        RoundedRectangle(cornerRadius: 10)
                                            .fill(isSelected ? Color.accentColor : Color(.systemGray5))
                                    )
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal)
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Notes")
                            .font(.headline)
                        TextEditor(text: $notes)
                            .frame(minHeight: 120)
                            .padding(8)
                            .background(
                                RoundedRectangle(cornerRadius: 10)
                                    .fill(Color(.systemGray6))
                            )
                    }
                    .padding(.horizontal)
                    
                    Button("Log Check-in") {
                        // Logic to save to Firebase goes here later
                    }
                    .buttonStyle(.borderedProminent)
                    .padding(.bottom)
                }
            }
            .tabItem {
                Label("Check In", systemImage: "checkmark.circle.fill")
            }
            
            // Tab 2: Journal
            Text("Journal History List")
                .tabItem {
                    Label("Journal", systemImage: "book.fill")
                }
            
            // Tab 3: Calendar placeholder
            NavigationStack {
                CalendarView()
            }
            .tabItem {
                Label("Calendar", systemImage: "calendar")
            }
        }
    }
}

struct CalendarView: View {
    @State private var selectedDate = Date()

    var body: some View {
        VStack {
            DatePicker(
                "Select Date",
                selection: $selectedDate,
                displayedComponents: [.date]
            )
            .datePickerStyle(.graphical)
            .labelsHidden()
            .padding()

            Spacer()
        }
        .navigationTitle("Calendar")
    }
}

#Preview {
    ContentView()
    CalendarView()
}
