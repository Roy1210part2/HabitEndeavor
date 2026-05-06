import SwiftUI

struct FailureNoteSheet: View {
    @Environment(\.dismiss) private var dismiss
    let record: HabitRecord

    @State private var note = ""

    private var dateLabel: String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ko_KR")
        formatter.dateFormat = "M월 d일 (E)"
        return formatter.string(from: record.date)
    }

    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 0) {
                Text(dateLabel)
                    .font(.subheadline)
                    .foregroundStyle(Color.secondary)
                    .padding(.horizontal, 16)
                    .padding(.top, 16)

                TextEditor(text: $note)
                    .padding(12)
                    .frame(minHeight: 140)

                Spacer()
            }
            .navigationTitle("실패 사유 기록")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("취소") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("저장") {
                        record.failureNote = note.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                            ? nil
                            : note
                        dismiss()
                    }
                    .fontWeight(.semibold)
                }
            }
        }
        #if os(iOS)
        .presentationDetents([.medium])
        #endif
        .onAppear {
            note = record.failureNote ?? ""
        }
    }
}
