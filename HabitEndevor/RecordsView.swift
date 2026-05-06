import SwiftUI
import SwiftData
import Charts

struct RecordsView: View {
    @Query(sort: \Habit.sortOrder) private var habits: [Habit]
    @Query private var allRecords: [HabitRecord]

    private var activeHabits: [Habit] { habits.filter(\.isActive) }
    private var failureRecords: [HabitRecord] {
        allRecords
            .filter { $0.failureNote != nil }
            .sorted { $0.date > $1.date }
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                overallStatsCard
                habitStreakList
                weekdayChart
                if !failureRecords.isEmpty {
                    failureLogSection
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
        }
        .navigationTitle("기록")
    }

    // MARK: - 전체 통계 카드

    private var overallStatsCard: some View {
        HStack(spacing: 0) {
            statItem(icon: "", value: "\(totalCheckins)",           label: "총 체크인")
            Divider().frame(height: 40)
            statItem(icon: "", value: "\(bestCurrentStreak)일",    label: "최고 스트릭")
            Divider().frame(height: 40)
            statItem(icon: "", value: "\(Int(overallRate * 100))%", label: "전체 달성률")
        }
        .padding(.vertical, 16)
        .background(Color.primary.opacity(0.05))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private func statItem(icon _: String, value: String, label: String) -> some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.title2)
                .fontWeight(.bold)
            Text(label)
                .font(.caption2)
                .foregroundStyle(Color.secondary)
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - 습관별 스트릭 리스트

    private var habitStreakList: some View {
        VStack(alignment: .leading, spacing: 0) {
            sectionHeader("습관별 스트릭")

            ForEach(activeHabits) { habit in
                HabitStreakRow(habit: habit)
                if habit.persistentModelID != activeHabits.last?.persistentModelID {
                    Divider().padding(.leading, 16)
                }
            }
        }
        .background(Color.primary.opacity(0.05))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    // MARK: - 요일별 달성률 차트

    private var weekdayChart: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionHeader("요일별 달성률")

            Chart(weekdayData) { item in
                BarMark(
                    x: .value("요일", item.label),
                    y: .value("달성률", item.rate)
                )
                .foregroundStyle(Color.primary.opacity(0.8))
                .cornerRadius(4)
            }
            .chartYScale(domain: 0...1)
            .chartYAxis {
                AxisMarks(values: [0, 0.25, 0.5, 0.75, 1.0]) { value in
                    AxisGridLine()
                    AxisValueLabel {
                        if let v = value.as(Double.self) {
                            Text("\(Int(v * 100))%").font(.caption2)
                        }
                    }
                }
            }
            .frame(height: 160)
            .padding(.bottom, 8)
        }
        .padding(.horizontal, 16)
        .padding(.top, 16)
        .background(Color.primary.opacity(0.05))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    // MARK: - 실패 사유 로그

    private var failureLogSection: some View {
        VStack(alignment: .leading, spacing: 0) {
            sectionHeader("실패 사유 기록")

            ForEach(failureRecords) { record in
                if let note = record.failureNote, let habit = record.habit {
                    FailureLogRow(record: record, habit: habit, note: note)
                    Divider().padding(.leading, 16)
                }
            }
        }
        .background(Color.primary.opacity(0.05))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    // MARK: - Computed Stats

    private var totalCheckins: Int {
        allRecords.filter(\.isChecked).count
    }

    private var bestCurrentStreak: Int {
        activeHabits.map { StreakService.currentStreak(for: $0) }.max() ?? 0
    }

    private var overallRate: Double {
        let checked = allRecords.filter(\.isChecked).count
        let total = allRecords.count
        guard total > 0 else { return 0 }
        return Double(checked) / Double(total)
    }

    // 요일별 데이터 (월~일)
    private var weekdayData: [WeekdayItem] {
        let labels = ["월", "화", "수", "목", "금", "토", "일"]
        let weekdayComponents = [2, 3, 4, 5, 6, 7, 1] // Calendar.weekday (1=Sun)

        return zip(labels, weekdayComponents).map { label, component in
            let rate = weekdayRate(for: component)
            return WeekdayItem(label: label, rate: rate)
        }
    }

    private func weekdayRate(for weekdayComponent: Int) -> Double {
        guard !activeHabits.isEmpty else { return 0 }
        let dayRecords = allRecords.filter {
            Calendar.current.component(.weekday, from: $0.date) == weekdayComponent
        }
        let uniqueDates = Set(dayRecords.map(\.date))
        guard !uniqueDates.isEmpty else { return 0 }

        let totalRate = uniqueDates.reduce(0.0) { sum, date in
            let checked = dayRecords.filter { $0.date == date && $0.isChecked }.count
            return sum + Double(checked) / Double(activeHabits.count)
        }
        return totalRate / Double(uniqueDates.count)
    }

    private func sectionHeader(_ title: String) -> some View {
        Text(title)
            .font(.subheadline)
            .fontWeight(.semibold)
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
    }
}

// MARK: - Habit Streak Row

struct HabitStreakRow: View {
    let habit: Habit

    var body: some View {
        HStack {
            Text(habit.emoji)
            Text(habit.name)
                .font(.subheadline)
                .lineLimit(1)

            Spacer()

            HStack(spacing: 20) {
                VStack(alignment: .trailing, spacing: 2) {
                    Text("\(StreakService.currentStreak(for: habit))일")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                    Text("현재")
                        .font(.caption2)
                        .foregroundStyle(Color.secondary)
                }

                VStack(alignment: .trailing, spacing: 2) {
                    Text("\(StreakService.longestStreak(for: habit))일")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundStyle(Color.secondary)
                    Text("최장")
                        .font(.caption2)
                        .foregroundStyle(Color.secondary)
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
    }
}

// MARK: - Failure Log Row

struct FailureLogRow: View {
    let record: HabitRecord
    let habit: Habit
    let note: String

    private var dateLabel: String {
        let f = DateFormatter()
        f.locale = Locale(identifier: "ko_KR")
        f.dateFormat = "M월 d일 (E)"
        return f.string(from: record.date)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: 4) {
                Text(habit.emoji)
                    .font(.caption)
                Text(habit.name)
                    .font(.caption)
                    .fontWeight(.medium)
                Spacer()
                Text(dateLabel)
                    .font(.caption2)
                    .foregroundStyle(Color.secondary)
            }
            Text(note)
                .font(.subheadline)
                .foregroundStyle(Color.primary.opacity(0.8))
                .lineLimit(2)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
    }
}

// MARK: - Supporting Types

struct WeekdayItem: Identifiable {
    let id = UUID()
    let label: String
    let rate: Double
}

#Preview {
    NavigationStack {
        RecordsView()
    }
    .modelContainer(for: [Habit.self, HabitRecord.self], inMemory: true)
}
