import SwiftUI
import SwiftData

struct AddHabitSheet: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss)      private var dismiss

    let nextSortOrder: Int

    @State private var name          = ""
    @State private var selectedColor = Color.blue

    private var canSave: Bool { !name.trimmingCharacters(in: .whitespaces).isEmpty }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {

                    // 미리보기
                    HStack(spacing: 14) {
                        RoundedRectangle(cornerRadius: 12)
                            .fill(selectedColor)
                            .frame(width: 52, height: 52)
                            .shadow(color: selectedColor.opacity(0.4), radius: 8, x: 0, y: 4)
                            .animation(.spring(response: 0.3), value: selectedColor)

                        VStack(alignment: .leading, spacing: 4) {
                            Text(name.isEmpty ? "습관 이름" : name)
                                .font(.system(.headline, design: .rounded))
                                .fontWeight(.bold)
                                .foregroundStyle(name.isEmpty ? Color.secondary : Color.primary)
                            Text("새 습관 미리보기")
                                .font(.caption)
                                .foregroundStyle(Color.secondary)
                        }
                        Spacer()
                    }
                    .padding(16)
                    .background(Color.primary.opacity(0.04))
                    .clipShape(RoundedRectangle(cornerRadius: 16))

                    // 이름
                    VStack(alignment: .leading, spacing: 10) {
                        Label("습관 이름", systemImage: "pencil")
                            .font(.system(.subheadline, design: .rounded))
                            .fontWeight(.semibold)
                            .foregroundStyle(Color.secondary)

                        TextField("습관 이름 (예: 운동, 독서)", text: $name)
                            .font(.system(.body, design: .rounded))
                            .submitLabel(.done)
                            .onSubmit { if canSave { save() } }
                            .padding(.horizontal, 14)
                            .padding(.vertical, 13)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Color.primary.opacity(0.06))
                            )
                    }

                    // 색상
                    VStack(alignment: .leading, spacing: 10) {
                        Label("색상 선택", systemImage: "paintpalette")
                            .font(.system(.subheadline, design: .rounded))
                            .fontWeight(.semibold)
                            .foregroundStyle(Color.secondary)

                        ColorPicker("습관 색상을 선택하세요", selection: $selectedColor, supportsOpacity: false)
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

    private func save() {
        let habit = Habit(
            name: name.trimmingCharacters(in: .whitespaces),
            sortOrder: nextSortOrder,
            colorHex: selectedColor.toHex() ?? "#74B9FF"
        )
        modelContext.insert(habit)
        dismiss()
    }
}


#Preview {
    AddHabitSheet(nextSortOrder: 0)
        .modelContainer(for: Habit.self, inMemory: true)
}
