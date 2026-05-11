import SwiftUI
import SwiftData

// MARK: - Main View

struct ScheduleView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \ScheduleItem.date) private var allItems: [ScheduleItem]

    @State private var viewMode: ViewMode = .weekly
    @State private var weekOffset: Int    = 0
    @State private var monthOffset: Int   = 0
    @State private var selectedDate: Date = Date.todayStart
    @State private var addingForDate: Date?

    enum ViewMode: String, CaseIterable {
        case weekly  = "주간"
        case monthly = "월간"
    }

    private let cal = Calendar.current

    // MARK: - Week helpers

    private var currentWeekDates: [Date] {
        guard let monday = mondayOf(Date.todayStart, offset: weekOffset) else { return [] }
        return (0..<7).compactMap { cal.date(byAdding: .day, value: $0, to: monday) }
    }

    private var weekRangeLabel: String {
        guard let first = currentWeekDates.first, let last = currentWeekDates.last else { return "" }
        let fmt = DateFormatter()
        fmt.locale = Locale(identifier: "ko_KR")
        fmt.dateFormat = "M월 d일"
        return "\(fmt.string(from: first)) ~ \(fmt.string(from: last))"
    }

    // MARK: - Month helpers

    private var currentMonthComponents: DateComponents {
        var c = cal.dateComponents([.year, .month], from: Date())
        c.month! += monthOffset
        return c
    }

    private var currentMonthStart: Date {
        cal.date(from: currentMonthComponents) ?? Date()
    }

    private var currentMonthLabel: String {
        let fmt = DateFormatter()
        fmt.locale = Locale(identifier: "ko_KR")
        fmt.dateFormat = "yyyy년 M월"
        return fmt.string(from: currentMonthStart)
    }

    // MARK: - Body

    var body: some View {
        VStack(spacing: 0) {
            // 모드 선택
            Picker("보기 모드", selection: $viewMode) {
                ForEach(ViewMode.allCases, id: \.self) { m in
                    Text(m.rawValue).tag(m)
                }
            }
            .pickerStyle(.segmented)
            .padding(.horizontal, 16)
            .padding(.top, 12)
            .padding(.bottom, 8)

            if viewMode == .weekly {
                weeklyContent
            } else {
                monthlyContent
            }
        }
        .navigationTitle("일정 관리")
        #if os(iOS)
        .navigationBarTitleDisplayMode(.large)
        #endif
        .sheet(item: $addingForDate) { date in
            AddScheduleItemSheet(date: date)
        }
    }

    // MARK: - Weekly View

    private var weeklyContent: some View {
        VStack(spacing: 0) {
            // 주간 네비게이션 헤더
            weekNavigationHeader

            ScrollView {
                VStack(spacing: 12) {
                    ForEach(currentWeekDates, id: \.self) { date in
                        DayScheduleCard(
                            date: date,
                            items: items(for: date),
                            onAdd: { addingForDate = date },
                            onToggle: { item in toggle(item) },
                            onDelete: { item in delete(item) }
                        )
                    }
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 32)
                .padding(.top, 8)
            }
        }
    }

    private var weekNavigationHeader: some View {
        HStack(spacing: 16) {
            Button {
                withAnimation(.spring(response: 0.35)) { weekOffset -= 1 }
            } label: {
                Image(systemName: "chevron.left")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(Color.primary)
                    .frame(width: 36, height: 36)
                    .background(Color.primary.opacity(0.08))
                    .clipShape(Circle())
            }
            .buttonStyle(.plain)

            Spacer()

            VStack(spacing: 2) {
                Text(weekRangeLabel)
                    .font(.system(.subheadline, design: .rounded))
                    .fontWeight(.semibold)
                if weekOffset == 0 {
                    Text("이번 주")
                        .font(.caption2)
                        .foregroundStyle(Color.secondary)
                } else {
                    Text(weekOffset < 0 ? "\(abs(weekOffset))주 전" : "\(weekOffset)주 후")
                        .font(.caption2)
                        .foregroundStyle(Color.secondary)
                }
            }

            Spacer()

            Button {
                withAnimation(.spring(response: 0.35)) { weekOffset += 1 }
            } label: {
                Image(systemName: "chevron.right")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(Color.primary)
                    .frame(width: 36, height: 36)
                    .background(Color.primary.opacity(0.08))
                    .clipShape(Circle())
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(.ultraThinMaterial)
    }

    // MARK: - Monthly View

    private var monthlyContent: some View {
        VStack(spacing: 0) {
            monthNavigationHeader

            ScrollView {
                VStack(spacing: 16) {
                    MonthCalendarGrid(
                        monthStart: currentMonthStart,
                        allItems: allItems,
                        selectedDate: $selectedDate,
                        onAddItem: { date in addingForDate = date }
                    )
                    .padding(.horizontal, 16)

                    // 선택 날짜 할일 패널
                    SelectedDayPanel(
                        date: selectedDate,
                        items: items(for: selectedDate),
                        onAdd: { addingForDate = selectedDate },
                        onToggle: toggle,
                        onDelete: delete
                    )
                    .padding(.horizontal, 16)
                }
                .padding(.bottom, 32)
                .padding(.top, 8)
            }
        }
    }

    private var monthNavigationHeader: some View {
        HStack(spacing: 16) {
            Button {
                withAnimation(.spring(response: 0.35)) { monthOffset -= 1 }
            } label: {
                Image(systemName: "chevron.left")
                    .font(.system(size: 15, weight: .semibold))
                    .frame(width: 36, height: 36)
                    .background(Color.primary.opacity(0.08))
                    .clipShape(Circle())
            }
            .buttonStyle(.plain)

            Spacer()

            Text(currentMonthLabel)
                .font(.system(.subheadline, design: .rounded))
                .fontWeight(.semibold)

            Spacer()

            Button {
                withAnimation(.spring(response: 0.35)) { monthOffset += 1 }
            } label: {
                Image(systemName: "chevron.right")
                    .font(.system(size: 15, weight: .semibold))
                    .frame(width: 36, height: 36)
                    .background(Color.primary.opacity(0.08))
                    .clipShape(Circle())
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(.ultraThinMaterial)
    }

    // MARK: - Helpers

    private func items(for date: Date) -> [ScheduleItem] {
        let dayStart = Calendar.current.startOfDay(for: date)
        return allItems.filter { $0.date == dayStart }
    }

    private func toggle(_ item: ScheduleItem) {
        withAnimation(.spring(response: 0.3)) {
            item.isCompleted.toggle()
        }
    }

    private func delete(_ item: ScheduleItem) {
        modelContext.delete(item)
    }

    private func mondayOf(_ date: Date, offset: Int) -> Date? {
        let weekday = cal.component(.weekday, from: date) // 1=일, 2=월
        let daysFromMon = (weekday + 5) % 7
        guard let monday = cal.date(byAdding: .day, value: -daysFromMon, to: date) else { return nil }
        return cal.date(byAdding: .weekOfYear, value: offset, to: monday)
    }
}

// MARK: - Day Schedule Card (주간 뷰)

struct DayScheduleCard: View {
    let date: Date
    let items: [ScheduleItem]
    let onAdd: () -> Void
    let onToggle: (ScheduleItem) -> Void
    let onDelete: (ScheduleItem) -> Void

    private var isToday: Bool { Calendar.current.isDateInToday(date) }
    private var completedCount: Int { items.filter(\.isCompleted).count }
    private var totalCount: Int { items.count }

    private var dayLabel: String {
        let fmt = DateFormatter()
        fmt.locale = Locale(identifier: "ko_KR")
        fmt.dateFormat = "M월 d일 (E)"
        return fmt.string(from: date)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // 날짜 헤더
            HStack(spacing: 8) {
                if isToday {
                    Text("오늘")
                        .font(.system(size: 11, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(Color.primary)
                        .clipShape(Capsule())
                }

                Text(dayLabel)
                    .font(.system(.subheadline, design: .rounded))
                    .fontWeight(isToday ? .bold : .semibold)
                    .foregroundStyle(isToday ? Color.primary : Color.secondary)

                Spacer()

                if totalCount > 0 {
                    Text("\(completedCount)/\(totalCount)")
                        .font(.system(size: 11, weight: .medium, design: .rounded))
                        .foregroundStyle(Color.secondary)
                }
            }
            .padding(.horizontal, 14)
            .padding(.top, 12)
            .padding(.bottom, items.isEmpty ? 12 : 8)

            // 할일 목록
            if !items.isEmpty {
                Divider().padding(.horizontal, 14)

                VStack(spacing: 0) {
                    ForEach(items) { item in
                        ScheduleItemRow(
                            item: item,
                            onToggle: { onToggle(item) },
                            onDelete: { onDelete(item) }
                        )
                        if item.persistentModelID != items.last?.persistentModelID {
                            Divider().padding(.leading, 50)
                        }
                    }
                }
            }

            // 추가 버튼
            Divider().padding(.horizontal, 14)

            Button(action: onAdd) {
                Label("할일 추가", systemImage: "plus.circle")
                    .font(.system(.footnote, design: .rounded))
                    .foregroundStyle(Color.secondary)
            }
            .buttonStyle(.plain)
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
        }
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(
                    isToday ? Color.primary.opacity(0.2) : Color.primary.opacity(0.06),
                    lineWidth: isToday ? 1.5 : 1
                )
        )
        .shadow(color: .black.opacity(isToday ? 0.06 : 0.03), radius: 8, x: 0, y: 3)
    }
}

// MARK: - Schedule Item Row

struct ScheduleItemRow: View {
    let item: ScheduleItem
    let onToggle: () -> Void
    let onDelete: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            Button(action: onToggle) {
                ZStack {
                    Circle()
                        .strokeBorder(
                            item.isCompleted ? Color.primary : Color.primary.opacity(0.3),
                            lineWidth: 1.5
                        )
                        .frame(width: 24, height: 24)
                        .background(
                            Circle().fill(item.isCompleted ? Color.primary : Color.clear)
                        )

                    if item.isCompleted {
                        Image(systemName: "checkmark")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundStyle(Color.cardBackground)
                    }
                }
            }
            .buttonStyle(.plain)

            Text(item.title)
                .font(.system(.body, design: .rounded))
                .strikethrough(item.isCompleted, color: Color.secondary)
                .foregroundStyle(item.isCompleted ? Color.secondary : Color.primary)
                .lineLimit(2)

            Spacer()
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 11)
        .contentShape(Rectangle())
        .contextMenu {
            Button(role: .destructive, action: onDelete) {
                Label("삭제", systemImage: "trash")
            }
        }
    }
}

// MARK: - Monthly Calendar Grid

struct MonthCalendarGrid: View {
    let monthStart: Date
    let allItems: [ScheduleItem]
    @Binding var selectedDate: Date
    let onAddItem: (Date) -> Void

    private let cal = Calendar.current
    private let weekdayLabels = ["월", "화", "수", "목", "금", "토", "일"]
    private let columns = Array(repeating: GridItem(.flexible(), spacing: 4), count: 7)

    // 월의 모든 날짜 (앞뒤 빈칸 포함)
    private var calendarDays: [Date?] {
        let startWeekday = (cal.component(.weekday, from: monthStart) + 5) % 7 // 0=월
        let range = cal.range(of: .day, in: .month, for: monthStart)!
        var days: [Date?] = Array(repeating: nil, count: startWeekday)
        for day in range {
            days.append(cal.date(byAdding: .day, value: day - 1, to: monthStart))
        }
        // 7의 배수로 채우기
        while days.count % 7 != 0 { days.append(nil) }
        return days
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // 요일 헤더
            HStack(spacing: 4) {
                ForEach(weekdayLabels, id: \.self) { label in
                    Text(label)
                        .font(.system(size: 11, weight: .semibold, design: .rounded))
                        .foregroundStyle(Color.secondary)
                        .frame(maxWidth: .infinity)
                }
            }

            // 날짜 그리드
            LazyVGrid(columns: columns, spacing: 4) {
                ForEach(0..<calendarDays.count, id: \.self) { idx in
                    if let date = calendarDays[idx] {
                        CalendarDayCell(
                            date: date,
                            items: dayItems(date),
                            isSelected: cal.isDate(date, inSameDayAs: selectedDate),
                            isToday: cal.isDateInToday(date)
                        ) {
                            selectedDate = date
                        }
                    } else {
                        Color.clear.aspectRatio(1, contentMode: .fit)
                    }
                }
            }
        }
        .padding(16)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .stroke(Color.primary.opacity(0.06), lineWidth: 1)
        )
    }

    private func dayItems(_ date: Date) -> [ScheduleItem] {
        let d = cal.startOfDay(for: date)
        return allItems.filter { $0.date == d }
    }
}

// MARK: - Calendar Day Cell

struct CalendarDayCell: View {
    let date: Date
    let items: [ScheduleItem]
    let isSelected: Bool
    let isToday: Bool
    let onTap: () -> Void

    private var completedAll: Bool { !items.isEmpty && items.allSatisfy(\.isCompleted) }
    private var hasItems: Bool { !items.isEmpty }

    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 3) {
                Text("\(Calendar.current.component(.day, from: date))")
                    .font(.system(size: 13, weight: isToday ? .bold : .regular, design: .rounded))
                    .foregroundStyle(
                        isSelected ? (isToday ? .white : .white) :
                        isToday    ? Color.primary :
                                     Color.primary.opacity(0.85)
                    )

                // 할일 도트 인디케이터
                if hasItems {
                    Circle()
                        .fill(completedAll ? Color.green : Color.orange)
                        .frame(width: 5, height: 5)
                } else {
                    Color.clear.frame(width: 5, height: 5)
                }
            }
            .frame(maxWidth: .infinity)
            .aspectRatio(1, contentMode: .fit)
            .background(
                Group {
                    if isSelected {
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color.primary)
                    } else if isToday {
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color.primary.opacity(0.1))
                    } else {
                        Color.clear
                    }
                }
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Selected Day Panel (월간 뷰 하단)

struct SelectedDayPanel: View {
    let date: Date
    let items: [ScheduleItem]
    let onAdd: () -> Void
    let onToggle: (ScheduleItem) -> Void
    let onDelete: (ScheduleItem) -> Void

    private var dayLabel: String {
        let fmt = DateFormatter()
        fmt.locale = Locale(identifier: "ko_KR")
        fmt.dateFormat = "M월 d일 (E)"
        return fmt.string(from: date)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                Text(dayLabel)
                    .font(.system(.subheadline, design: .rounded))
                    .fontWeight(.semibold)
                Spacer()
                Button(action: onAdd) {
                    Image(systemName: "plus.circle.fill")
                        .font(.title3)
                        .foregroundStyle(Color.primary)
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 16)
            .padding(.top, 14)
            .padding(.bottom, 10)

            if items.isEmpty {
                Text("이 날의 할일이 없어요")
                    .font(.subheadline)
                    .foregroundStyle(Color.secondary)
                    .padding(.horizontal, 16)
                    .padding(.bottom, 16)
            } else {
                Divider().padding(.horizontal, 16)

                VStack(spacing: 0) {
                    ForEach(items) { item in
                        ScheduleItemRow(
                            item: item,
                            onToggle: { onToggle(item) },
                            onDelete: { onDelete(item) }
                        )
                        if item.persistentModelID != items.last?.persistentModelID {
                            Divider().padding(.leading, 50)
                        }
                    }
                }
                .padding(.bottom, 8)
            }
        }
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .stroke(Color.primary.opacity(0.06), lineWidth: 1)
        )
    }
}

// MARK: - Add Schedule Item Sheet

struct AddScheduleItemSheet: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    let date: Date

    @State private var title = ""
    @FocusState private var focused: Bool

    private var canSave: Bool { !title.trimmingCharacters(in: .whitespaces).isEmpty }

    private var dateLabel: String {
        let fmt = DateFormatter()
        fmt.locale = Locale(identifier: "ko_KR")
        fmt.dateFormat = "M월 d일 (E)"
        return fmt.string(from: date)
    }

    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 20) {
                Text(dateLabel)
                    .font(.system(.title3, design: .rounded))
                    .fontWeight(.bold)
                    .padding(.horizontal, 20)
                    .padding(.top, 20)

                TextField("할일을 입력하세요", text: $title)
                    .font(.system(.body, design: .rounded))
                    .padding(.horizontal, 16)
                    .padding(.vertical, 14)
                    .background(Color.primary.opacity(0.06))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .padding(.horizontal, 20)
                    .submitLabel(.done)
                    .onSubmit { if canSave { save() } }
                    .focused($focused)

                Spacer()
            }
            .navigationTitle("할일 추가")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("취소") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("추가") { save() }
                        .fontWeight(.semibold)
                        .disabled(!canSave)
                }
            }
            .onAppear { focused = true }
        }
        #if os(iOS)
        .presentationDetents([.fraction(0.35)])
        .presentationDragIndicator(.visible)
        #endif
    }

    private func save() {
        let item = ScheduleItem(date: date, title: title.trimmingCharacters(in: .whitespaces))
        modelContext.insert(item)
        dismiss()
    }
}

// MARK: - Identifiable for Date (sheet(item:) 사용)

extension Date: @retroactive Identifiable {
    public var id: TimeInterval { timeIntervalSince1970 }
}

#Preview {
    NavigationStack { ScheduleView() }
        .modelContainer(for: ScheduleItem.self, inMemory: true)
}
