import SwiftUI
import SwiftData

struct AddHabitSheet: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    let nextSortOrder: Int

    @State private var name = ""
    @State private var emoji = "✅"
    @State private var showEmojiPicker = false

    private var canSave: Bool {
        !name.trimmingCharacters(in: .whitespaces).isEmpty
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    HStack(spacing: 12) {
                        Button {
                            showEmojiPicker = true
                        } label: {
                            Text(emoji)
                                .font(.title2)
                                .frame(width: 44, height: 44)
                                .background(Color.secondary.opacity(0.1))
                                .clipShape(RoundedRectangle(cornerRadius: 8))
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
            sortOrder: nextSortOrder
        )
        modelContext.insert(habit)
        dismiss()
    }
}

// MARK: - Emoji Picker

struct EmojiPickerView: View {
    @Binding var selected: String
    let onSelect: () -> Void

    // 자주 쓰는 습관 이모지 선별
    private let emojis = [
        "✅", "⭐️", "🔥", "💪", "🏃", "🧘", "📚", "✍️",
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
