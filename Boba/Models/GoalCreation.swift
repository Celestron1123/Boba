//
//  GoalCreation.swift
//  Boba
//
//  Created by Julia Maia on 9/15/26.
//

import Foundation

struct GoalCreation: Identifiable, Codable {
    var id: UUID = UUID()
    var title: String = ""
    var systemImage: String = "target"
    var targetValue: Double = 1.0
    var unit: String = ""
    var isEnabled: Bool = true
}
