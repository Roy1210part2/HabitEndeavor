import SwiftUI
import SwiftData

// MARK: - Main View

struct ScheduleView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \ScheduleItem.createdAt) private var allItems: [ScheduleItem]

    @State private var viewMode: ViewMode = .weekly
    @State private var weekOffset: Int = 0
    @State private var monthOffset: Int = 0
    @State private var selectedDate: Date = Date.todayStart
    @State private var addingForDate: IdentifiableDate?

    enum ViewMode: String, CaseIterable {
        case weekly = "주간"
        case monthly = "월간"
    }

    private let cal = Calendar.current

    private var currentWeekDates: [Date] {
        guard let mon = mondayOf(weekOffset: weekOffset) else { return [] }
        return (0..<7).compactMap { cal.date(byAdding: .day, value: $0, to: mon) }
    }

    private var weekLabel: String {
        guard let f = currentWeekDates.first, let l = currentWeekDates.last else { return "" }
        let fmt = DateFormatter()
        fmt.locale = Locale(identifier: "ko_KR")
        fmt.dateFormat = "M월 d일"
        return "\(fmt.string(from: f)) – \(fmt.string(from: l))"
    }

    private var monthStart: Date {
        var c = cal.dateComponents([.year, .month], from: Date())
        c.month! += monthOffset
        return cal.date(from: c) ?? Date()
    }

    private var monthLabel: String {
        let f = DateFormatter()
        f.locale = Locale(identifier: "ko_KR")
        f.dateFormat = "yyyy년 M월"
        return f.string(from: monthStart)
    }

    var body: some View {
        VStack(spacing: 0) {
            modeToggle
            if viewMode == .weekly {
                weeklyContent
            } else {
                monthlyContent
            }
        }
        .navigationTitle("일정")
        #if os(iOS)
        .navigationBarTitleDisplayMode(.inline)
        #endif
        .sheet(item: $addingForDate) { item in
            AddScheduleSheet(date: item.date)
        }
    }

    // MARK: - Mode Toggle

    private var modeToggle: some View {
        Picker("", selection: $viewMode) {
            ForEach(ViewMode.allCases, id: \.self) { Text($0.rawValue).tag($0) }
        }
        .pickerStyle(.segmented)
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(.ultraThinMaterial)
    }

    // MARK: - Weekly

    private var weeklyContent: some View {
        VStack(spacing: 0) {
            navBar(label: weekLabel,
                   sub: weekOffset == 0 ? "이번 주" : (weekOffset < 0 ? "\(abs(weekOffset))주 전" : "\(weekOffset)주 후"),
                   prev: { withAnimation(.spring(response: 0.3)) { weekOffset -= 1 } },
                   next: { withAnimation(.spring(response: 0.3)) { weekOffset += 1 } })

            ScrollView {
                LazyVStack(spacing: 10) {
                    ForEach(currentWeekDates, id: \.self) { date in
                        WeekDayCard(
                            date: date,
                            items: items(for: date),
                            onAdd: { addingForDate = IdentifiableDate(date) }
                        )
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .padding(.bottom, 20)
            }
        }
    }

    // MARK: - Monthly

    private var monthlyContent: some View {
        VStack(spacing: 0) {
            navBar(label: monthLabel,
                   sub: monthOffset == 0 ? "이번 달" : nil,
                   prev: { withAnimation(.spring(response: 0.3)) { monthOffset -= 1 } },
                   next: { withAnimation(.spring(response: 0.3)) { monthOffset += 1 } })

            ScrollView {
                VStack(spacing: 14) {
                    MonthGrid(
                        monthStart: monthStart,
                        allItems: allItems,
                        selectedDate: $selectedDate
                    )
                    .padding(.horizontal, 16)

                    SelectedDayPanel(
                        date: selectedDate,
                        items: items(for: selectedDate),
                        onAdd: { addingForDate = IdentifiableDate(selectedDate) }
                    )
                    .padding(.horizontal, 16)
                }
                .padding(.vertical, 12)
                .padding(.bottom, 20)
            }
        }
    }

    // MARK: - Nav bar

    private func navBar(label: String, sub: String?, prev: @escaping () -> Void, next: @escaping () -> Void) -> some View {
        HStack(spacing: 12) {
            Button(action: prev) {
                Image(systemName: "chevron.left")
                    .font(.system(size: 14, weight: .semibold))
                    .frame(width: 34, height: 34)
                    .background(Color.primary.opacity(0.08))
                    .clipShape(Circle())
            }
            .buttonStyle(.plain)

            Spacer()

            VStack(spacing: 2) {
                Text(label)
                    .font(.system(.subheadline, design: .rounded))
                    .fontWeight(.bold)
                if let sub {
                    Text(sub)
                        .font(.system(size: 11, design: .rounded))
                        .foregroundStyle(Color.secondary)
                }
            }

            Spacer()

            Button(action: next) {
                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .semibold))
                    .frame(width: 34, height: 34)
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

    func items(for date: Date) -> [ScheduleItem] {
        let d = cal.startOfDay(for: date)
        return allItems
            .filter { $0.date == d }
            .sorted { ($0.time ?? .distantFuture) < ($1.time ?? .distantFuture) }
    }

    private func mondayOf(weekOffset: Int) -> Date? {
        let today = Date.todayStart
        let wd = cal.component(.weekday, from: today)
        let diff = (wd + 5) % 7
        guard let mon = cal.date(byAdding: .day, value: -diff, to: today) else { return nil }
        return cal.date(byAdding: .weekOfYear, value: weekOffset, to: mon)
    }
}

// MARK: - Week Day Card (주간 뷰)

struct WeekDayCard: View {
    let date: Date
    let items: [ScheduleItem]
    let onAdd: () -> Void

    private var isToday: Bool { Calendar.current.isDateInToday(date) }
    private var done: Int { items.filter(\.isCompleted).count }
    private var total: Int { items.count }
    private var progress: Double { total > 0 ? Double(done) / Double(total) : 0 }

    private var dayLabel: String {
        let f = DateFormatter()
        f.locale = Locale(identifier: "ko_KR")
        f.dateFormat = "M.d (E)"
        return f.string(from: date)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header
            HStack(spacing: 8) {
                if isToday {
                    Text("TODAY")
                        .font(.system(size: 10, weight: .black, design: .rounded))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 7)
                        .padding(.vertical, 3)
                        .background(Color.primary)
                        .clipShape(Capsule())
                }
                Text(dayLabel)
                    .font(.system(.subheadline, design: .rounded))
                    .fontWeight(isToday ? .bold : .semibold)
                    .foregroundStyle(isToday ? Color.primary : Color.secondary)
                Spacer()
                if total > 0 {
                    Text("\(done)/\(total)")
                        .font(.system(size: 12, weight: .semibold, design: .rounded))
                        .foregroundStyle(done == total ? Color.green : Color.secondary)
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 14)
            .padding(.bottom, total > 0 ? 8 : 0)

            // Progress bar
            if total > 0 {
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        Capsule().fill(Color.primary.opacity(0.08)).frame(height: 3)
                        Capsule()
                            .fill(done == total ? Color.green : Color.primary.opacity(0.5))
                            .frame(width: geo.size.width * progress, height: 3)
                            .animation(.spring(response: 0.4), value: progress)
                    }
                }
                .frame(height: 3)
                .padding(.horizontal, 16)
                .padding(.bottom, 10)
            }

            // Item list
            if !items.isEmpty {
                Divider().padding(.horizontal, 16)
                VStack(spacing: 0) {
                    ForEach(items) { item in
                        ScheduleRow(item: item)
                        if item.persistentModelID != items.last?.persistentModelID {
                            Divider().padding(.leading, 52)
                        }
                    }
                }
            }

            // Add button
            Divider().padding(.horizontal, 16)
            Button(action: onAdd) {
                HStack(spacing: 6) {
                    Image(systemName: "plus.circle")
                        .font(.system(size: 13))
                    Text("할일 추가")
                        .font(.system(.footnote, design: .rounded))
                }
                .foregroundStyle(Color.secondary)
                .padding(.horizontal, 16)
                .padding(.vertical, 11)
            }
            .buttonStyle(.plain)
        }
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(isToday ? Color.primary.opacity(0.25) : Color.primary.opacity(0.07),
                        lineWidth: isToday ? 1.5 : 1)
        )
        .shadow(color: .black.opacity(isToday ? 0.08 : 0.04), radius: 10, x: 0, y: 4)
    }
}

// MARK: - Schedule Row (핵심: @Bindable로 직접 토글 — 버그 수정)

struct ScheduleRow: View {
    @Environment(\.modelContext) private var modelContext
    @Bindable var item: ScheduleItem

    var body: some View {
        HStack(spacing: 12) {
            // 체크박스 버튼
            Button {
                withAnimation(.spring(response: 0.28, dampingFraction: 0.7)) {
                    item.isCompleted.toggle()
                }
            } label: {
                ZStack {
                    Circle()
                        .stroke(item.isCompleted ? Color.primary : Color.primary.opacity(0.3),
                                lineWidth: 1.5)
                        .frame(width: 26, height: 26)
                    if item.isCompleted {
                        Circle()
                            .fill(Color.primary)
                            .frame(width: 26, height: 26)
                        Image(systemName: "checkmark")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundStyle(Color.cardBackground)
                    }
                }
            }
            .buttonStyle(.plain)

            VStack(alignment: .leading, spacing: 2) {
                Text(item.title)
                    .font(.system(.body, design: .rounded))
                    .strikethrough(item.isCompleted, color: Color.secondary)
                    .foregroundStyle(item.isCompleted ? Color.secondary : Color.primary)
                    .lineLimit(2)
                    .animation(.easeInOut(duration: 0.2), value: item.isCompleted)

                if let t = item.timeLabel {
                    Label(t, systemImage: "clock")
                        .font(.system(size: 11, design: .rounded))
                        .foregroundStyle(Color.secondary)
                }
            }

            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .contentShape(Rectangle())
        .contextMenu {
            Button(role: .destructive) {
                modelContext.delete(item)
            } label: {
                Label("삭제", systemImage: "trash")
            }
        }
    }
}

// MARK: - Month Grid (월간 캘린더 — 셀 크게, 할일 미리보기)

struct MonthGrid: View {
    let monthStart: Date
    let allItems: [ScheduleItem]
    @Binding var selectedDate: Date

    private let cal = Calendar.current
    private let weekdays = ["월", "화", "수", "목", "금", "토", "일"]

    private var gridDays: [Date?] {
        let wd = (cal.component(.weekday, from: monthStart) + 5) % 7
        let range = cal.range(of: .day, in: .month, for: monthStart)!
        var days: [Date?] = Array(repeating: nil, count: wd)
        for d in range {
            days.append(cal.date(byAdding: .day, value: d - 1, to: monthStart))
        }
        while days.count % 7 != 0 { days.append(nil) }
        return days
    }

    private func dayItems(_ date: Date) -> [ScheduleItem] {
        let d = cal.startOfDay(for: date)
        return allItems.filter { $0.date == d }
    }

    var body: some View {
        VStack(spacing: 0) {
            // 요일 헤더
            HStack(spacing: 0) {
                ForEach(weekdays, id: \.self) { wd in
                    Text(wd)
                        .font(.system(size: 12, weight: .semibold, design: .rounded))
                        .foregroundStyle(Color.secondary)
                        .frame(maxWidth: .infinity)
                }
            }
            .padding(.vertical, 10)

            Divider()

            // 날짜 그리드
            let cols = Array(repeating: GridItem(.flexible(), spacing: 0), count: 7)
            LazyVGrid(columns: cols, spacing: 0) {
                ForEach(0..<gridDays.count, id: \.self) { i in
                    if let date = gridDays[i] {
                        MonthDayCell(
                            date: date,
                            items: dayItems(date),
                            isSelected: cal.isDate(date, inSameDayAs: selectedDate),
                            isToday: cal.isDateInToday(date)
                        ) {
                            withAnimation(.spring(response: 0.3)) { selectedDate = date }
                        }
                    } else {
                        Color.clear
                            .frame(height: 76)
                    }
                }
            }
        }
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .stroke(Color.primary.opacity(0.07), lineWidth: 1)
        )
    }
}

// MARK: - Month Day Cell (크게, 할일 미리보기)

struct MonthDayCell: View {
    let date: Date
    let items: [ScheduleItem]
    let isSelected: Bool
    let isToday: Bool
    let onTap: () -> Void

    private var done: Int { items.filter(\.isCompleted).count }
    private var total: Int { items.count }
    private var allDone: Bool { total > 0 && done == total }

    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 3) {
                // 날짜 숫자
                HStack {
                    Text("\(Calendar.current.component(.day, from: date))")
                        .font(.system(size: 14, weight: isToday ? .black : .medium, design: .rounded))
                        .foregroundStyle(
                            isSelected ? Color.cardBackground :
                            isToday    ? Color.primary : Color.primary.opacity(0.8)
                        )
                        .frame(width: 26, height: 26)
                        .background(
                            Circle()
                                .fill(isSelected ? Color.primary :
                                      isToday    ? Color.primary.opacity(0.12) : Color.clear)
                        )
                    Spacer()
                    // 완료 인디케이터
                    if total > 0 {
                        Circle()
                            .fill(allDone ? Color.green : Color.orange)
                            .frame(width: 6, height: 6)
                    }
                }

                // 할일 미리보기 (최대 2개)
                ForEach(Array(items.prefix(2))) { item in
                    HStack(spacing: 3) {
                        Circle()
                            .fill(item.isCompleted ? Color.green : Color.primary.opacity(0.4))
                            .frame(width: 4, height: 4)
                        Text(item.title)
                            .font(.system(size: 9, design: .rounded))
                            .foregroundStyle(Color.secondary)
                            .lineLimit(1)
                    }
                }

                // 더 많은 경우
                if items.count > 2 {
                    Text("+\(items.count - 2)개")
                        .font(.system(size: 8, design: .rounded))
                        .foregroundStyle(Color.secondary.opacity(0.7))
                }

                Spacer(minLength: 0)
            }
            .padding(.horizontal, 5)
            .padding(.vertical, 6)
            .frame(height: 76)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                isSelected ? Color.primary.opacity(0.06) : Color.clear
            )
            .overlay(
                Rectangle()
                    .stroke(Color.primary.opacity(0.06), lineWidth: 0.5)
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Selected Day Panel (월간 뷰 선택일)

struct SelectedDayPanel: View {
    let date: Date
    let items: [ScheduleItem]
    let onAdd: () -> Void

    private var label: String {
        let f = DateFormatter()
        f.locale = Locale(identifier: "ko_KR")
        f.dateFormat = "M월 d일 (E)"
        return f.string(from: date)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                Text(label)
                    .font(.system(.subheadline, design: .rounded))
                    .fontWeight(.bold)
                Spacer()
                Button(action: onAdd) {
                    Image(systemName: "plus.circle.fill")
                        .font(.title3)
                        .symbolRenderingMode(.hierarchical)
                        .foregroundStyle(Color.primary)
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 16)
            .padding(.top, 14)
            .padding(.bottom, 10)

            Divider().padding(.horizontal, 16)

            if items.isEmpty {
                HStack {
                    Image(systemName: "checkmark.circle")
                        .foregroundStyle(Color.secondary)
                    Text("이 날은 할일이 없어요")
                        .font(.system(.subheadline, design: .rounded))
                        .foregroundStyle(Color.secondary)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 16)
            } else {
                VStack(spacing: 0) {
                    ForEach(items) { item in
                        ScheduleRow(item: item)
                        if item.persistentModelID != items.last?.persistentModelID {
                            Divider().padding(.leading, 52)
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
                .stroke(Color.primary.opacity(0.07), lineWidth: 1)
        )
    }
}

// MARK: - Add Schedule Sheet

struct AddScheduleSheet: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss)       private var dismiss

    let date: Date

    @State private var title = ""
    @State private var hasTime = false
    @State private var time = Date()
    @FocusState private var focused: Bool

    private var canSave: Bool { !title.trimmingCharacters(in: .whitespaces).isEmpty }

    private var dateLabel: String {
        let f = DateFormatter()
        f.locale = Locale(identifier: "ko_KR")
        f.dateFormat = "M월 d일 (E)"
        return f.string(from: date)
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // 날짜 표시
                    HStack {
                        Image(systemName: "calendar")
                            .foregroundStyle(Color.secondary)
                        Text(dateLabel)
                            .font(.system(.subheadline, design: .rounded))
                            .fontWeight(.semibold)
                            .foregroundStyle(Color.secondary)
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 8)

                    // 제목
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

                    // 시각 설정
                    VStack(alignment: .leading, spacing: 12) {
                        Toggle(isOn: $hasTime.animation()) {
                            Label("시각 설정", systemImage: "clock")
                                .font(.system(.subheadline, design: .rounded))
                                .fontWeight(.semibold)
                        }
                        .padding(.horizontal, 20)
                        .tint(Color.primary)

                        if hasTime {
                            DatePicker("시각", selection: $time, displayedComponents: .hourAndMinute)
                                #if os(iOS)
                                .datePickerStyle(.wheel)
                                #else
                                .datePickerStyle(.graphical)
                                #endif
                                .labelsHidden()
                                .frame(maxWidth: .infinity)
                                .padding(.horizontal, 20)
                        }
                    }
                }
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
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
        #endif
    }

    private func save() {
        let item = ScheduleItem(
            date: date,
            title: title.trimmingCharacters(in: .whitespaces),
            time: hasTime ? time : nil
        )
        modelContext.insert(item)
        dismiss()
    }
}

// MARK: - IdentifiableDate (Date를 전역 Identifiable 확장하는 대신 안전한 래퍼 사용)

struct IdentifiableDate: Identifiable {
    let date: Date
    var id: TimeInterval { date.timeIntervalSince1970 }
    init(_ date: Date) { self.date = date }
}

#Preview {
    NavigationStack { ScheduleView() }
        .modelContainer(for: ScheduleItem.self, inMemory: true)
}
