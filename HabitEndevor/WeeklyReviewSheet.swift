import SwiftUI
import SwiftData
import Charts

// MARK: - Motivational Messages

let motivationalMessages: [String] = [
    "작은 습관이 큰 삶을 만든다.\n오늘도 한 걸음 앞으로.",
    "포기하지 않는 것 자체가\n이미 성공이야.",
    "매일 1%씩 나아지면\n1년 후엔 37배 성장해있어.",
    "습관은 두 번째 본성이다.\n넌 지금 그것을 만들고 있어.",
    "완벽하지 않아도 괜찮아.\n그냥 계속하는 것이 전부야.",
    "오늘의 작은 노력이\n내일의 큰 차이를 만든다.",
]

// MARK: - WeeklyReviewSheet

struct WeeklyReviewSheet: View {
    @Environment(\.dismiss) private var dismiss
    let habits: [Habit]
    let allRecords: [HabitRecord]

    @State private var page = 0

    private let cal = Calendar.current
    private let pageCount = 5

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
        return habits.reduce(0.0) { $0 + habitRate($1, dates: dates) } / Double(habits.count)
    }

    private var thisRate:  Double { overallRate(dates: thisWeekDates) }
    private var lastRate:  Double { overallRate(dates: lastWeekDates) }
    private var delta:     Double { thisRate - lastRate }
    private var bestHabit: Habit? { habits.max { habitRate($0, dates: thisWeekDates) < habitRate($1, dates: thisWeekDates) } }
    private var worstHabit: Habit? { habits.min { habitRate($0, dates: thisWeekDates) < habitRate($1, dates: thisWeekDates) } }

    private var motivationMsg: String {
        if thisRate >= 0.8 { return motivationalMessages[0] }
        if thisRate >= 0.5 { return motivationalMessages[Int.random(in: 1...3)] }
        return motivationalMessages[Int.random(in: 4...5)]
    }

    // 세련된 다크 톤 (B&W 미니멀 앱 컨셉)
    private let gradients: [[Color]] = [
        [Color(hex: "#0F1923") ?? .black, Color(hex: "#1A2D3D") ?? .black],
        [Color(hex: "#0D1F17") ?? .black, Color(hex: "#1A3D2A") ?? .black],
        [Color(hex: "#1F150D") ?? .black, Color(hex: "#3D2A1A") ?? .black],
        [Color(hex: "#0D0F1F") ?? .black, Color(hex: "#1A1D3D") ?? .black],
        [Color(hex: "#101419") ?? .black, Color(hex: "#1C2530") ?? .black],
    ]

    var body: some View {
        ZStack {
            LinearGradient(colors: gradients[page], startPoint: .topLeading, endPoint: .bottomTrailing)
                .ignoresSafeArea()
                .animation(.easeInOut(duration: 0.4), value: page)

            VStack(spacing: 0) {
                // 진행 도트
                HStack(spacing: 6) {
                    ForEach(0..<pageCount, id: \.self) { i in
                        Capsule()
                            .fill(.white.opacity(i == page ? 1 : 0.3))
                            .frame(width: i == page ? 20 : 6, height: 6)
                            .animation(.spring(response: 0.3), value: page)
                    }
                }
                .padding(.top, 20)
                .padding(.bottom, 8)

                // 페이지
                TabView(selection: $page) {
                    ComparisonPage(thisRate: thisRate, lastRate: lastRate, delta: delta, weekLabel: weekRangeLabel).tag(0)
                    HabitSpotlightPage(title: "이번 주 MVP", subtitle: "가장 잘한 습관",
                                       habit: bestHabit, rate: bestHabit.map { habitRate($0, dates: thisWeekDates) } ?? 0).tag(1)
                    HabitSpotlightPage(title: "조금 아쉬웠어", subtitle: "더 노력할 습관",
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
                        Button { withAnimation { page -= 1 } } label: {
                            Text("← 이전")
                                .font(.system(.body, design: .rounded)).fontWeight(.semibold)
                                .foregroundStyle(.white.opacity(0.8))
                                .frame(width: 90).padding(.vertical, 14)
                                .background(Capsule().fill(.white.opacity(0.18)))
                        }
                    }
                    Button {
                        if page < pageCount - 1 { withAnimation { page += 1 } } else { dismiss() }
                    } label: {
                        Text(page < pageCount - 1 ? "다음 →" : "완료")
                            .font(.system(.body, design: .rounded)).fontWeight(.bold)
                            .foregroundStyle(Color.black)
                            .frame(maxWidth: .infinity).padding(.vertical, 14)
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
        let fmt = DateFormatter()
        fmt.locale = Locale(identifier: "ko_KR")
        fmt.dateFormat = "M월 d일"
        return "\(fmt.string(from: f)) ~ \(fmt.string(from: l))"
    }
}

// MARK: - ComparisonPage

struct ComparisonPage: View {
    let thisRate: Double
    let lastRate: Double
    let delta: Double
    let weekLabel: String

    var body: some View {
        VStack(spacing: 24) {
            Spacer()
            Text("이번 주 결산")
                .font(.system(size: 16, weight: .semibold, design: .rounded))
                .foregroundStyle(.white.opacity(0.75))
            Text(weekLabel)
                .font(.system(size: 13, design: .rounded))
                .foregroundStyle(.white.opacity(0.5))

            Text("\(Int(thisRate * 100))%")
                .font(.system(size: 88, weight: .black, design: .rounded))
                .foregroundStyle(.white)

            HStack(spacing: 32) {
                statBadge(label: "지난 주", value: "\(Int(lastRate * 100))%")
                statBadge(label: "변화",
                          value: delta >= 0 ? "+\(Int(abs(delta) * 100))% ↑" : "-\(Int(abs(delta) * 100))% ↓",
                          accent: delta >= 0 ? Color(hex: "#A8EDCA") ?? .mint : Color(hex: "#FDE8A3") ?? .yellow)
            }
            .padding(.horizontal, 32).padding(.vertical, 16)
            .background(Capsule().fill(.white.opacity(0.1)))

            Spacer(); Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private func statBadge(label: String, value: String, accent: Color = .white) -> some View {
        VStack(spacing: 4) {
            Text(label).font(.system(size: 12, design: .rounded)).foregroundStyle(.white.opacity(0.55))
            Text(value).font(.system(size: 22, weight: .bold, design: .rounded)).foregroundStyle(accent.opacity(0.9))
        }
    }
}

// MARK: - HabitSpotlightPage

struct HabitSpotlightPage: View {
    let title: String
    let subtitle: String
    let habit: Habit?
    let rate: Double

    var body: some View {
        VStack(spacing: 20) {
            Spacer()
            Text(title)
                .font(.system(size: 16, weight: .semibold, design: .rounded))
                .foregroundStyle(.white.opacity(0.75))

            if let habit {
                Circle()
                    .fill(habit.displayColor)
                    .frame(width: 80, height: 80)
                    .shadow(color: habit.displayColor.opacity(0.5), radius: 20, x: 0, y: 6)

                Text(habit.name)
                    .font(.system(size: 32, weight: .black, design: .rounded))
                    .foregroundStyle(.white)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 24)

                Text(subtitle)
                    .font(.system(size: 13, design: .rounded))
                    .foregroundStyle(.white.opacity(0.55))

                Text("\(Int(rate * 100))%")
                    .font(.system(size: 52, weight: .black, design: .rounded))
                    .foregroundStyle(.white)

                Text("달성률")
                    .font(.system(size: 13, design: .rounded))
                    .foregroundStyle(.white.opacity(0.55))
            } else {
                Text("습관을 추가해보세요")
                    .font(.system(size: 22, weight: .bold, design: .rounded))
                    .foregroundStyle(.white.opacity(0.6))
            }
            Spacer(); Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - WeeklyChartPage

struct WeeklyChartPage: View {
    let habits: [Habit]
    let thisWeekDates: [Date]
    let allRecords: [HabitRecord]

    struct PieSlice: Identifiable {
        let id = UUID()
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
            PieSlice(value: max(overallRate, 0.001),       color: .white.opacity(0.85)),
            PieSlice(value: max(1 - overallRate, 0.001),   color: .white.opacity(0.12))
        ]
    }

    var body: some View {
        VStack(spacing: 16) {
            Spacer()
            Text("이번 주 총 달성률")
                .font(.system(size: 16, weight: .semibold, design: .rounded))
                .foregroundStyle(.white.opacity(0.75))

            ZStack {
                Chart(slices) { s in
                    SectorMark(angle: .value("비율", s.value), innerRadius: .ratio(0.55), angularInset: 1.5)
                        .cornerRadius(5).foregroundStyle(s.color)
                }
                .frame(width: 170, height: 170)

                VStack(spacing: 0) {
                    Text("\(Int(overallRate * 100))")
                        .font(.system(size: 50, weight: .black, design: .rounded))
                        .foregroundStyle(.white)
                    Text("%")
                        .font(.system(size: 16, weight: .bold, design: .rounded))
                        .foregroundStyle(.white.opacity(0.6))
                }
            }

            VStack(spacing: 8) {
                ForEach(habits) { habit in
                    HStack(spacing: 8) {
                        Circle().fill(habit.displayColor).frame(width: 8, height: 8)
                        Text(habit.name)
                            .font(.system(size: 12, design: .rounded))
                            .foregroundStyle(.white.opacity(0.8)).lineLimit(1)
                        Spacer()
                        Text("\(Int(habitRate(habit) * 100))%")
                            .font(.system(size: 12, weight: .semibold, design: .rounded))
                            .foregroundStyle(.white)
                    }
                }
            }
            .padding(.horizontal, 36)

            Spacer(); Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - MotivationPage

struct MotivationPage: View {
    let message: String
    let rate: Double
    @State private var appeared = false

    private var icon: String {
        rate >= 0.8 ? "flame.fill" : rate >= 0.5 ? "bolt.fill" : "leaf.fill"
    }

    var body: some View {
        VStack(spacing: 28) {
            Spacer()
            Image(systemName: icon)
                .font(.system(size: 64, weight: .bold))
                .foregroundStyle(.white.opacity(0.9))
                .scaleEffect(appeared ? 1.0 : 0.4)
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
                .foregroundStyle(.white.opacity(0.6))
                .opacity(appeared ? 1.0 : 0)
                .animation(.easeOut(duration: 0.5).delay(0.4), value: appeared)

            Spacer(); Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .onAppear { appeared = true }
    }
}
