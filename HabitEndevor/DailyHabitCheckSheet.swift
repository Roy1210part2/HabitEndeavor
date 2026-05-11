import SwiftUI
import SwiftData

// MARK: - Daily Habit Check Sheet

struct DailyHabitCheckSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Habit.sortOrder) private var habits: [Habit]
    @Query private var allRecords: [HabitRecord]

    @State private var currentIndex = 0

    private var activeHabits: [Habit] { habits.filter(\.isActive) }
    private var today: Date { Calendar.current.startOfDay(for: Date()) }

    var body: some View {
        NavigationStack {
            if activeHabits.isEmpty {
                emptyView
            } else {
                VStack(spacing: 0) {
                    progressHeader
                    pageContent
                    navigationButtons
                }
            }
        }
        .presentationDragIndicator(.visible)
        #if os(iOS)
        .presentationDetents([.large])
        #endif
        .onAppear { currentIndex = 0 }
    }

    // MARK: - Progress Header

    private var progressHeader: some View {
        HStack {
            Button("닫기") { dismiss() }
                .font(.system(.body, design: .rounded))
                .foregroundStyle(Color.secondary)

            Spacer()

            Text("\(currentIndex + 1) / \(activeHabits.count)")
                .font(.system(.subheadline, design: .rounded))
                .fontWeight(.semibold)
                .foregroundStyle(Color.secondary)

            Spacer()

            // Placeholder for alignment
            Text("닫기").opacity(0)
        }
        .padding(.horizontal, 20)
        .padding(.top, 12)
        .padding(.bottom, 8)

        // Progress dots (max 9 visible)
        .overlay(alignment: .bottom) {
            HStack(spacing: 5) {
                ForEach(dotRange, id: \.self) { i in
                    Capsule()
                        .fill(i == currentIndex ? Color.primary : Color.primary.opacity(0.2))
                        .frame(width: i == currentIndex ? 16 : 6, height: 6)
                        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: currentIndex)
                }
            }
            .padding(.bottom, -4)
        }
    }

    private var dotRange: Range<Int> {
        let total = activeHabits.count
        if total <= 9 { return 0..<total }
        let start = max(0, min(currentIndex - 4, total - 9))
        return start..<(start + 9)
    }

    // MARK: - Page Content

    private var pageContent: some View {
        TabView(selection: $currentIndex) {
            ForEach(0..<activeHabits.count, id: \.self) { idx in
                let habit = activeHabits[idx]
                HabitCheckPage(
                    habit: habit,
                    record: record(for: habit),
                    today: today,
                    onToggleCheck: { toggleCheck(habit: habit) },
                    onToggleFail: { toggleFail(habit: habit) },
                    onUpdateFailureNote: { tag, note in updateFailureNote(habit: habit, tag: tag, note: note) }
                )
                .tag(idx)
            }
        }
        .tabViewStyle(.page(indexDisplayMode: .never))
        .animation(.easeInOut(duration: 0.25), value: currentIndex)
    }

    // MARK: - Navigation Buttons

    private var navigationButtons: some View {
        HStack(spacing: 12) {
            if currentIndex > 0 {
                Button {
                    withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                        currentIndex -= 1
                    }
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "chevron.left")
                        Text("이전")
                    }
                    .font(.system(.body, design: .rounded))
                    .fontWeight(.medium)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(Color.primary.opacity(0.07))
                    .clipShape(RoundedRectangle(cornerRadius: 14))
                }
                .buttonStyle(.plain)
            }

            Button {
                if currentIndex < activeHabits.count - 1 {
                    withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                        currentIndex += 1
                    }
                } else {
                    dismiss()
                }
            } label: {
                HStack(spacing: 6) {
                    Text(currentIndex < activeHabits.count - 1 ? "다음" : "완료")
                    Image(systemName: currentIndex < activeHabits.count - 1 ? "chevron.right" : "checkmark")
                }
                .font(.system(.body, design: .rounded))
                .fontWeight(.semibold)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(Color.primary)
                .foregroundStyle(Color.cardBackground)
                .clipShape(RoundedRectangle(cornerRadius: 14))
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 20)
        .padding(.bottom, 24)
        .padding(.top, 12)
    }

    // MARK: - Empty

    private var emptyView: some View {
        VStack(spacing: 16) {
            Image(systemName: "sparkles")
                .font(.system(size: 48))
                .foregroundStyle(Color.secondary)
            Text("추가된 습관이 없어요")
                .font(.system(.title3, design: .rounded))
                .fontWeight(.semibold)
            Text("체크박스 탭에서 습관을 먼저 추가해보세요.")
                .font(.system(.subheadline, design: .rounded))
                .foregroundStyle(Color.secondary)
                .multilineTextAlignment(.center)
            Button("닫기") { dismiss() }
                .font(.system(.body, design: .rounded))
                .padding(.top, 8)
        }
        .padding(32)
        .navigationTitle("오늘 습관 체크")
        #if os(iOS)
        .navigationBarTitleDisplayMode(.inline)
        #endif
    }

    // MARK: - Data Helpers

    private func record(for habit: Habit) -> HabitRecord? {
        allRecords.first {
            $0.date == today && $0.habit?.persistentModelID == habit.persistentModelID
        }
    }

    private func toggleCheck(habit: Habit) {
        if let r = record(for: habit) {
            if r.isChecked {
                r.isChecked = false
                CoinService.revokeIfToday(record: r)
            } else {
                modelContext.delete(r)
            }
        } else {
            let r = HabitRecord(date: today, habit: habit)
            modelContext.insert(r)
            r.isChecked = true
            CoinService.awardIfToday(record: r)
        }
        try? modelContext.save()
    }

    private func toggleFail(habit: Habit) {
        if let r = record(for: habit) {
            if r.isChecked {
                r.isChecked = false
                CoinService.revokeIfToday(record: r)
            } else {
                modelContext.delete(r)
            }
        } else {
            let r = HabitRecord(date: today, habit: habit)
            modelContext.insert(r)
            r.isChecked = false
        }
        try? modelContext.save()
    }

    private func updateFailureNote(habit: Habit, tag: EmotionTag?, note: String) {
        guard let r = record(for: habit), !r.isChecked else { return }
        r.emotionTag  = tag?.rawValue
        r.failureNote = note.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? nil : note
        try? modelContext.save()
    }
}

// MARK: - Single Habit Page

private struct HabitCheckPage: View {
    let habit: Habit
    let record: HabitRecord?
    let today: Date
    let onToggleCheck: () -> Void
    let onToggleFail: () -> Void
    let onUpdateFailureNote: (EmotionTag?, String) -> Void

    @State private var localTag: EmotionTag? = nil
    @State private var localNote: String = ""
    @State private var showNoteField = false

    private var isChecked: Bool { record?.isChecked == true }
    private var isFailed: Bool { record != nil && record?.isChecked == false }
    private var habitColor: Color { habit.displayColor }

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                habitCard
                checkButtons
                if isFailed {
                    failureNoteSection
                        .transition(.opacity.combined(with: .move(edge: .top)))
                }
                Spacer(minLength: 8)
            }
            .padding(.horizontal, 20)
            .padding(.top, 20)
            .padding(.bottom, 12)
        }
        .onAppear { syncLocalState() }
        .onChange(of: record?.emotionTag) { _, _ in syncLocalState() }
        .onChange(of: record?.failureNote) { _, _ in syncLocalState() }
    }

    // MARK: Habit Card

    private var habitCard: some View {
        VStack(spacing: 14) {
            Text(habit.emoji)
                .font(.system(size: 72))
            Text(habit.name)
                .font(.system(.title2, design: .rounded))
                .fontWeight(.bold)
                .multilineTextAlignment(.center)
                .foregroundStyle(Color.primary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 36)
        .background(
            habitColor.opacity(0.12)
                .clipShape(RoundedRectangle(cornerRadius: 24))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 24)
                .stroke(habitColor.opacity(isChecked ? 0.6 : isFailed ? 0.3 : 0.15), lineWidth: 1.5)
        )
    }

    // MARK: Check / Fail Buttons

    private var checkButtons: some View {
        HStack(spacing: 14) {
            // 완료 버튼
            Button(action: { withAnimation(.spring(response: 0.25)) { onToggleCheck() } }) {
                VStack(spacing: 8) {
                    Image(systemName: isChecked ? "checkmark.circle.fill" : "checkmark.circle")
                        .font(.system(size: 34))
                        .foregroundStyle(isChecked ? .green : Color.secondary)
                    Text("완료했어요")
                        .font(.system(.footnote, design: .rounded))
                        .fontWeight(.semibold)
                        .foregroundStyle(isChecked ? .green : Color.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 18)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(isChecked ? Color.green.opacity(0.12) : Color.primary.opacity(0.05))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(isChecked ? Color.green.opacity(0.5) : Color.clear, lineWidth: 2)
                )
                .scaleEffect(isChecked ? 1.02 : 1.0)
                .animation(.spring(response: 0.3), value: isChecked)
            }
            .buttonStyle(.plain)

            // 못했어요 버튼
            Button(action: { withAnimation(.spring(response: 0.25)) { onToggleFail() } }) {
                VStack(spacing: 8) {
                    Image(systemName: isFailed ? "xmark.circle.fill" : "xmark.circle")
                        .font(.system(size: 34))
                        .foregroundStyle(isFailed ? .red : Color.secondary)
                    Text("못했어요")
                        .font(.system(.footnote, design: .rounded))
                        .fontWeight(.semibold)
                        .foregroundStyle(isFailed ? .red : Color.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 18)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(isFailed ? Color.red.opacity(0.10) : Color.primary.opacity(0.05))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(isFailed ? Color.red.opacity(0.45) : Color.clear, lineWidth: 2)
                )
                .scaleEffect(isFailed ? 1.02 : 1.0)
                .animation(.spring(response: 0.3), value: isFailed)
            }
            .buttonStyle(.plain)
        }
    }

    // MARK: Failure Note Section

    private var failureNoteSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Text("어떤 이유였나요?")
                    .font(.system(.subheadline, design: .rounded))
                    .fontWeight(.semibold)
                Spacer()
            }

            // Emotion tag grid
            let columns = [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())]
            LazyVGrid(columns: columns, spacing: 10) {
                ForEach(EmotionTag.allCases) { tag in
                    Button {
                        withAnimation(.spring(response: 0.2)) {
                            localTag = (localTag == tag) ? nil : tag
                        }
                        onUpdateFailureNote(localTag, localNote)
                        #if os(iOS)
                        UISelectionFeedbackGenerator().selectionChanged()
                        #endif
                    } label: {
                        VStack(spacing: 5) {
                            Text(tag.icon).font(.system(size: 24))
                            Text(tag.label)
                                .font(.system(size: 11, weight: .medium, design: .rounded))
                                .foregroundStyle(localTag == tag ? Color.primary : Color.secondary)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(localTag == tag ? Color.primary.opacity(0.1) : Color.primary.opacity(0.04))
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(localTag == tag ? Color.primary.opacity(0.4) : Color.clear, lineWidth: 1.5)
                        )
                        .scaleEffect(localTag == tag ? 1.03 : 1.0)
                    }
                    .buttonStyle(.plain)
                }
            }

            // Memo toggle
            Button {
                withAnimation(.easeInOut(duration: 0.2)) { showNoteField.toggle() }
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: showNoteField ? "chevron.up" : "pencil")
                        .font(.caption)
                    Text(showNoteField ? "메모 접기" : "더 자세히 메모하기")
                        .font(.system(.footnote, design: .rounded))
                }
                .foregroundStyle(Color.secondary)
            }

            if showNoteField {
                TextField("메모 (선택사항)", text: $localNote, axis: .vertical)
                    .lineLimit(2...4)
                    .font(.body)
                    .padding(12)
                    .background(Color.primary.opacity(0.05))
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                    .onChange(of: localNote) { _, _ in
                        onUpdateFailureNote(localTag, localNote)
                    }
                    .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.primary.opacity(0.04))
        )
    }

    // MARK: Sync

    private func syncLocalState() {
        localTag = EmotionTag(rawValue: record?.emotionTag ?? "")
        localNote = record?.failureNote ?? ""
        showNoteField = !(record?.failureNote ?? "").isEmpty
    }
}

// MARK: - Splash View

struct SplashView: View {
    var body: some View {
        ZStack {
            LinearGradient(
                stops: [
                    .init(color: Color(red: 0.27, green: 0.12, blue: 0.51), location: 0),
                    .init(color: Color(red: 0.95, green: 0.42, blue: 0.18), location: 0.52),
                    .init(color: Color(red: 1.0,  green: 0.78, blue: 0.32), location: 1.0),
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            VStack(spacing: 22) {
                SunsetIconView(size: 120)
                    .shadow(color: .black.opacity(0.25), radius: 16, x: 0, y: 6)

                Text("Habit Endeavor")
                    .font(.system(.title2, design: .rounded))
                    .fontWeight(.bold)
                    .foregroundStyle(.white)
                    .shadow(color: .black.opacity(0.2), radius: 4, x: 0, y: 2)
            }
        }
    }
}

#Preview("Daily Check") {
    DailyHabitCheckSheet()
        .modelContainer(for: [Habit.self, HabitRecord.self], inMemory: true)
}

#Preview("Splash") {
    SplashView()
}
