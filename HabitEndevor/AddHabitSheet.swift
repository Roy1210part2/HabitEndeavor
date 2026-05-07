import SwiftUI
import SwiftData

struct AddHabitSheet: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    let nextSortOrder: Int

    @State private var name = ""
    @State private var emoji = "⭐️"
    @State private var selectedColorHex = habitColorPalette[5]  // 하늘색 기본
    @State private var showEmojiPicker = false

    private var canSave: Bool {
        !name.trimmingCharacters(in: .whitespaces).isEmpty
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    HStack(spacing: 12) {
                        // 이모지 + 색상 프리뷰 버튼
                        Button { showEmojiPicker = true } label: {
                            ZStack {
                                RoundedRectangle(cornerRadius: 10)
                                    .fill(Color(hex: selectedColorHex) ?? .blue)
                                    .frame(width: 48, height: 48)
                                Text(emoji).font(.title2)
                            }
                        }
                        .buttonStyle(.plain)

                        TextField("습관 이름 (예: 운동, 독서)", text: $name)
                            .submitLabel(.done)
                            .onSubmit { if canSave { save() } }
                    }
                    .padding(.vertical, 4)
                }

                if showEmojiPicker {
                    Section("이모지 선택") {
                        EmojiPickerView(selected: $emoji, onSelect: { showEmojiPicker = false })
                    }
                }

                Section("색상 선택") {
                    ColorPaletteView(selectedHex: $selectedColorHex)
                }
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
        .presentationDetents([.medium, .large])
        #endif
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

// MARK: - Color Palette Picker

struct ColorPaletteView: View {
    @Binding var selectedHex: String

    private let columns = Array(repeating: GridItem(.flexible()), count: 6)

    var body: some View {
        LazyVGrid(columns: columns, spacing: 10) {
            ForEach(habitColorPalette, id: \.self) { hex in
                let color = Color(hex: hex) ?? .blue
                ZStack {
                    Circle().fill(color).frame(width: 36, height: 36)
                    if selectedHex == hex {
                        Circle()
                            .strokeBorder(Color.primary, lineWidth: 2)
                            .frame(width: 40, height: 40)
                        Circle()
                            .fill(.white.opacity(0.35))
                            .frame(width: 36, height: 36)
                    }
                }
                .frame(width: 44, height: 44)
                .contentShape(Circle())
                .onTapGesture {
                    selectedHex = hex
                    #if os(iOS)
                    UISelectionFeedbackGenerator().selectionChanged()
                    #endif
                }
                .animation(.spring(response: 0.2), value: selectedHex)
            }
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Emoji Picker

struct EmojiPickerView: View {
    @Binding var selected: String
    let onSelect: () -> Void

    private let emojis = [
        "⭐️", "🔥", "💪", "🏃", "🧘", "📚", "✍️",
        "🎯", "🎨", "🎵", "🍎", "💧", "😴", "🧹", "💻",
        "📝", "🏋️", "🚴", "🌱", "🧠", "❤️", "💊", "🛁",
        "☀️", "🌙", "🍵", "🥗", "🚫", "🙏", "📖", "🎤",
    ]

    let columns = Array(repeating: GridItem(.flexible()), count: 8)

    var body: some View {
        LazyVGrid(columns: columns, spacing: 8) {
            ForEach(emojis, id: \.self) { e in
                Button {
                    selected = e
                    onSelect()
                } label: {
                    Text(e)
                        .font(.title3)
                        .frame(width: 36, height: 36)
                        .background(
                            RoundedRectangle(cornerRadius: 6)
                                .fill(selected == e ? Color.primary.opacity(0.15) : Color.clear)
                        )
                }
                .buttonStyle(.plain)
            }
        }
    }
}

#Preview {
    AddHabitSheet(nextSortOrder: 0)
        .modelContainer(for: Habit.self, inMemory: true)
}
