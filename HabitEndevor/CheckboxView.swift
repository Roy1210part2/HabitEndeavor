import SwiftUI
import SwiftData
import Charts

struct CheckboxView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Habit.sortOrder) private var habits: [Habit]
    @Query private var allRecords: [HabitRecord]
    @Query private var settingsArray: [AppSettings]
    @Query private var completedQuests: [CompletedQuest]
    @Query private var purchases: [PurchasedCountry]

    @State private var showAddHabit = false
    @State private var selectedRecord: HabitRecord?
    // Maps habitID → date of the cell that just got checked (for particle burst)
    @State private var burstMap: [PersistentIdentifier: Date] = [:]

    private var settings: AppSettings {
        settingsArray.first ?? AppSettings()
    }

    private var weekDates: [Date] {
        Date().weekDates(startsOnMonday: settings.weekStartsOnMonday)
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                // 날짜 헤더
                currentDateHeader
                    .padding(.bottom, 12)

                weekHeaderRow
                    .padding(.bottom, 8)

                Divider()

                ForEach(habits.filter(\.isActive)) { habit in
                    HabitRowView(
                        habit: habit,
                        weekDates: weekDates,
                        records: records(for: habit),
                        burstDate: burstMap[habit.persistentModelID],
                        onTap: { date in handleTap(habit: habit, date: date) },
                        onLongPress: { date in handleLongPress(habit: habit, date: date) }
                    )
                    Divider()
                }

                addHabitButton
                    .padding(.top, 20)

                // 통계 섹션
                if !habits.filter(\.isActive).isEmpty {
                    statsSection
                        .padding(.top, 8)
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 8)
        }
        #if os(iOS)
        .navigationBarTitleDisplayMode(.inline)
        #endif
        .toolbar {
            ToolbarItem(placement: .principal) {
                HStack(spacing: 8) {
                    SunsetIconView(size: 28)
                    Text("HabitEndeavor")
                        .font(.system(.headline, design: .rounded))
                        .fontWeight(.bold)
                }
            }
            #if os(iOS)
            ToolbarItem(placement: .primaryAction) {
                EditButton()
            }
            #endif
            ToolbarItem(placement: .primaryAction) {
                Button { showAddHabit = true } label: {
                    Image(systemName: "plus")
                        .fontWeight(.semibold)
                }
            }
        }
        .sheet(isPresented: $showAddHabit) {
            AddHabitSheet(nextSortOrder: (habits.map(\.sortOrder).max() ?? -1) + 1)
        }
        .sheet(item: $selectedRecord) { record in
            FailureNoteSheet(record: record)
        }
        .onChange(of: allRecords) { _, _ in
            QuestService.checkAndComplete(
                habits: habits.filter(\.isActive),
                allRecords: allRecords,
                completedQuests: completedQuests,
                purchases: purchases,
                context: modelContext
            )
        }
    }

    // MARK: - Current Date Header

    private var currentDateHeader: some View {
        VStack(alignment: .center, spacing: 2) {
            Text(yearString)
                .font(.system(size: 13, weight: .regular, design: .rounded))
                .foregroundStyle(Color.secondary)

            Text(monthDayString)
                .font(.system(size: 28, weight: .bold, design: .rounded))
                .foregroundStyle(Color.primary)
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 4)
    }

    private var yearString: String {
        let f = DateFormatter()
        f.locale = Locale(identifier: "ko_KR")
        f.dateFormat = "yyyy년"
        return f.string(from: Date())
    }

    private var monthDayString: String {
        let f = DateFormatter()
        f.locale = Locale(identifier: "ko_KR")
        f.dateFormat = "M월 d일"
        return f.string(from: Date())
    }

    // MARK: - Week Header

    private var weekHeaderRow: some View {
        HStack(spacing: 0) {
            Spacer().frame(width: 118)
            ForEach(weekDates, id: \.self) { date in
                VStack(spacing: 4) {
                    Text(date.koreanWeekday())
                        .font(.system(size: 13, weight: date.isToday ? .semibold : .regular, design: .rounded))
                        .foregroundStyle(date.isToday ? Color.primary : Color.secondary)
                    Text("\(date.dayNumber())")
                        .font(.system(size: 18, weight: date.isToday ? .bold : .medium, design: .rounded))
                        .foregroundStyle(date.isToday ? Color.primary : Color.secondary)
                }
                .frame(maxWidth: .infinity)
            }
        }
    }

    // MARK: - Add Button

    private var addHabitButton: some View {
        Button {
            showAddHabit = true
        } label: {
            Label("습관 추가", systemImage: "plus.circle")
                .font(.body)
                .foregroundStyle(Color.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.bottom, 8)
    }

    // MARK: - Stats Section

    private var statsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("습관 통계")
                .font(.system(.title3, design: .rounded))
                .fontWeight(.bold)
                .padding(.top, 12)

            ForEach(habits.filter(\.isActive)) { habit in
                HabitStatsCard(habit: habit, records: records(for: habit))
            }

            OverallAchievementChart(
                habits: habits.filter(\.isActive),
                allRecords: allRecords
            )
        }
        .padding(.bottom, 32)
    }

    // MARK: - Helpers

    private func records(for habit: Habit) -> [HabitRecord] {
        allRecords.filter { $0.habit?.persistentModelID == habit.persistentModelID }
    }

    private func record(for habit: Habit, on date: Date) -> HabitRecord? {
        let dayStart = Calendar.current.startOfDay(for: date)
        return allRecords.first {
            $0.habit?.persistentModelID == habit.persistentModelID && $0.date == dayStart
        }
    }

    // MARK: - Tap Logic: empty → checked → X → empty

    private func handleTap(habit: Habit, date: Date) {
        var justChecked = false
        if let existing = record(for: habit, on: date) {
            if existing.isChecked {
                existing.isChecked = false
                if existing.date == Date.todayStart { existing.coinPaidAt = nil }
            } else {
                modelContext.delete(existing)
            }
        } else {
            let newRecord = HabitRecord(date: date, habit: habit)
            modelContext.insert(newRecord)
            newRecord.isChecked = true
            if date == Date.todayStart { newRecord.coinPaidAt = Date() }
            justChecked = true
        }

        if justChecked {
            triggerHaptic()
            burstMap[habit.persistentModelID] = date
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.7) {
                burstMap.removeValue(forKey: habit.persistentModelID)
            }
        }
    }

    private func triggerHaptic() {
        #if os(iOS)
        let impact = UIImpactFeedbackGenerator(style: .medium)
        impact.impactOccurred()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.12) {
            let success = UINotificationFeedbackGenerator()
            success.notificationOccurred(.success)
        }
        #endif
    }

    private func handleLongPress(habit: Habit, date: Date) {
        if let existing = record(for: habit, on: date) {
            selectedRecord = existing
        } else {
            let newRecord = HabitRecord(date: date, habit: habit)
            modelContext.insert(newRecord)
            selectedRecord = newRecord
        }
    }
}

// MARK: - Habit Row

struct HabitRowView: View {
    let habit: Habit
    let weekDates: [Date]
    let records: [HabitRecord]
    let burstDate: Date?
    let onTap: (Date) -> Void
    let onLongPress: (Date) -> Void

    private var pastAndTodayDates: [Date] {
        weekDates.filter { !$0.isFuture }
    }

    private var weeklyRate: Double {
        guard !pastAndTodayDates.isEmpty else { return 0 }
        let checked = pastAndTodayDates.filter { date in
            records.first { $0.date == date }?.isChecked == true
        }.count
        return Double(checked) / Double(pastAndTodayDates.count)
    }

    var body: some View {
        HStack(spacing: 0) {
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 6) {
                    Text(habit.emoji)
                        .font(.body)
                    Text(habit.name)
                        .font(.system(.body, design: .rounded))
                        .fontWeight(.semibold)
                        .lineLimit(1)
                        .truncationMode(.tail)
                }
                Text("\(Int(weeklyRate * 100))%")
                    .font(.subheadline)
                    .foregroundStyle(Color.secondary)
            }
            .frame(width: 118, alignment: .leading)

            ForEach(weekDates, id: \.self) { date in
                let rec = records.first { $0.date == date }
                ZStack {
                    CheckboxCell(
                        hasRecord: rec != nil,
                        isChecked: rec?.isChecked ?? false,
                        isFuture: date.isFuture,
                        isToday: date.isToday
                    )
                    if burstDate == date {
                        CheckmarkBurst()
                    }
                }
                .frame(maxWidth: .infinity)
                .contentShape(Rectangle())
                .onTapGesture {
                    guard !date.isFuture else { return }
                    onTap(date)
                }
                .simultaneousGesture(
                    LongPressGesture(minimumDuration: 0.5)
                        .onEnded { _ in
                            guard !date.isFuture else { return }
                            onLongPress(date)
                        }
                )
                .contextMenu {
                    if !date.isFuture {
                        Button("실패 사유 기록") { onLongPress(date) }
                    }
                }
            }
        }
        .padding(.vertical, 12)
    }
}

// MARK: - Checkbox Cell (3 states: empty / checked / X)

struct CheckboxCell: View {
    let hasRecord: Bool
    let isChecked: Bool
    let isFuture: Bool
    let isToday: Bool

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 7)
                .fill(fillColor)

            RoundedRectangle(cornerRadius: 7)
                .stroke(strokeColor, lineWidth: 1.5)

            if hasRecord {
                Image(systemName: isChecked ? "checkmark" : "xmark")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(isChecked ? Color(white: 1.0) : Color.red)
            }
        }
        .frame(width: 36, height: 36)
        .opacity(isFuture ? 0.35 : 1.0)
        .background(
            isToday
                ? RoundedRectangle(cornerRadius: 9)
                    .fill(Color.primary.opacity(0.06))
                    .padding(-4)
                : nil
        )
    }

    private var fillColor: Color {
        if !hasRecord { return .clear }
        return isChecked ? Color.primary : Color.red.opacity(0.12)
    }

    private var strokeColor: Color {
        if !hasRecord { return Color.primary.opacity(isFuture ? 0.2 : 0.45) }
        return isChecked ? Color.primary.opacity(0.9) : Color.red.opacity(0.6)
    }
}

// MARK: - Habit Stats Card

enum DayMark { case checked, failed, empty }

struct DayCellData {
    let date: Date
    let mark: DayMark
    var isToday: Bool { Calendar.current.isDateInToday(date) }
}

struct HabitStatsCard: View {
    let habit: Habit
    let records: [HabitRecord]

    private var checkedRecords: [HabitRecord] { records.filter(\.isChecked) }
    private var totalCount: Int { checkedRecords.count }

    private var currentStreak: Int {
        var streak = 0
        var day = Date.todayStart
        let cal = Calendar.current
        while true {
            if records.first(where: { $0.date == day })?.isChecked == true {
                streak += 1
                day = cal.date(byAdding: .day, value: -1, to: day)!
            } else { break }
        }
        return streak
    }

    private var thisMonthRate: Double {
        let cal = Calendar.current
        let now = Date()
        let startOfMonth = cal.date(from: cal.dateComponents([.year, .month], from: now))!
        let daysPassed = cal.dateComponents([.day], from: startOfMonth, to: now).day! + 1
        guard daysPassed > 0 else { return 0 }
        return Double(checkedRecords.filter { $0.date >= startOfMonth }.count) / Double(daysPassed)
    }

    private var bestStreak: Int {
        let sorted = checkedRecords.map(\.date).sorted()
        guard !sorted.isEmpty else { return 0 }
        var best = 1, cur = 1
        let cal = Calendar.current
        for i in 1..<sorted.count {
            let diff = cal.dateComponents([.day], from: sorted[i-1], to: sorted[i]).day ?? 0
            if diff == 1 { cur += 1; best = max(best, cur) } else { cur = 1 }
        }
        return best
    }

    private var heatmapCells: [DayCellData] {
        let cal = Calendar.current
        return (0..<28).reversed().map { offset in
            let date = cal.date(byAdding: .day, value: -offset, to: Date.todayStart)!
            let rec = records.first { $0.date == date }
            let mark: DayMark = rec.map { $0.isChecked ? .checked : .failed } ?? .empty
            return DayCellData(date: date, mark: mark)
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top) {
                HStack(spacing: 6) {
                    Text(habit.emoji).font(.title3)
                    Text(habit.name)
                        .font(.system(.subheadline, design: .rounded))
                        .fontWeight(.semibold)
                }
                Spacer()
                VStack(spacing: 3) {
                    RingProgressView(value: thisMonthRate)
                    Text("이번달")
                        .font(.system(size: 9, design: .rounded))
                        .foregroundStyle(Color.secondary)
                }
            }

            MiniHeatmapView(cells: heatmapCells)

            HStack(spacing: 0) {
                statItem(icon: "flame.fill",   color: .orange,
                         value: "\(currentStreak)일", label: "연속 달성")
                Divider().frame(height: 32)
                statItem(icon: "star.fill",    color: .yellow,
                         value: "\(totalCount)회",   label: "총 달성")
                Divider().frame(height: 32)
                statItem(icon: "trophy.fill",  color: Color(red: 0.8, green: 0.6, blue: 0.2),
                         value: "\(bestStreak)일",   label: "최장 연속")
            }
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(Color.cardBackground)
                .shadow(color: .black.opacity(0.07), radius: 6, x: 0, y: 2)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(Color.primary.opacity(0.07), lineWidth: 1)
        )
    }

    private func statItem(icon: String, color: Color, value: String, label: String) -> some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .font(.system(size: 15))
                .foregroundStyle(color)
            Text(value)
                .font(.system(.subheadline, design: .rounded))
                .fontWeight(.bold)
            Text(label)
                .font(.system(size: 10, design: .rounded))
                .foregroundStyle(Color.secondary)
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Ring Progress View

struct RingProgressView: View {
    let value: Double

    var body: some View {
        ZStack {
            Circle()
                .stroke(Color.primary.opacity(0.1), lineWidth: 5)
            Circle()
                .trim(from: 0, to: CGFloat(min(value, 1.0)))
                .stroke(
                    Color.primary.opacity(0.85),
                    style: StrokeStyle(lineWidth: 5, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))
                .animation(.easeInOut(duration: 0.5), value: value)
            VStack(spacing: 0) {
                Text("\(Int(value * 100))")
                    .font(.system(size: 12, weight: .bold, design: .rounded))
                Text("%")
                    .font(.system(size: 7, weight: .medium, design: .rounded))
                    .foregroundStyle(Color.secondary)
            }
        }
        .frame(width: 46, height: 46)
    }
}

// MARK: - Mini Heatmap View

struct MiniHeatmapView: View {
    let cells: [DayCellData]

    private let gridColumns = Array(repeating: GridItem(.flexible(), spacing: 3), count: 7)
    private let dayLabels = ["월", "화", "수", "목", "금", "토", "일"]

    var body: some View {
        VStack(alignment: .leading, spacing: 3) {
            LazyVGrid(columns: gridColumns, spacing: 2) {
                ForEach(dayLabels, id: \.self) { label in
                    Text(label)
                        .font(.system(size: 8, design: .rounded))
                        .foregroundStyle(Color.secondary.opacity(0.6))
                        .frame(maxWidth: .infinity)
                        .multilineTextAlignment(.center)
                }
            }
            LazyVGrid(columns: gridColumns, spacing: 3) {
                ForEach(0..<cells.count, id: \.self) { idx in
                    HeatmapCell(cell: cells[idx])
                }
            }
            HStack {
                Text("28일 전")
                    .font(.system(size: 8, design: .rounded))
                    .foregroundStyle(Color.secondary.opacity(0.5))
                Spacer()
                Text("오늘")
                    .font(.system(size: 8, design: .rounded))
                    .foregroundStyle(Color.secondary.opacity(0.5))
            }
            .padding(.top, 1)
        }
    }
}

struct HeatmapCell: View {
    let cell: DayCellData

    var body: some View {
        RoundedRectangle(cornerRadius: 3)
            .fill(fillColor)
            .aspectRatio(1, contentMode: .fit)
            .overlay(
                cell.isToday
                    ? RoundedRectangle(cornerRadius: 3)
                        .stroke(Color.primary.opacity(0.7), lineWidth: 1.5)
                    : nil
            )
    }

    private var fillColor: Color {
        switch cell.mark {
        case .checked: return Color.primary.opacity(0.82)
        case .failed:  return Color.red.opacity(0.3)
        case .empty:   return Color.primary.opacity(0.08)
        }
    }
}

// MARK: - Checkmark Burst (Particle Animation)

struct CheckmarkBurst: View {
    @State private var exploded = false

    private let particleColors: [Color] = [
        .orange, .yellow, .pink, .blue, .green, .red, .purple, .teal, .orange, .mint, .cyan, .yellow
    ]

    var body: some View {
        ZStack {
            ForEach(0..<12, id: \.self) { i in
                let angle = Double(i) * (360.0 / 12.0)
                Circle()
                    .fill(particleColors[i % particleColors.count])
                    .frame(width: 5, height: 5)
                    .offset(
                        x: exploded ? CGFloat(cos(angle * .pi / 180)) * 30 : 0,
                        y: exploded ? CGFloat(sin(angle * .pi / 180)) * 30 : 0
                    )
                    .opacity(exploded ? 0 : 1)
                    .scaleEffect(exploded ? 0.3 : 1.2)
            }
        }
        .onAppear {
            withAnimation(.easeOut(duration: 0.55)) { exploded = true }
        }
        .allowsHitTesting(false)
    }
}

// MARK: - Overall Achievement Chart

struct OverallAchievementChart: View {
    let habits: [Habit]
    let allRecords: [HabitRecord]

    struct HabitRate: Identifiable {
        let id: Int
        let emoji: String
        let name: String
        let rate: Double
    }

    private func records(for habit: Habit) -> [HabitRecord] {
        allRecords.filter { $0.habit?.persistentModelID == habit.persistentModelID }
    }

    private func monthRate(for habit: Habit) -> Double {
        let cal = Calendar.current
        let now = Date()
        let startOfMonth = cal.date(from: cal.dateComponents([.year, .month], from: now))!
        let daysPassed = cal.dateComponents([.day], from: startOfMonth, to: now).day! + 1
        guard daysPassed > 0 else { return 0 }
        let checked = records(for: habit).filter { $0.isChecked && $0.date >= startOfMonth }.count
        return Double(checked) / Double(daysPassed)
    }

    private var chartData: [HabitRate] {
        habits.enumerated().map { idx, habit in
            HabitRate(
                id: idx,
                emoji: habit.emoji,
                name: habit.name,
                rate: monthRate(for: habit)
            )
        }
    }

    private var overallRate: Double {
        guard !chartData.isEmpty else { return 0 }
        return chartData.map(\.rate).reduce(0, +) / Double(chartData.count)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .bottom, spacing: 6) {
                Text("이번달 전체 달성률")
                    .font(.system(.subheadline, design: .rounded))
                    .fontWeight(.semibold)
                Spacer()
                Text("\(Int(overallRate * 100))%")
                    .font(.system(.title2, design: .rounded))
                    .fontWeight(.bold)
                    .foregroundStyle(Color.primary)
            }

            // Overall progress bar
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 6)
                        .fill(Color.primary.opacity(0.08))
                        .frame(height: 10)
                    RoundedRectangle(cornerRadius: 6)
                        .fill(Color.primary.opacity(0.8))
                        .frame(width: geo.size.width * CGFloat(overallRate), height: 10)
                        .animation(.easeInOut(duration: 0.6), value: overallRate)
                }
            }
            .frame(height: 10)

            // Per-habit bar chart
            if !chartData.isEmpty {
                Chart(chartData) { item in
                    BarMark(
                        x: .value("달성률", item.rate),
                        y: .value("습관", "\(item.emoji) \(item.name)")
                    )
                    .foregroundStyle(
                        item.rate >= 0.8 ? Color.primary.opacity(0.85) :
                        item.rate >= 0.5 ? Color.primary.opacity(0.55) :
                                           Color.primary.opacity(0.25)
                    )
                    .cornerRadius(5)
                    .annotation(position: .trailing) {
                        Text("\(Int(item.rate * 100))%")
                            .font(.system(size: 10, design: .rounded))
                            .foregroundStyle(Color.secondary)
                    }
                }
                .chartXScale(domain: 0...1)
                .chartXAxis {
                    AxisMarks(values: [0, 0.25, 0.5, 0.75, 1.0]) { value in
                        AxisGridLine()
                        AxisValueLabel {
                            if let v = value.as(Double.self) {
                                Text("\(Int(v * 100))%").font(.system(size: 9))
                            }
                        }
                    }
                }
                .frame(height: CGFloat(chartData.count) * 44)
            }
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(Color.cardBackground)
                .shadow(color: .black.opacity(0.07), radius: 6, x: 0, y: 2)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(Color.primary.opacity(0.07), lineWidth: 1)
        )
    }
}

#Preview {
    NavigationStack {
        CheckboxView()
    }
    .modelContainer(for: [Habit.self, HabitRecord.self, AppSettings.self], inMemory: true)
}
