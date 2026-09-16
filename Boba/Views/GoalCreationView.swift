//
//  GoalCreationView.swift
//  Boba
//
//  Created by Julia Maia on 9/15/26.
//

import SwiftUI

struct GoalCreationView: View {
    @Environment(\.dismiss) private var dismiss
    
    @State private var newGoal = GoalCreation()
    var onSave: (GoalCreation) -> Void

    let iconOptions = ["drop.fill", "bed.double.fill", "figure.run", "brain.head.profile", "flame.fill", "leaf.fill"]
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Goal Details") {
                    TextField("Title (e.g., Exercise)", text: $newGoal.title)
                }
                
                Section("Target Defaults") {
                    HStack(spacing: 12) {
                        TextField("Target", value: $newGoal.targetValue, format: .number)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                                        
                        TextField("Unit (e.g., mins)", text: $newGoal.unit)
                    }
                }
                
                Section("Icon Picker") {
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 6), spacing: 12) {
                        ForEach(iconOptions, id: \.self) { icon in
                            Image(systemName: icon)
                                .font(.title2)
                                .padding(8)
                                .background(newGoal.systemImage == icon ? Color.themePrimary.opacity(0.2) : Color.clear)
                                .clipShape(Circle())
                                .onTapGesture {
                                    newGoal.systemImage = icon
                                }
                        }
                    }
                    .padding(.vertical, 8)
                }
            }
            .navigationTitle("Create Custom Goal")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        onSave(newGoal)
                        dismiss()
                    }
                    .disabled(newGoal.title.isEmpty || newGoal.unit.isEmpty)
                }
            }
        }
    }
}
