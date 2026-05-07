import Foundation
import SwiftData
import SwiftUI

@Model
final class Habit {
    var name: String
    var emoji: String
    var sortOrder: Int
    var createdAt: Date
    var isActive: Bool
    var colorHex: String?   // optional for migration compat
    @Relationship(deleteRule: .cascade) var records: [HabitRecord]

    init(name: String, emoji: String = "⭐️", sortOrder: Int = 0, colorHex: String? = nil) {
        self.name = name
        self.emoji = emoji
        self.sortOrder = sortOrder
        self.createdAt = Date()
        self.isActive = true
        self.colorHex = colorHex
        self.records = []
    }

    var displayColor: Color {
        guard let hex = colorHex, let c = Color(hex: hex) else { return .blue }
        return c
    }

    var thisWeekCompletionRate: Double {
        guard !records.isEmpty else { return 0 }
        let checked = records.filter { $0.isChecked }.count
        return Double(checked) / Double(records.count)
    }
}
