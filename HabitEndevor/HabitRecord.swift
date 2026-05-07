import Foundation
import SwiftData

@Model
final class HabitRecord {
    var date: Date          // startOfDay 정규화
    var isChecked: Bool
    var coinPaidAt: Date?   // nil=미지급, Date=지급완료
    var failureNote: String?
    var emotionTag: String?   // EmotionTag.rawValue
    var habit: Habit?

    init(date: Date, habit: Habit) {
        self.date = Calendar.current.startOfDay(for: date)
        self.isChecked = false
        self.coinPaidAt = nil
        self.habit = habit
    }
}
