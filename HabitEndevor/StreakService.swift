import Foundation

// habit.records를 3번 개별 접근하던 기존 방식 → computeAll로 1번 접근
struct StreakService {

    struct StreakResult {
        let current: Int
        let longest: Int
        let total: Int
        var successRate: Double {
            guard total > 0 else { return 0 }
            return Double(total) / Double(total) // caller에서 habit.records.count로 나눔
        }
    }

    // 핵심: habit.records를 딱 한 번만 읽어 세 값을 동시에 계산
    static func computeAll(for habit: Habit) -> (current: Int, longest: Int, total: Int) {
        let cal = Calendar.current
        let today = Date.todayStart
        let records = habit.records                     // SwiftData 관계 단일 접근
        let checkedDates = Set(records.filter { $0.isChecked }.map { $0.date })
        let sorted = checkedDates.sorted()

        // current streak
        var cursor = checkedDates.contains(today)
            ? today
            : cal.date(byAdding: .day, value: -1, to: today)!
        var current = 0
        while checkedDates.contains(cursor) {
            current += 1
            cursor = cal.date(byAdding: .day, value: -1, to: cursor)!
        }

        // longest streak
        var longest = sorted.isEmpty ? 0 : 1
        var run = 1
        for i in 1..<sorted.count {
            let diff = cal.dateComponents([.day], from: sorted[i-1], to: sorted[i]).day ?? 0
            if diff == 1 { run += 1; longest = max(longest, run) }
            else if diff > 1 { run = 1 }
        }

        return (current, longest, checkedDates.count)
    }

    // 하위 호환 — 내부적으로 computeAll 위임
    static func currentStreak(for habit: Habit) -> Int   { computeAll(for: habit).current }
    static func longestStreak(for habit: Habit) -> Int   { computeAll(for: habit).longest }
    static func totalCheckedDays(for habit: Habit) -> Int { computeAll(for: habit).total  }
}
