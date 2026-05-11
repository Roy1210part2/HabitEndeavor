import SwiftUI
import SwiftData
import Charts

struct RecordsView: View {
    @Query(sort: \Habit.sortOrder) private var habits: [Habit]
    @Query private var allRecords: [HabitRecord]

    @State private var showWeeklyReview = false

    // 🟠 캐시: computed property 매 렌더 실행 → onChange 시만 재계산
    @State private var cachedCheckins:    Int    = 0
    @State private var cachedBestStreak:  Int    = 0
    @State private var cachedOverallRate: Double = 0
    @State private var cachedPieData:     [PieItem]     = []
    @State private var cachedWeekdayData: [WeekdayItem] = []

    private var activeHabits: [Habit] { habits.filter(\.isActive) }
    private var failureRecords: [HabitRecord] {
        allRecords
            .filter { $0.failureNote != nil }
            .sorted { $0.date > $1.date }
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                weeklyReviewButton
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
        .sheet(isPresented: $showWeeklyReview) {
            WeeklyReviewSheet(habits: activeHabits, allRecords: allRecords)
        }
        .onAppear { recompute() }
        .onChange(of: allRecords) { _, _ in recompute() }
        .onChange(of: habits)     { _, _ in recompute() }
    }

    private func recompute() {
        let active = activeHabits
        cachedCheckins    = StatisticsManager.checkedCount(from: allRecords)
        cachedBestStreak  = StatisticsManager.bestLongestStreak(habits: active)
        cachedOverallRate = StatisticsManager.overallRate(from: allRecords)
        cachedPieData     = StatisticsManager.pieData(activeHabits: active, records: allRecords)
        cachedWeekdayData = StatisticsManager.weekdayData(activeHabits: active, records: allRecords)
    }

    // MARK: - Weekly Review Button

    private var weeklyReviewButton: some View {
        Button {
            showWeeklyReview = true
        } label: {
            HStack(spacing: 14) {
                Image(systemName: "chart.line.uptrend.xyaxis")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(Color.primary)
                    .frame(width: 42, height: 42)
                    .background(Color.primary.opacity(0.08))
                    .clipShape(RoundedRectangle(cornerRadius: 12))

                VStack(alignment: .leading, spacing: 3) {
                    Text("주간 리뷰")
                        .font(.system(.subheadline, design: .rounded))
                        .fontWeight(.bold)
                        .foregroundStyle(Color.primary)
                    Text("이번 주 성과를 한눈에 확인해요")
                        .font(.system(size: 11, design: .rounded))
                        .foregroundStyle(Color.secondary)
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(Color.secondary)
            }
            .padding(14)
            .cardBackground()
        }
        .buttonStyle(.plain)
    }

    // MARK: - 전체 통계 카드

    private var overallStatsCard: some View {
        HStack(spacing: 0) {
            statItem(value: "\(totalCheckins)",             label: "총 습관 성공")
            Divider().frame(height: 44)
            statItem(value: "\(bestLongestStreak)일",      label: "최장 연속기록")
            Divider().frame(height: 44)
            statItem(value: "\(Int(overallRate * 100))%",  label: "전체 달성률")
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
                Text("습관을 추가하고 습관을 성공하면 차트가 나타납니다.")
                    .font(.subheadline)
                    .foregroundStyle(Color.secondary)
                    .padding(.horizontal, 16)
                    .padding(.bottom, 16)
            } else {
                HStack(alignment: .center, spacing: 20) {
                    // 각 습관의 displayColor로 파이 조각 색상 결정
                    Chart(pieChartData) { item in
                        SectorMark(
                            angle: .value("습관 성공", item.count),
                            innerRadius: .ratio(0.48),
                            angularInset: 2.5
                        )
                        .cornerRadius(4)
                        .foregroundStyle(item.habitColor)
                    }
                    .frame(width: 160, height: 160)

                    VStack(alignment: .leading, spacing: 8) {
                        ForEach(pieChartData) { item in
                            HStack(spacing: 8) {
                                RoundedRectangle(cornerRadius: 3)
                                    .fill(item.habitColor)
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
            sectionHeader("습관별 연속기록 & 성공률")

            ForEach(activeHabits) { habit in
                HabitStreakRow(habit: habit)
                if habit.persistentModelID != activeHabits.last?.persistentModelID {
                    Divider().padding(.leading, 16)
                }
            }
        }
        .cardBackground()
    }

    // MARK: - 요일별 달성률 차트 (의미 기반 색상: 70%+ 초록, 미만 빨강)

    private var weekdayChart: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionHeader("요일별 달성률")

            Chart(weekdayData) { item in
                BarMark(
                    x: .value("요일", item.label),
                    y: .value("달성률", item.rate)
                )
                .foregroundStyle(rateColor(item.rate))
                .cornerRadius(5)
                .annotation(position: .top) {
                    if item.rate > 0 {
                        Text("\(Int(item.rate * 100))%")
                            .font(.system(size: 9, weight: .medium))
                            .foregroundStyle(Color.secondary)
                    }
                }

                // 70% 목표 기준선
                RuleMark(y: .value("목표", 0.7))
                    .foregroundStyle(Color.primary.opacity(0.25))
                    .lineStyle(StrokeStyle(lineWidth: 1.5, dash: [5, 3]))
                    .annotation(position: .trailing, alignment: .leading) {
                        Text("70%")
                            .font(.system(size: 9))
                            .foregroundStyle(Color.secondary)
                    }
            }
            .chartYScale(domain: 0...1)
            .chartYAxis {
                AxisMarks(values: [0, 0.5, 1.0]) { value in
                    AxisGridLine()
                    AxisValueLabel {
                        if let v = value.as(Double.self) {
                            Text("\(Int(v * 100))%").font(.caption)
                        }
                    }
                }
            }
            .frame(height: 200)
            .padding(.bottom, 8)
        }
        // Collab #4: 카드 배경 제거 → 투명 + 좌우 패딩만으로 시각적 숨 트임
        .padding(.horizontal, 16)
        .padding(.vertical, 16)
    }

    private func rateColor(_ rate: Double) -> Color {
        // 0% = 빨강, 70%+ = 초록, 그 사이 보간
        let t = min(rate / 0.7, 1.0)
        return Color(
            red:   0.95 - 0.77 * t,
            green: 0.23 + 0.57 * t,
            blue:  0.23 - 0.02 * t
        )
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

    // MARK: - Computed Stats (캐시 참조 — recompute()에서만 갱신)

    private var totalCheckins:     Int    { cachedCheckins    }
    private var bestLongestStreak: Int    { cachedBestStreak  }
    private var overallRate:       Double { cachedOverallRate }
    private var pieChartData:      [PieItem]     { cachedPieData     }
    private var weekdayData:       [WeekdayItem] { cachedWeekdayData }

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

    var body: some View {
        // computeAll로 habit.records 단 1회 접근 (기존 3회 → 1회)
        let s = StreakService.computeAll(for: habit)
        let recordCount = habit.records.count
        let rate = recordCount > 0 ? Double(s.total) / Double(recordCount) : 0.0

        return HStack(spacing: 12) {
            RoundedRectangle(cornerRadius: 2)
                .fill(habit.displayColor)
                .frame(width: 3, height: 24)
            Text(habit.name)
                .font(.body)
                .lineLimit(1)

            Spacer()

            HStack(spacing: 20) {
                VStack(alignment: .trailing, spacing: 3) {
                    Text("\(Int(rate * 100))%")
                        .font(.body)
                        .fontWeight(.semibold)
                    Text("성공률")
                        .font(.caption)
                        .foregroundStyle(Color.secondary)
                }
                VStack(alignment: .trailing, spacing: 3) {
                    Text("\(s.current)일")
                        .font(.body)
                        .fontWeight(.semibold)
                    Text("현재")
                        .font(.caption)
                        .foregroundStyle(Color.secondary)
                }
                VStack(alignment: .trailing, spacing: 3) {
                    Text("\(s.longest)일")
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

// MARK: - Failure Log Row (Collab #3: 인용구 스타일)

struct FailureLogRow: View {
    let record: HabitRecord
    let habit: Habit
    let note: String

    private var dateLabel: String {
        let f = DateFormatter()
        f.locale = Locale(identifier: "ko_KR")
        f.dateFormat = "M.d (E)"
        return f.string(from: record.date)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            // 헤더: 습관명 + 날짜
            HStack(spacing: 8) {
                RoundedRectangle(cornerRadius: 2)
                    .fill(habit.displayColor)
                    .frame(width: 3, height: 14)
                Text(habit.name)
                    .font(.system(.caption, design: .rounded))
                    .fontWeight(.semibold)
                    .foregroundStyle(habit.displayColor)
                Spacer()
                Text(dateLabel)
                    .font(.system(size: 11, design: .rounded))
                    .foregroundStyle(Color.secondary)
            }

            // 인용구 스타일 본문
            HStack(alignment: .top, spacing: 10) {
                Text("\u{201C}")
                    .font(.system(size: 32, weight: .black, design: .serif))
                    .foregroundStyle(habit.displayColor.opacity(0.3))
                    .offset(y: -4)

                Text(note)
                    .font(.system(.subheadline, design: .rounded))
                    .foregroundStyle(Color.primary.opacity(0.75))
                    .lineLimit(3)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
    }
}

// MARK: - Card Background Modifier

extension View {
    func cardBackground() -> some View {
        self
            .background(.ultraThinMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .stroke(Color.primary.opacity(0.05), lineWidth: 1)
            )
            .shadow(color: .black.opacity(0.03), radius: 10, x: 0, y: 4)
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
    let habitColor: Color
    let count: Int
    let rate: Double
}

#Preview {
    NavigationStack {
        RecordsView()
    }
    .modelContainer(for: [Habit.self, HabitRecord.self], inMemory: true)
}
