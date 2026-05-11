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
    @State private var editingHabit: Habit?
    @State private var burstMap: [PersistentIdentifier: Date] = [:]
    // 🔴 핵심 최적화: habitID → [HabitRecord] 딕셔너리 (한 번만 빌드, O(1) 조회)
    @State private var recordsByHabit: [PersistentIdentifier: [HabitRecord]] = [:]

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
                        onLongPress: { date in handleLongPress(habit: habit, date: date) },
                        onEdit: { editingHabit = habit }
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
                    Text("Habit Endeavor")
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
        .sheet(item: $editingHabit) { habit in
            EditHabitSheet(habit: habit)
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
        .onAppear {
            buildRecordIndex(allRecords)
            assignMissingColors()
        }
        .onChange(of: allRecords) { _, new in buildRecordIndex(new) }
    }

    // 색상 없는 습관에 팔레트 색상 자동 배정
    private func assignMissingColors() {
        let active = habits.filter(\.isActive)
        var changed = false
        for (idx, habit) in active.enumerated() {
            if habit.colorHex == nil {
                habit.colorHex = habitColorPalette[idx % habitColorPalette.count]
                changed = true
            }
            if habit.emoji == "✅" {           // 기존 기본 이모지 교체
                habit.emoji = "⭐️"
                changed = true
            }
        }
        if changed { try? modelContext.save() }
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
            Spacer().frame(width: 100)
            ForEach(weekDates, id: \.self) { date in
                VStack(spacing: 3) {
                    Text(date.koreanWeekday())
                        .font(.system(size: 11, weight: date.isToday ? .semibold : .regular, design: .rounded))
                        .foregroundStyle(date.isToday ? Color.primary : Color.secondary)
                    Text("\(date.dayNumber())")
                        .font(.system(size: 15, weight: date.isToday ? .bold : .medium, design: .rounded))
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

            CombinedHeatmapGrid(
                habits: habits.filter(\.isActive),
                recordsByHabit: recordsByHabit
            )

            HabitTrendChart(
                habits: habits.filter(\.isActive),
                recordsByHabit: recordsByHabit
            )
        }
        .padding(.bottom, 32)
    }

    // MARK: - Record Index (O(1) lookup)

    private func buildRecordIndex(_ records: [HabitRecord]) {
        var d: [PersistentIdentifier: [HabitRecord]] = [:]
        for r in records {
            if let id = r.habit?.persistentModelID { d[id, default: []].append(r) }
        }
        recordsByHabit = d
    }

    // MARK: - Helpers

    private func records(for habit: Habit) -> [HabitRecord] {
        recordsByHabit[habit.persistentModelID] ?? []
    }

    private func record(for habit: Habit, on date: Date) -> HabitRecord? {
        let dayStart = Calendar.current.startOfDay(for: date)
        return (recordsByHabit[habit.persistentModelID] ?? []).first { $0.date == dayStart }
    }

    // MARK: - Tap Logic: empty → checked → X → empty

    private func handleTap(habit: Habit, date: Date) {
        var justChecked = false
        if let existing = record(for: habit, on: date) {
            if existing.isChecked {
                existing.isChecked = false
                CoinService.revokeIfToday(record: existing) // ① CoinService 위임
            } else {
                modelContext.delete(existing)
            }
        } else {
            let newRecord = HabitRecord(date: date, habit: habit)
            modelContext.insert(newRecord)
            newRecord.isChecked = true
            CoinService.awardIfToday(record: newRecord)     // ① CoinService 위임
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
    var onEdit: (() -> Void)? = nil

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
            HStack(spacing: 6) {
                RoundedRectangle(cornerRadius: 2)
                    .fill(habit.displayColor)
                    .frame(width: 3, height: 28)
                VStack(alignment: .leading, spacing: 1) {
                    Text(habit.name)
                        .font(.system(.subheadline, design: .rounded))
                        .fontWeight(.semibold)
                        .lineLimit(1)
                        .truncationMode(.tail)
                    Text("\(Int(weeklyRate * 100))%")
                        .font(.system(size: 11))
                        .foregroundStyle(Color.secondary)
                }
            }
            .frame(width: 100, alignment: .leading)
            .contentShape(Rectangle())
            .onTapGesture { onEdit?() }

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
            RoundedRectangle(cornerRadius: 6)
                .fill(fillColor)

            RoundedRectangle(cornerRadius: 6)
                .stroke(strokeColor, lineWidth: 1.5)

            if hasRecord {
                Image(systemName: isChecked ? "checkmark" : "xmark")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(isChecked ? Color(white: 1.0) : Color.red)
            }
        }
        .frame(width: 32, height: 32)
        .opacity(isFuture ? 0.35 : 1.0)
        .background(
            isToday
                ? RoundedRectangle(cornerRadius: 8)
                    .fill(Color.primary.opacity(0.06))
                    .padding(-3)
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

// MARK: Bento Heatmap (compact 7×4, no labels)

struct BentoHeatmap: View {
    let cells: [DayCellData]
    let accentColor: Color

    private let cols = Array(repeating: GridItem(.flexible(), spacing: 2), count: 7)

    var body: some View {
        LazyVGrid(columns: cols, spacing: 2) {
            ForEach(0..<cells.count, id: \.self) { i in
                RoundedRectangle(cornerRadius: 2)
                    .fill(cellColor(cells[i]))
                    .aspectRatio(1, contentMode: .fit)
                    .overlay(cells[i].isToday
                        ? RoundedRectangle(cornerRadius: 2).stroke(accentColor, lineWidth: 1.5)
                        : nil)
            }
        }
    }

    private func cellColor(_ c: DayCellData) -> Color {
        switch c.mark {
        case .checked: return accentColor.opacity(0.85)
        case .failed:  return Color.primary.opacity(0.15) // 무채색 톤
        case .empty:   return Color.primary.opacity(0.04) // 무채색 톤
        }
    }
}

struct HabitStatsCard: View {
    let habit: Habit
    let records: [HabitRecord]

    private var checkedRecords: [HabitRecord] { records.filter(\.isChecked) }
    private var totalCount: Int { checkedRecords.count }

    private var currentStreak: Int {
        var streak = 0, day = Date.todayStart
        let cal = Calendar.current
        while records.first(where: { $0.date == day })?.isChecked == true {
            streak += 1
            day = cal.date(byAdding: .day, value: -1, to: day)!
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
            let rec  = records.first { $0.date == date }
            return DayCellData(date: date, mark: rec.map { $0.isChecked ? .checked : .failed } ?? .empty)
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // ── Header ──
            HStack(spacing: 8) {
                RoundedRectangle(cornerRadius: 2)
                    .fill(habit.displayColor)
                    .frame(width: 4, height: 22)
                Text(habit.name)
                    .font(.system(.subheadline, design: .rounded))
                    .fontWeight(.semibold)
                    .lineLimit(1)
            }
            .padding(.horizontal, 14)
            .padding(.top, 14)
            .padding(.bottom, 10)

            // ── Bento row: heatmap + ring ──
            HStack(alignment: .center, spacing: 10) {
                BentoHeatmap(cells: heatmapCells, accentColor: habit.displayColor)
                    .frame(maxWidth: .infinity)

                VStack(spacing: 3) {
                    RingProgressView(value: thisMonthRate, color: habit.displayColor)
                    Text("이번달")
                        .font(.system(size: 9, design: .rounded))
                        .foregroundStyle(Color.secondary)
                }
                .frame(width: 58)
            }
            .padding(.horizontal, 14)
            .padding(.bottom, 10)

            Divider().padding(.horizontal, 10)

            // ── Stats row ──
            HStack(spacing: 0) {
                statItem(icon: "flame.fill",  color: .orange,
                         value: "\(currentStreak)일", label: "연속")
                Divider().frame(height: 28)
                statItem(icon: "star.fill",   color: habit.displayColor,
                         value: "\(totalCount)회",   label: "총달성")
                Divider().frame(height: 28)
                statItem(icon: "trophy.fill", color: Color(red: 0.8, green: 0.6, blue: 0.2),
                         value: "\(bestStreak)일",   label: "최장")
            }
            .padding(.vertical, 8)
        }
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(.ultraThinMaterial)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .stroke(Color.primary.opacity(0.05), lineWidth: 1)
        )
    }

    private func statItem(icon: String, color: Color, value: String, label: String) -> some View {
        VStack(spacing: 3) {
            Image(systemName: icon).font(.system(size: 13)).foregroundStyle(color)
            Text(value).font(.system(.footnote, design: .rounded)).fontWeight(.bold)
            Text(label).font(.system(size: 9, design: .rounded)).foregroundStyle(Color.secondary)
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Ring Progress View

struct RingProgressView: View {
    let value: Double
    var color: Color = Color.primary.opacity(0.85)

    var body: some View {
        ZStack {
            Circle().stroke(Color.primary.opacity(0.1), lineWidth: 5)
            Circle()
                .trim(from: 0, to: CGFloat(min(value, 1.0)))
                .stroke(color, style: StrokeStyle(lineWidth: 5, lineCap: .round))
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

// MARK: - Combined Heatmap Grid (one square containing all habit heatmaps)

struct CombinedHeatmapGrid: View {
    let habits: [Habit]
    let recordsByHabit: [PersistentIdentifier: [HabitRecord]]

    private let cols = Array(repeating: GridItem(.flexible(), spacing: 8), count: 2)

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("28일 히트맵")
                .font(.system(.headline, design: .rounded))
                .fontWeight(.bold)

            if habits.isEmpty {
                Text("습관을 추가해보세요")
                    .font(.subheadline).foregroundStyle(Color.secondary)
            } else {
                LazyVGrid(columns: cols, spacing: 12) {
                    ForEach(habits) { habit in
                        HabitMiniCard(
                            habit: habit,
                            records: recordsByHabit[habit.persistentModelID] ?? []
                        )
                        .aspectRatio(1, contentMode: .fit)
                    }
                }
            }
        }
        .padding(20)
        // 전체 카드를 정사각형으로: ScrollView 안에서도 올바르게 작동
        .frame(maxWidth: .infinity)
        .aspectRatio(1, contentMode: .fit)
        .background(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(.ultraThinMaterial)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .stroke(Color.primary.opacity(0.05), lineWidth: 1)
        )
    }
}

struct HabitMiniCard: View {
    let habit: Habit
    let records: [HabitRecord]

    private var heatmapCells: [DayCellData] {
        let cal = Calendar.current
        return (0..<28).reversed().map { offset in
            let date = cal.date(byAdding: .day, value: -offset, to: Date.todayStart)!
            let rec = records.first { $0.date == date }
            return DayCellData(date: date, mark: rec.map { $0.isChecked ? .checked : .failed } ?? .empty)
        }
    }

    // records 파라미터를 직접 사용해 정확한 연속기록 계산
    private var streak: Int {
        var s = 0, day = Date.todayStart
        let cal = Calendar.current
        while records.first(where: { $0.date == day })?.isChecked == true {
            s += 1
            day = cal.date(byAdding: .day, value: -1, to: day)!
        }
        return s
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // 이름 헤더
            HStack(spacing: 4) {
                Circle()
                    .fill(habit.displayColor)
                    .frame(width: 8, height: 8)
                Text(habit.name)
                    .font(.system(size: 13, weight: .semibold, design: .rounded))
                    .lineLimit(1)
                    .foregroundStyle(Color.primary)
                Spacer(minLength: 0)
                if streak > 0 {
                    HStack(spacing: 2) {
                        Image(systemName: "flame.fill").font(.system(size: 10)).foregroundStyle(Color.primary.opacity(0.6))
                        Text("\(streak)").font(.system(size: 11, weight: .bold, design: .rounded)).foregroundStyle(Color.primary.opacity(0.8))
                    }
                }
            }

            BentoHeatmap(cells: heatmapCells, accentColor: habit.displayColor)
        }
        .padding(12)
        .background(RoundedRectangle(cornerRadius: 16, style: .continuous).fill(Color.primary.opacity(0.03)))
        .overlay(RoundedRectangle(cornerRadius: 16, style: .continuous).stroke(Color.primary.opacity(0.05), lineWidth: 1))
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

// MARK: - Habit Trend Chart (꺾은선)

struct HabitTrendChart: View {
    let habits: [Habit]
    let recordsByHabit: [PersistentIdentifier: [HabitRecord]]

    private let weekLabels = ["4주전", "3주전", "2주전", "이번주"]

    struct TrendPoint: Identifiable {
        let id = UUID()
        let habitID: PersistentIdentifier
        let seriesName: String
        let color: Color
        let weekIndex: Int
        let rate: Double
    }

    // 🔴 수정: allRecords 전체 스캔 제거 → 딕셔너리 O(1) 조회
    private func weeklyRate(habitRecords: [HabitRecord], weekOffset: Int) -> Double {
        let cal = Calendar.current
        let today = Date.todayStart
        var checked = 0, total = 7
        for d in 0..<7 {
            guard let date = cal.date(byAdding: .day, value: -(weekOffset * 7 + d), to: today) else { continue }
            if date > today { total -= 1; continue }
            if habitRecords.first(where: { $0.date == date })?.isChecked == true { checked += 1 }
        }
        return total > 0 ? Double(checked) / Double(total) : 0
    }

    private var trendData: [TrendPoint] {
        habits.flatMap { habit in
            let recs = recordsByHabit[habit.persistentModelID] ?? []
            return (0..<4).map { offset in
                TrendPoint(
                    habitID: habit.persistentModelID,
                    seriesName: habit.name,
                    color: habit.displayColor,
                    weekIndex: 3 - offset,
                    rate: weeklyRate(habitRecords: recs, weekOffset: offset)
                )
            }
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("4주 달성 추이")
                .font(.system(.subheadline, design: .rounded))
                .fontWeight(.semibold)

            if habits.isEmpty {
                Text("습관을 추가하면 추이 그래프가 나타납니다.")
                    .font(.subheadline).foregroundStyle(Color.secondary)
                    .padding(.bottom, 8)
            } else {
                Chart {
                    ForEach(habits) { habit in
                        let pts = trendData.filter { $0.habitID == habit.persistentModelID }
                        ForEach(pts) { p in
                            LineMark(
                                x: .value("주", p.weekIndex),
                                y: .value("달성률", p.rate),
                                series: .value("습관", p.seriesName)
                            )
                            .foregroundStyle(habit.displayColor)
                            .interpolationMethod(.catmullRom)
                            .lineStyle(StrokeStyle(lineWidth: 2.5))

                            PointMark(
                                x: .value("주", p.weekIndex),
                                y: .value("달성률", p.rate)
                            )
                            .foregroundStyle(habit.displayColor)
                            .symbolSize(35)
                        }
                    }
                }
                .chartYScale(domain: 0...1)
                .chartXScale(domain: 0...3)
                .chartXAxis {
                    AxisMarks(values: [0, 1, 2, 3]) { val in
                        AxisValueLabel {
                            if let v = val.as(Int.self) {
                                Text(weekLabels[v]).font(.system(size: 9, design: .rounded))
                            }
                        }
                    }
                }
                .chartYAxis {
                    AxisMarks(values: [0, 0.5, 1.0]) { val in
                        AxisGridLine()
                        AxisValueLabel {
                            if let v = val.as(Double.self) {
                                Text("\(Int(v * 100))%").font(.system(size: 9))
                            }
                        }
                    }
                }
                .frame(height: 160)

                // Legend
                LazyVGrid(
                    columns: [GridItem(.flexible()), GridItem(.flexible())],
                    spacing: 6
                ) {
                    ForEach(habits) { habit in
                        HStack(spacing: 6) {
                            RoundedRectangle(cornerRadius: 2)
                                .fill(habit.displayColor)
                                .frame(width: 18, height: 3)
                            Text(habit.name)
                                .font(.system(size: 10, design: .rounded))
                                .foregroundStyle(Color.secondary)
                                .lineLimit(1)
                        }
                    }
                }
                .padding(.top, 4)
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
