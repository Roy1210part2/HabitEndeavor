import SwiftUI
import SwiftData

struct AddHabitSheet: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss)      private var dismiss

    let nextSortOrder: Int

    @State private var name             = ""
    @State private var emoji            = "⭐️"
    @State private var selectedColorHex = habitColorPalette[5]
    @State private var showEmojiPicker  = false

    private var selectedColor: Color { Color(hex: selectedColorHex) ?? .blue }
    private var canSave: Bool { !name.trimmingCharacters(in: .whitespaces).isEmpty }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {

                    // ── 색상 선택 (맨 위, 항상 보임) ──
                    VStack(alignment: .leading, spacing: 10) {
                        Label("색상 선택", systemImage: "paintpalette")
                            .font(.system(.subheadline, design: .rounded))
                            .fontWeight(.semibold)
                            .foregroundStyle(Color.secondary)

                        colorGrid
                    }

                    // ── 이모지 + 이름 ──
                    VStack(alignment: .leading, spacing: 10) {
                        Label("습관 정보", systemImage: "pencil")
                            .font(.system(.subheadline, design: .rounded))
                            .fontWeight(.semibold)
                            .foregroundStyle(Color.secondary)

                        HStack(spacing: 12) {
                            Button { showEmojiPicker.toggle() } label: {
                                ZStack {
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(selectedColor)
                                        .frame(width: 52, height: 52)
                                    Text(emoji).font(.title2)
                                }
                            }
                            .buttonStyle(.plain)

                            TextField("습관 이름 (예: 운동, 독서)", text: $name)
                                .font(.system(.body, design: .rounded))
                                .submitLabel(.done)
                                .onSubmit { if canSave { save() } }
                                .padding(.horizontal, 12)
                                .padding(.vertical, 12)
                                .background(
                                    RoundedRectangle(cornerRadius: 10)
                                        .fill(Color.primary.opacity(0.06))
                                )
                        }
                    }

                    // ── 이모지 선택 ──
                    if showEmojiPicker {
                        VStack(alignment: .leading, spacing: 10) {
                            Label("이모지 선택", systemImage: "face.smiling")
                                .font(.system(.subheadline, design: .rounded))
                                .fontWeight(.semibold)
                                .foregroundStyle(Color.secondary)

                            emojiGrid
                        }
                    }
                }
                .padding(20)
            }
            .navigationTitle("습관 추가")
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
        }
        #if os(iOS)
        .presentationDetents([.large])
        .presentationDragIndicator(.visible)
        #endif
    }

    // MARK: - 색상 그리드

    private var colorGrid: some View {
        let cols = Array(repeating: GridItem(.flexible(), spacing: 10), count: 6)
        return LazyVGrid(columns: cols, spacing: 10) {
            ForEach(habitColorPalette, id: \.self) { hex in
                let c = Color(hex: hex) ?? .blue
                let isSelected = selectedColorHex == hex
                Circle()
                    .fill(c)
                    .frame(height: 40)
                    .overlay(
                        Circle()
                            .stroke(.white, lineWidth: isSelected ? 3 : 0)
                            .padding(3)
                    )
                    .overlay(
                        Circle()
                            .stroke(c, lineWidth: isSelected ? 2 : 0)
                    )
                    .scaleEffect(isSelected ? 1.15 : 1.0)
                    .animation(.spring(response: 0.25), value: isSelected)
                    .onTapGesture {
                        selectedColorHex = hex
                        #if os(iOS)
                        UISelectionFeedbackGenerator().selectionChanged()
                        #endif
                    }
            }
        }
    }

    // MARK: - 이모지 그리드

    private let emojis = [
        "⭐️", "🔥", "💪", "🏃", "🧘", "📚", "✍️",
        "🎯", "🎨", "🎵", "🍎", "💧", "😴", "🧹", "💻",
        "📝", "🏋️", "🚴", "🌱", "🧠", "❤️", "💊", "🛁",
        "☀️", "🌙", "🍵", "🥗", "🙏", "📖", "🎤", "🌍",
    ]

    private var emojiGrid: some View {
        let cols = Array(repeating: GridItem(.flexible()), count: 8)
        return LazyVGrid(columns: cols, spacing: 8) {
            ForEach(emojis, id: \.self) { e in
                Button {
                    emoji = e
                    showEmojiPicker = false
                } label: {
                    Text(e)
                        .font(.title3)
                        .frame(width: 36, height: 36)
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .fill(emoji == e ? selectedColor.opacity(0.2) : Color.clear)
                        )
                }
                .buttonStyle(.plain)
            }
        }
    }

    private func save() {
        let habit = Habit(
            name: name.trimmingCharacters(in: .whitespaces),
            emoji: emoji,
            sortOrder: nextSortOrder,
            colorHex: selectedColorHex
        )
        modelContext.insert(habit)
        dismiss()
    }
}

// ColorPaletteView — 다른 곳에서도 재사용 가능하도록 유지

struct ColorPaletteView: View {
    @Binding var selectedHex: String

    private let columns = Array(repeating: GridItem(.flexible()), count: 6)

    var body: some View {
        LazyVGrid(columns: columns, spacing: 10) {
            ForEach(habitColorPalette, id: \.self) { hex in
                let c = Color(hex: hex) ?? .blue
                let isSelected = selectedHex == hex
                Circle()
                    .fill(c)
                    .frame(height: 36)
                    .overlay(Circle().stroke(.white, lineWidth: isSelected ? 3 : 0).padding(3))
                    .overlay(Circle().stroke(c, lineWidth: isSelected ? 2 : 0))
                    .scaleEffect(isSelected ? 1.15 : 1.0)
                    .animation(.spring(response: 0.25), value: isSelected)
                    .onTapGesture {
                        selectedHex = hex
                        #if os(iOS)
                        UISelectionFeedbackGenerator().selectionChanged()
                        #endif
                    }
            }
        }
    }
}

#Preview {
    AddHabitSheet(nextSortOrder: 0)
        .modelContainer(for: Habit.self, inMemory: true)
}
