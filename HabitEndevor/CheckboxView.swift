import SwiftUI
import SwiftData

struct CheckboxView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Habit.sortOrder) private var habits: [Habit]
    @Query private var allRecords: [HabitRecord]
    @Query private var settingsArray: [AppSettings]

    @State private var showAddHabit = false
    @State private var selectedRecord: HabitRecord?

    private var settings: AppSettings {
        settingsArray.first ?? AppSettings()
    }

    private var weekDates: [Date] {
        Date().weekDates(startsOnMonday: settings.weekStartsOnMonday)
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                weekHeaderRow
                    .padding(.bottom, 6)

                Divider()

                ForEach(habits.filter(\.isActive)) { habit in
                    HabitRowView(
                        habit: habit,
                        weekDates: weekDates,
                        records: records(for: habit),
                        onTap: { date in handleTap(habit: habit, date: date) },
                        onLongPress: { date in handleLongPress(habit: habit, date: date) }
                    )
                    Divider()
                }

                addHabitButton
                    .padding(.top, 16)
            }
            .padding(.horizontal, 16)
            .padding(.top, 8)
        }
        .navigationTitle("HabitEndeavor")
        .toolbar {
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
    }

    // MARK: - Header

    private var weekHeaderRow: some View {
        HStack(spacing: 0) {
            Spacer().frame(width: 110)
            ForEach(weekDates, id: \.self) { date in
                VStack(spacing: 2) {
                    Text(date.koreanWeekday())
                        .font(.caption2)
                        .foregroundStyle(date.isToday ? Color.primary : Color.secondary)
                    Text("\(date.dayNumber())")
                        .font(.caption)
                        .fontWeight(date.isToday ? .bold : .regular)
                        .foregroundStyle(date.isToday ? Color.primary : Color.secondary)
                }
                .frame(maxWidth: .infinity)
            }
        }
        .padding(.top, 12)
    }

    // MARK: - Add Button

    private var addHabitButton: some View {
        Button {
            showAddHabit = true
        } label: {
            Label("습관 추가", systemImage: "plus.circle")
                .font(.subheadline)
                .foregroundStyle(Color.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.bottom, 20)
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

    private func handleTap(habit: Habit, date: Date) {
        if let existing = record(for: habit, on: date) {
            CoinService.handleToggle(record: existing)
        } else {
            let newRecord = HabitRecord(date: date, habit: habit)
            modelContext.insert(newRecord)
            newRecord.isChecked = true
            if date == Date.todayStart {
                newRecord.coinPaidAt = Date()
            }
        }
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
            // 왼쪽: 이름 + 달성률
            VStack(alignment: .leading, spacing: 3) {
                Text(habit.name)
                    .font(.system(.body, design: .rounded))
                    .fontWeight(.semibold)
                    .lineLimit(1)
                    .truncationMode(.tail)
                Text("\(Int(weeklyRate * 100))%")
                    .font(.footnote)
                    .foregroundStyle(Color.secondary)
            }
            .frame(width: 110, alignment: .leading)

            // 오른쪽: 7개 체크박스
            ForEach(weekDates, id: \.self) { date in
                let rec = records.first { $0.date == date }
                CheckboxCell(
                    isChecked: rec?.isChecked ?? false,
                    isFuture: date.isFuture,
                    isToday: date.isToday
                )
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
        .padding(.vertical, 10)
    }
}

// MARK: - Checkbox Cell

struct CheckboxCell: View {
    let isChecked: Bool
    let isFuture: Bool
    let isToday: Bool

    @Environment(\.colorScheme) private var colorScheme

    private var checkmarkColor: Color {
        colorScheme == .dark ? .black : .white
    }

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 6)
                .fill(isChecked ? Color.primary : Color.clear)

            RoundedRectangle(cornerRadius: 6)
                .stroke(Color.primary.opacity(isFuture ? 0.2 : 0.5), lineWidth: 1.5)

            if isChecked {
                Image(systemName: "checkmark")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(checkmarkColor)
            }
        }
        .frame(width: 34, height: 34)
        .opacity(isFuture ? 0.35 : 1.0)
        .background(
            isToday
                ? RoundedRectangle(cornerRadius: 8)
                    .fill(Color.primary.opacity(0.05))
                    .padding(-4)
                : nil
        )
    }
}

#Preview {
    NavigationStack {
        CheckboxView()
    }
    .modelContainer(for: [Habit.self, HabitRecord.self, AppSettings.self], inMemory: true)
}
