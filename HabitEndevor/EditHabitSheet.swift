import SwiftUI
import SwiftData

struct EditHabitSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    @Bindable var habit: Habit

    @State private var name: String
    @State private var selectedColor: Color

    init(habit: Habit) {
        self.habit = habit
        _name = State(initialValue: habit.name)
        _selectedColor = State(initialValue: habit.displayColor)
    }

    private var canSave: Bool {
        !name.trimmingCharacters(in: .whitespaces).isEmpty
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {

                    // 미리보기
                    HStack(spacing: 14) {
                        RoundedRectangle(cornerRadius: 12)
                            .fill(selectedColor)
                            .frame(width: 52, height: 52)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(selectedColor.opacity(0.4), lineWidth: 2)
                            )
                            .shadow(color: selectedColor.opacity(0.4), radius: 8, x: 0, y: 4)
                            .animation(.spring(response: 0.3), value: selectedColor)

                        VStack(alignment: .leading, spacing: 4) {
                            Text(name.isEmpty ? "습관 이름" : name)
                                .font(.system(.headline, design: .rounded))
                                .fontWeight(.bold)
                                .foregroundStyle(name.isEmpty ? Color.secondary : Color.primary)
                            Text("미리보기")
                                .font(.caption)
                                .foregroundStyle(Color.secondary)
                        }
                        Spacer()
                    }
                    .padding(16)
                    .background(Color.primary.opacity(0.04))
                    .clipShape(RoundedRectangle(cornerRadius: 16))

                    // 이름 편집
                    VStack(alignment: .leading, spacing: 10) {
                        Label("습관 이름", systemImage: "pencil")
                            .font(.system(.subheadline, design: .rounded))
                            .fontWeight(.semibold)
                            .foregroundStyle(Color.secondary)

                        TextField("습관 이름을 입력하세요", text: $name)
                            .font(.system(.body, design: .rounded))
                            .submitLabel(.done)
                            .padding(.horizontal, 14)
                            .padding(.vertical, 13)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Color.primary.opacity(0.06))
                            )
                    }

                    // 색상 편집
                    VStack(alignment: .leading, spacing: 10) {
                        Label("색상 선택", systemImage: "paintpalette")
                            .font(.system(.subheadline, design: .rounded))
                            .fontWeight(.semibold)
                            .foregroundStyle(Color.secondary)

                        ColorPicker("습관 색상", selection: $selectedColor, supportsOpacity: false)
                            .padding(.horizontal, 14)
                            .padding(.vertical, 13)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Color.primary.opacity(0.06))
                            )

                        // 팔레트 빠른 선택
                        LazyVGrid(
                            columns: Array(repeating: GridItem(.flexible()), count: 6),
                            spacing: 10
                        ) {
                            ForEach(habitColorPalette, id: \.self) { hex in
                                let c = Color(hex: hex) ?? .blue
                                Circle()
                                    .fill(c)
                                    .frame(height: 36)
                                    .overlay(
                                        Circle()
                                            .stroke(Color.primary, lineWidth: selectedColor.toHex() == hex ? 2.5 : 0)
                                            .padding(3)
                                    )
                                    .scaleEffect(selectedColor.toHex() == hex ? 1.15 : 1.0)
                                    .animation(.spring(response: 0.25), value: selectedColor.toHex())
                                    .onTapGesture {
                                        selectedColor = c
                                        #if os(iOS)
                                        UISelectionFeedbackGenerator().selectionChanged()
                                        #endif
                                    }
                            }
                        }
                    }

                    // 위험 구역
                    VStack(alignment: .leading, spacing: 10) {
                        Label("기타", systemImage: "exclamationmark.triangle")
                            .font(.system(.subheadline, design: .rounded))
                            .fontWeight(.semibold)
                            .foregroundStyle(Color.secondary)

                        Button(role: .destructive) {
                            habit.isActive = false
                            try? modelContext.save()
                            dismiss()
                        } label: {
                            Label("습관 비활성화", systemImage: "archivebox")
                                .font(.system(.body, design: .rounded))
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(.horizontal, 14)
                                .padding(.vertical, 13)
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(Color.red.opacity(0.08))
                                )
                                .foregroundStyle(Color.red)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(20)
            }
            .navigationTitle("습관 편집")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("취소") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("저장") { save() }
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

    private func save() {
        habit.name     = name.trimmingCharacters(in: .whitespaces)
        habit.colorHex = selectedColor.toHex() ?? habit.colorHex
        try? modelContext.save()
        dismiss()
    }
}

#Preview {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: Habit.self, configurations: config)
    let habit = Habit(name: "운동", sortOrder: 0, colorHex: "#74B9FF")
    container.mainContext.insert(habit)
    return EditHabitSheet(habit: habit)
        .modelContainer(container)
}
