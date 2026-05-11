import Foundation

struct StreakService {

    // habit.records를 딱 한 번 읽어 세 값 동시 계산
    static func computeAll(for habit: Habit) -> (current: Int, longest: Int, total: Int) {
        let cal = Calendar.current
        let today = Date.todayStart
        let records = habit.records
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

        // longest streak — 🔴 버그 수정: sorted.count==0 → 1..<0 크래시
        var longest = sorted.isEmpty ? 0 : 1
        if sorted.count > 1 {
            var run = 1
            for i in 1..<sorted.count {
                let diff = cal.dateComponents([.day], from: sorted[i-1], to: sorted[i]).day ?? 0
                if diff == 1 { run += 1; longest = max(longest, run) }
                else if diff > 1 { run = 1 }
            }
        }

        return (current, longest, checkedDates.count)
    }

    // 하위 호환 래퍼
    static func currentStreak(for habit: Habit) -> Int    { computeAll(for: habit).current }
    static func longestStreak(for habit: Habit) -> Int    { computeAll(for: habit).longest }
    static func totalCheckedDays(for habit: Habit) -> Int { computeAll(for: habit).total   }
}
