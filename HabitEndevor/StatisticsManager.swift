import SwiftUI
import SwiftData

// RecordsView에서 분리된 통계 계산 레이어.
// SwiftData @Query 결과를 받아 순수 함수로 계산 — 캐싱 가능, 테스트 가능.

struct StatisticsManager {

    // MARK: - 기본 통계

    static func checkedCount(from records: [HabitRecord]) -> Int {
        records.filter(\.isChecked).count
    }

    static func overallRate(from records: [HabitRecord]) -> Double {
        guard !records.isEmpty else { return 0 }
        return Double(checkedCount(from: records)) / Double(records.count)
    }

    static func bestLongestStreak(habits: [Habit]) -> Int {
        habits.map { StreakService.longestStreak(for: $0) }.max() ?? 0
    }

    // MARK: - 파이차트 데이터

    static func pieData(activeHabits: [Habit], records: [HabitRecord]) -> [PieItem] {
        let total = checkedCount(from: records)
        guard total > 0 else { return [] }
        return activeHabits.enumerated().compactMap { idx, habit in
            let count = StreakService.totalCheckedDays(for: habit)
            guard count > 0 else { return nil }
            let possible = habit.records.count
            return PieItem(
                id:         habit.persistentModelID.hashValue,
                index:      idx,
                habitName:  habit.name,
                habitColor: habit.displayColor,
                count:      count,
                rate:       possible > 0 ? Double(count) / Double(possible) : 0
            )
        }
    }

    // MARK: - 요일별 달성률 (캐싱 가능하도록 독립 함수)

    static func weekdayData(activeHabits: [Habit], records: [HabitRecord]) -> [WeekdayItem] {
        let labels     = ["월", "화", "수", "목", "금", "토", "일"]
        let components = [2, 3, 4, 5, 6, 7, 1]      // Calendar.weekday 매핑 (1=일)
        return zip(labels, components).map { label, comp in
            WeekdayItem(label: label, rate: weekdayRate(weekday: comp, habits: activeHabits, records: records))
        }
    }

    private static func weekdayRate(weekday: Int, habits: [Habit], records: [HabitRecord]) -> Double {
        guard !habits.isEmpty else { return 0 }
        let dayRecords = records.filter {
            Calendar.current.component(.weekday, from: $0.date) == weekday
        }
        let uniqueDates = Set(dayRecords.map(\.date))
        guard !uniqueDates.isEmpty else { return 0 }
        let sum = uniqueDates.reduce(0.0) { acc, date in
            let checked = dayRecords.filter { $0.date == date && $0.isChecked }.count
            return acc + Double(checked) / Double(habits.count)
        }
        return sum / Double(uniqueDates.count)
    }
}
