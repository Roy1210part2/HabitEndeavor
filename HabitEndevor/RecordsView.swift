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
                habitPieSection
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
            statItem(value: "\(totalCheckins)",            label: "총 체크인")
            Divider().frame(height: 44)
            statItem(value: "\(bestCurrentStreak)일",     label: "최고 스트릭")
            Divider().frame(height: 44)
            statItem(value: "\(Int(overallRate * 100))%", label: "전체 달성률")
        }
        .padding(.vertical, 20)
        .cardBackground()
    }

    private func statItem(value: String, label: String) -> some View {
        VStack(spacing: 6) {
            Text(value)
                .font(.title)
                .fontWeight(.bold)
            Text(label)
                .font(.caption)
                .foregroundStyle(Color.secondary)
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - 습관 비율 파이차트

    private var habitPieSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionHeader("습관 비율")

            if pieChartData.isEmpty {
                Text("습관을 추가하고 체크인하면 차트가 나타납니다.")
                    .font(.subheadline)
                    .foregroundStyle(Color.secondary)
                    .padding(.horizontal, 16)
                    .padding(.bottom, 16)
            } else {
                HStack(alignment: .center, spacing: 20) {
                    Chart(pieChartData) { item in
                        SectorMark(
                            angle: .value("체크인", item.count),
                            innerRadius: .ratio(0.48),
                            angularInset: 2.5
                        )
                        .cornerRadius(4)
                        .foregroundStyle(
                            item.index % 2 == 0
                                ? Color.primary.opacity(0.85)
                                : Color.primary.opacity(0.4)
                        )
                    }
                    .frame(width: 160, height: 160)

                    VStack(alignment: .leading, spacing: 8) {
                        ForEach(pieChartData) { item in
                            HStack(spacing: 8) {
                                RoundedRectangle(cornerRadius: 3)
                                    .fill(item.index % 2 == 0
                                        ? Color.primary.opacity(0.85)
                                        : Color.primary.opacity(0.4))
                                    .frame(width: 10, height: 10)
                                VStack(alignment: .leading, spacing: 1) {
                                    Text(item.habitName)
                                        .font(.caption)
                                        .fontWeight(.medium)
                                        .lineLimit(1)
                                    Text("\(item.count)일 · \(Int(item.rate * 100))%")
                                        .font(.caption2)
                                        .foregroundStyle(Color.secondary)
                                }
                            }
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 16)
            }
        }
        .cardBackground()
    }

    // MARK: - 습관별 스트릭 리스트

    private var habitStreakList: some View {
        VStack(alignment: .leading, spacing: 0) {
            sectionHeader("습관별 스트릭 & 성공률")

            ForEach(activeHabits) { habit in
                HabitStreakRow(habit: habit)
                if habit.persistentModelID != activeHabits.last?.persistentModelID {
                    Divider().padding(.leading, 16)
                }
            }
        }
        .cardBackground()
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
                .cornerRadius(5)
            }
            .chartYScale(domain: 0...1)
            .chartYAxis {
                AxisMarks(values: [0, 0.25, 0.5, 0.75, 1.0]) { value in
                    AxisGridLine()
                    AxisValueLabel {
                        if let v = value.as(Double.self) {
                            Text("\(Int(v * 100))%").font(.caption)
                        }
                    }
                }
            }
            .frame(height: 180)
            .padding(.bottom, 8)
        }
        .padding(.horizontal, 16)
        .padding(.top, 16)
        .cardBackground()
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
        .cardBackground()
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

    private var pieChartData: [PieItem] {
        let totalChecked = allRecords.filter(\.isChecked).count
        guard totalChecked > 0 else { return [] }
        return activeHabits.enumerated().compactMap { idx, habit in
            let count = StreakService.totalCheckedDays(for: habit)
            guard count > 0 else { return nil }
            let totalPossible = habit.records.count
            let rate = totalPossible > 0 ? Double(count) / Double(totalPossible) : 0
            return PieItem(
                id: habit.persistentModelID.hashValue,
                index: idx,
                habitName: habit.name,
                count: count,
                rate: rate
            )
        }
    }

    private var weekdayData: [WeekdayItem] {
        let labels = ["월", "화", "수", "목", "금", "토", "일"]
        let weekdayComponents = [2, 3, 4, 5, 6, 7, 1]
        return zip(labels, weekdayComponents).map { label, component in
            WeekdayItem(label: label, rate: weekdayRate(for: component))
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
            .font(.body)
            .fontWeight(.semibold)
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
    }
}

// MARK: - Habit Streak Row

struct HabitStreakRow: View {
    let habit: Habit

    private var successRate: Double {
        let total = habit.records.count
        guard total > 0 else { return 0 }
        return Double(StreakService.totalCheckedDays(for: habit)) / Double(total)
    }

    var body: some View {
        HStack(spacing: 12) {
            Text(habit.emoji)
                .font(.body)
            Text(habit.name)
                .font(.body)
                .lineLimit(1)

            Spacer()

            HStack(spacing: 20) {
                VStack(alignment: .trailing, spacing: 3) {
                    Text("\(Int(successRate * 100))%")
                        .font(.body)
                        .fontWeight(.semibold)
                    Text("성공률")
                        .font(.caption)
                        .foregroundStyle(Color.secondary)
                }

                VStack(alignment: .trailing, spacing: 3) {
                    Text("\(StreakService.currentStreak(for: habit))일")
                        .font(.body)
                        .fontWeight(.semibold)
                    Text("현재")
                        .font(.caption)
                        .foregroundStyle(Color.secondary)
                }

                VStack(alignment: .trailing, spacing: 3) {
                    Text("\(StreakService.longestStreak(for: habit))일")
                        .font(.body)
                        .fontWeight(.medium)
                        .foregroundStyle(Color.secondary)
                    Text("최장")
                        .font(.caption)
                        .foregroundStyle(Color.secondary)
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
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
        VStack(alignment: .leading, spacing: 5) {
            HStack(spacing: 5) {
                Text(habit.emoji)
                    .font(.footnote)
                Text(habit.name)
                    .font(.footnote)
                    .fontWeight(.medium)
                Spacer()
                Text(dateLabel)
                    .font(.caption)
                    .foregroundStyle(Color.secondary)
            }
            Text(note)
                .font(.body)
                .foregroundStyle(Color.primary.opacity(0.8))
                .lineLimit(2)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }
}

// MARK: - Card Background Modifier

extension View {
    func cardBackground() -> some View {
        #if os(iOS)
        self
            .background(Color(.systemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 14))
            .shadow(color: .black.opacity(0.06), radius: 8, x: 0, y: 2)
        #else
        self
            .background(Color(.windowBackgroundColor))
            .clipShape(RoundedRectangle(cornerRadius: 14))
            .shadow(color: .black.opacity(0.09), radius: 8, x: 0, y: 2)
        #endif
    }
}

// MARK: - Supporting Types

struct WeekdayItem: Identifiable {
    let id = UUID()
    let label: String
    let rate: Double
}

struct PieItem: Identifiable {
    let id: Int
    let index: Int
    let habitName: String
    let count: Int
    let rate: Double
}

#Preview {
    NavigationStack {
        RecordsView()
    }
    .modelContainer(for: [Habit.self, HabitRecord.self], inMemory: true)
}
