import SwiftUI
import SwiftData
import Charts

struct RecordsView: View {
    @Query(sort: \Habit.sortOrder) private var habits: [Habit]
    @Query private var allRecords: [HabitRecord]

    @State private var showWeeklyReview = false

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
    }

    // MARK: - Weekly Review Button

    private var weeklyReviewButton: some View {
        Button {
            showWeeklyReview = true
        } label: {
            HStack {
                Image(systemName: "calendar.badge.checkmark")
                    .font(.title3)
                    .foregroundStyle(.white)
                    .frame(width: 42, height: 42)
                    .background(
                        LinearGradient(colors: [Color(hex: "#74B9FF") ?? .blue,
                                                Color(hex: "#5352ED") ?? .indigo],
                                       startPoint: .topLeading, endPoint: .bottomTrailing)
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 10))

                VStack(alignment: .leading, spacing: 2) {
                    Text("주간 리뷰 보기")
                        .font(.system(.subheadline, design: .rounded))
                        .fontWeight(.semibold)
                        .foregroundStyle(Color.primary)
                    Text("이번 주 성과를 한눈에 확인해요")
                        .font(.system(size: 11, design: .rounded))
                        .foregroundStyle(Color.secondary)
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.caption)
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
            statItem(value: "\(totalCheckins)",            label: "총 습관 성공")
            Divider().frame(height: 44)
            statItem(value: "\(bestCurrentStreak)일",     label: "최고 연속기록")
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
        .padding(.horizontal, 16)
        .padding(.top, 16)
        .cardBackground()
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
                habitColor: habit.displayColor,
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
            RoundedRectangle(cornerRadius: 2)
                .fill(habit.displayColor)
                .frame(width: 3, height: 24)
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
            HStack(spacing: 8) {
                RoundedRectangle(cornerRadius: 2)
                    .fill(habit.displayColor)
                    .frame(width: 3, height: 14)
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

// MARK: - Weekly Review (Wrapped 스타일)

private let motivationalMessages: [String] = [
    "작은 습관이 큰 삶을 만든다.\n오늘도 한 걸음 앞으로.",
    "포기하지 않는 것 자체가\n이미 성공이야.",
    "매일 1%씩 나아지면\n1년 후엔 37배 성장해있어.",
    "습관은 두 번째 본성이다.\n넌 지금 그것을 만들고 있어.",
    "완벽하지 않아도 괜찮아.\n그냥 계속하는 것이 전부야.",
    "오늘의 작은 노력이\n내일의 큰 차이를 만든다.",
]

struct WeeklyReviewSheet: View {
    @Environment(\.dismiss) private var dismiss
    let habits: [Habit]
    let allRecords: [HabitRecord]

    @State private var page = 0

    private let cal = Calendar.current

    private var thisWeekDates: [Date] {
        let today = Date.todayStart
        let daysFromMon = (cal.component(.weekday, from: today) + 5) % 7
        return (0...daysFromMon).compactMap {
            cal.date(byAdding: .day, value: -$0, to: today)
        }.reversed()
    }

    private var lastWeekDates: [Date] {
        guard let mon = thisWeekDates.first else { return [] }
        return (1...7).compactMap { cal.date(byAdding: .day, value: -$0, to: mon) }.reversed()
    }

    private func habitRate(_ habit: Habit, dates: [Date]) -> Double {
        guard !dates.isEmpty else { return 0 }
        let recs = allRecords.filter { $0.habit?.persistentModelID == habit.persistentModelID }
        let checked = dates.filter { d in recs.first { $0.date == d }?.isChecked == true }.count
        return Double(checked) / Double(dates.count)
    }

    private func overallRate(dates: [Date]) -> Double {
        guard !habits.isEmpty, !dates.isEmpty else { return 0 }
        let sum = habits.reduce(0.0) { $0 + habitRate($1, dates: dates) }
        return sum / Double(habits.count)
    }

    private var thisRate: Double { overallRate(dates: thisWeekDates) }
    private var lastRate: Double { overallRate(dates: lastWeekDates) }
    private var delta: Double    { thisRate - lastRate }

    private var bestHabit: Habit? {
        habits.max { habitRate($0, dates: thisWeekDates) < habitRate($1, dates: thisWeekDates) }
    }
    private var worstHabit: Habit? {
        habits.min { habitRate($0, dates: thisWeekDates) < habitRate($1, dates: thisWeekDates) }
    }

    private var motivationMsg: String {
        if thisRate >= 0.8 { return motivationalMessages[0] }
        if thisRate >= 0.5 { return motivationalMessages[Int.random(in: 1...3)] }
        return motivationalMessages[Int.random(in: 4...5)]
    }

    private let pageCount = 5

    private let gradients: [[Color]] = [
        [Color(hex: "#5352ED") ?? .indigo, Color(hex: "#A29BFE") ?? .purple],
        [Color(hex: "#00B894") ?? .green,  Color(hex: "#55EFC4") ?? .mint],
        [Color(hex: "#E17055") ?? .orange, Color(hex: "#FDCB6E") ?? .yellow],
        [Color(hex: "#0984E3") ?? .blue,   Color(hex: "#74B9FF") ?? .cyan],
        [Color(hex: "#6C5CE7") ?? .purple, Color(hex: "#FD79A8") ?? .pink],
    ]

    var body: some View {
        ZStack {
            LinearGradient(
                colors: gradients[page],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            .animation(.easeInOut(duration: 0.4), value: page)

            VStack(spacing: 0) {
                // 진행 도트
                HStack(spacing: 6) {
                    ForEach(0..<pageCount, id: \.self) { i in
                        Capsule()
                            .fill(.white.opacity(i == page ? 1 : 0.35))
                            .frame(width: i == page ? 20 : 6, height: 6)
                            .animation(.spring(response: 0.3), value: page)
                    }
                }
                .padding(.top, 20)
                .padding(.bottom, 8)

                // 페이지 콘텐츠
                TabView(selection: $page) {
                    ComparisonPage(thisRate: thisRate, lastRate: lastRate, delta: delta, weekLabel: weekRangeLabel).tag(0)
                    HabitSpotlightPage(title: "이번 주 MVP 🏆", subtitle: "가장 잘한 습관",
                                       habit: bestHabit, rate: bestHabit.map { habitRate($0, dates: thisWeekDates) } ?? 0).tag(1)
                    HabitSpotlightPage(title: "조금 아쉬웠어 💪", subtitle: "더 노력할 습관",
                                       habit: worstHabit, rate: worstHabit.map { habitRate($0, dates: thisWeekDates) } ?? 0).tag(2)
                    WeeklyChartPage(habits: habits, thisWeekDates: thisWeekDates, allRecords: allRecords).tag(3)
                    MotivationPage(message: motivationMsg, rate: thisRate).tag(4)
                }
                #if os(iOS)
                .tabViewStyle(.page(indexDisplayMode: .never))
                #endif
                .animation(.easeInOut(duration: 0.35), value: page)

                // 이전 / 다음 버튼
                HStack(spacing: 12) {
                    if page > 0 {
                        Button {
                            withAnimation { page -= 1 }
                        } label: {
                            Text("← 이전")
                                .font(.system(.body, design: .rounded))
                                .fontWeight(.semibold)
                                .foregroundStyle(.white.opacity(0.8))
                                .frame(width: 90)
                                .padding(.vertical, 14)
                                .background(Capsule().fill(.white.opacity(0.2)))
                        }
                    }
                    Button {
                        if page < pageCount - 1 {
                            withAnimation { page += 1 }
                        } else {
                            dismiss()
                        }
                    } label: {
                        Text(page < pageCount - 1 ? "다음 →" : "완료")
                            .font(.system(.body, design: .rounded))
                            .fontWeight(.bold)
                            .foregroundStyle(gradients[page].first ?? .blue)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(Capsule().fill(.white))
                    }
                }
                .padding(.horizontal, 32)
                .padding(.bottom, 36)
            }
        }
        #if os(iOS)
        .presentationDetents([.large])
        .presentationDragIndicator(.hidden)
        #endif
    }

    private var weekRangeLabel: String {
        guard let f = thisWeekDates.first, let l = thisWeekDates.last else { return "" }
        let fmt = DateFormatter(); fmt.locale = Locale(identifier: "ko_KR"); fmt.dateFormat = "M월 d일"
        return "\(fmt.string(from: f)) ~ \(fmt.string(from: l))"
    }
}

// MARK: - Review Pages

struct ComparisonPage: View {
    let thisRate: Double
    let lastRate: Double
    let delta: Double
    let weekLabel: String

    var body: some View {
        VStack(spacing: 24) {
            Spacer()
            Text("이번 주 결산").font(.system(size: 16, weight: .semibold, design: .rounded)).foregroundStyle(.white.opacity(0.8))
            Text(weekLabel).font(.system(size: 13, design: .rounded)).foregroundStyle(.white.opacity(0.6))

            Text("\(Int(thisRate * 100))%")
                .font(.system(size: 88, weight: .black, design: .rounded))
                .foregroundStyle(.white)

            HStack(spacing: 32) {
                VStack(spacing: 4) {
                    Text("지난 주").font(.system(size: 12, design: .rounded)).foregroundStyle(.white.opacity(0.6))
                    Text("\(Int(lastRate * 100))%").font(.system(size: 22, weight: .bold, design: .rounded)).foregroundStyle(.white.opacity(0.8))
                }
                VStack(spacing: 4) {
                    Text("변화").font(.system(size: 12, design: .rounded)).foregroundStyle(.white.opacity(0.6))
                    let d = Int(abs(delta) * 100)
                    Text(delta >= 0 ? "+\(d)% ↑" : "-\(d)% ↓")
                        .font(.system(size: 22, weight: .bold, design: .rounded))
                        .foregroundStyle(delta >= 0 ? Color(hex: "#55EFC4") ?? .mint : Color(hex: "#FDCB6E") ?? .yellow)
                }
            }
            .padding(.horizontal, 32)
            .padding(.vertical, 16)
            .background(Capsule().fill(.white.opacity(0.12)))

            Spacer()
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

struct HabitSpotlightPage: View {
    let title: String
    let subtitle: String
    let habit: Habit?
    let rate: Double

    var body: some View {
        VStack(spacing: 20) {
            Spacer()
            Text(title).font(.system(size: 16, weight: .semibold, design: .rounded)).foregroundStyle(.white.opacity(0.8))

            if let habit = habit {
                Circle()
                    .fill(habit.displayColor)
                    .frame(width: 80, height: 80)
                    .shadow(color: habit.displayColor.opacity(0.6), radius: 20, x: 0, y: 6)

                Text(habit.name)
                    .font(.system(size: 32, weight: .black, design: .rounded))
                    .foregroundStyle(.white)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 24)

                Text(subtitle)
                    .font(.system(size: 13, design: .rounded))
                    .foregroundStyle(.white.opacity(0.6))

                Text("\(Int(rate * 100))%")
                    .font(.system(size: 52, weight: .black, design: .rounded))
                    .foregroundStyle(.white)
                    .padding(.top, 4)

                Text("달성률")
                    .font(.system(size: 13, design: .rounded))
                    .foregroundStyle(.white.opacity(0.6))
            } else {
                Text("😅").font(.system(size: 64))
                Text("습관을 추가해보세요")
                    .font(.system(size: 22, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
            }
            Spacer()
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

struct WeeklyChartPage: View {
    let habits: [Habit]
    let thisWeekDates: [Date]
    let allRecords: [HabitRecord]

    struct PieSlice: Identifiable {
        let id = UUID()
        let label: String
        let value: Double
        let color: Color
    }

    private func habitRate(_ habit: Habit) -> Double {
        let recs = allRecords.filter { $0.habit?.persistentModelID == habit.persistentModelID }
        let checked = thisWeekDates.filter { d in recs.first { $0.date == d }?.isChecked == true }.count
        return Double(checked) / Double(max(thisWeekDates.count, 1))
    }

    private var overallRate: Double {
        guard !habits.isEmpty else { return 0 }
        return habits.reduce(0.0) { $0 + habitRate($1) } / Double(habits.count)
    }

    private var slices: [PieSlice] {
        [
            PieSlice(label: "달성", value: max(overallRate, 0.001),
                     color: Color(hex: "#2ED573") ?? .green),
            PieSlice(label: "미달성", value: max(1 - overallRate, 0.001),
                     color: .white.opacity(0.15))
        ]
    }

    var body: some View {
        VStack(spacing: 16) {
            Spacer()
            Text("이번 주 총 달성률").font(.system(size: 16, weight: .semibold, design: .rounded)).foregroundStyle(.white.opacity(0.8))

            ZStack {
                Chart(slices) { s in
                    SectorMark(angle: .value("비율", s.value),
                               innerRadius: .ratio(0.55),
                               angularInset: 1.5)
                    .cornerRadius(5)
                    .foregroundStyle(s.color)
                }
                .frame(width: 170, height: 170)

                VStack(spacing: 0) {
                    Text("\(Int(overallRate * 100))")
                        .font(.system(size: 50, weight: .black, design: .rounded))
                        .foregroundStyle(.white)
                    Text("%")
                        .font(.system(size: 16, weight: .bold, design: .rounded))
                        .foregroundStyle(.white.opacity(0.7))
                }
            }

            VStack(spacing: 8) {
                ForEach(habits) { habit in
                    HStack(spacing: 8) {
                        Circle().fill(habit.displayColor).frame(width: 8, height: 8)
                        Text(habit.name)
                            .font(.system(size: 12, design: .rounded))
                            .foregroundStyle(.white.opacity(0.85))
                            .lineLimit(1)
                        Spacer()
                        Text("\(Int(habitRate(habit) * 100))%")
                            .font(.system(size: 12, weight: .semibold, design: .rounded))
                            .foregroundStyle(.white)
                    }
                }
            }
            .padding(.horizontal, 36)

            Spacer()
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

struct MotivationPage: View {
    let message: String
    let rate: Double

    @State private var appeared = false

    private var emoji: String {
        if rate >= 0.8 { return "🔥" }
        if rate >= 0.5 { return "💪" }
        return "🌱"
    }

    var body: some View {
        VStack(spacing: 28) {
            Spacer()
            Text(emoji)
                .font(.system(size: 80))
                .scaleEffect(appeared ? 1.0 : 0.5)
                .opacity(appeared ? 1.0 : 0)
                .animation(.spring(response: 0.5, dampingFraction: 0.6), value: appeared)

            Text(message)
                .font(.system(size: 24, weight: .bold, design: .rounded))
                .foregroundStyle(.white)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
                .opacity(appeared ? 1.0 : 0)
                .offset(y: appeared ? 0 : 20)
                .animation(.easeOut(duration: 0.5).delay(0.2), value: appeared)

            Text("다음 주도 파이팅!")
                .font(.system(size: 14, design: .rounded))
                .foregroundStyle(.white.opacity(0.7))
                .opacity(appeared ? 1.0 : 0)
                .animation(.easeOut(duration: 0.5).delay(0.4), value: appeared)

            Spacer()
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .onAppear { appeared = true }
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
