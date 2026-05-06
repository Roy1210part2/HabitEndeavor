import Foundation

struct StreakService {
    static func currentStreak(for habit: Habit) -> Int {
        let calendar = Calendar.current
        let today = Date.todayStart
        let checkedDates = Set(habit.records.filter { $0.isChecked }.map { $0.date })

        // 오늘 체크 안 됐으면 어제부터 카운트
        var cursor = checkedDates.contains(today)
            ? today
            : calendar.date(byAdding: .day, value: -1, to: today)!

        var streak = 0
        while checkedDates.contains(cursor) {
            streak += 1
            cursor = calendar.date(byAdding: .day, value: -1, to: cursor)!
        }
        return streak
    }

    static func longestStreak(for habit: Habit) -> Int {
        let dates = habit.records
            .filter { $0.isChecked }
            .map { $0.date }
            .sorted()

        guard !dates.isEmpty else { return 0 }

        let calendar = Calendar.current
        var longest = 1
        var current = 1

        for i in 1..<dates.count {
            let diff = calendar.dateComponents([.day], from: dates[i - 1], to: dates[i]).day ?? 0
            if diff == 1 {
                current += 1
                longest = max(longest, current)
            } else if diff > 1 {
                current = 1
            }
        }
        return longest
    }

    static func totalCheckedDays(for habit: Habit) -> Int {
        habit.records.filter { $0.isChecked }.count
    }
}
