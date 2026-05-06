import Foundation
import SwiftData

@Model
final class Habit {
    var name: String
    var emoji: String       // 내 아이디어: 습관별 이모지 (예: 🏃 📚 🧘)
    var sortOrder: Int      // 내 아이디어: 순서 변경 지원
    var createdAt: Date
    var isActive: Bool
    @Relationship(deleteRule: .cascade) var records: [HabitRecord]

    init(name: String, emoji: String = "✅", sortOrder: Int = 0) {
        self.name = name
        self.emoji = emoji
        self.sortOrder = sortOrder
        self.createdAt = Date()
        self.isActive = true
        self.records = []
    }

    var thisWeekCompletionRate: Double {
        guard !records.isEmpty else { return 0 }
        let checked = records.filter { $0.isChecked }.count
        return Double(checked) / Double(records.count)
    }
}
