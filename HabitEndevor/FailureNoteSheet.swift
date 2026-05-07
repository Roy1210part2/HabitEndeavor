import SwiftUI

// MARK: - Emotion Tag

enum EmotionTag: String, CaseIterable, Identifiable {
    case tired       = "tired"
    case busy        = "busy"
    case forgot      = "forgot"
    case unmotivated = "unmotivated"
    case sick        = "sick"
    case other       = "other"

    var id: String { rawValue }

    var label: String {
        switch self {
        case .tired:       return "피곤함"
        case .busy:        return "바빴음"
        case .forgot:      return "잊어버림"
        case .unmotivated: return "의욕없음"
        case .sick:        return "아팠음"
        case .other:       return "기타"
        }
    }

    var icon: String {
        switch self {
        case .tired:       return "😴"
        case .busy:        return "🏃"
        case .forgot:      return "🤔"
        case .unmotivated: return "😔"
        case .sick:        return "🤒"
        case .other:       return "💭"
        }
    }
}

// MARK: - Sheet

struct FailureNoteSheet: View {
    @Environment(\.dismiss) private var dismiss
    let record: HabitRecord

    @State private var selectedTag: EmotionTag? = nil
    @State private var note = ""
    @State private var showTextInput = false

    private var dateLabel: String {
        let f = DateFormatter()
        f.locale = Locale(identifier: "ko_KR")
        f.dateFormat = "M월 d일 (E)"
        return f.string(from: record.date)
    }

    private let columns = [
        GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())
    ]

    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 0) {
                // Date label
                Text(dateLabel)
                    .font(.system(.subheadline, design: .rounded))
                    .foregroundStyle(Color.secondary)
                    .padding(.horizontal, 20)
                    .padding(.top, 20)

                Text("오늘 왜 못 했어요?")
                    .font(.system(.title3, design: .rounded))
                    .fontWeight(.bold)
                    .padding(.horizontal, 20)
                    .padding(.top, 6)
                    .padding(.bottom, 20)

                // Emotion tag grid
                LazyVGrid(columns: columns, spacing: 12) {
                    ForEach(EmotionTag.allCases) { tag in
                        EmotionTagButton(
                            tag: tag,
                            isSelected: selectedTag == tag
                        ) {
                            if selectedTag == tag {
                                selectedTag = nil
                            } else {
                                selectedTag = tag
                                #if os(iOS)
                                let g = UISelectionFeedbackGenerator()
                                g.selectionChanged()
                                #endif
                            }
                        }
                    }
                }
                .padding(.horizontal, 20)

                // Optional text note toggle
                Button {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        showTextInput.toggle()
                    }
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: showTextInput ? "chevron.up" : "pencil")
                            .font(.caption)
                        Text(showTextInput ? "메모 접기" : "더 자세히 메모하기")
                            .font(.system(.footnote, design: .rounded))
                    }
                    .foregroundStyle(Color.secondary)
                }
                .padding(.horizontal, 20)
                .padding(.top, 16)

                if showTextInput {
                    TextEditor(text: $note)
                        .font(.body)
                        .frame(height: 100)
                        .padding(12)
                        .background(Color.primary.opacity(0.04))
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                        .padding(.horizontal, 20)
                        .padding(.top, 8)
                }

                Spacer()
            }
            .navigationTitle("실패 사유")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("취소") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("저장") {
                        record.emotionTag  = selectedTag?.rawValue
                        record.failureNote = note.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                            ? nil : note
                        dismiss()
                    }
                    .fontWeight(.semibold)
                    .disabled(selectedTag == nil && note.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
        }
        #if os(iOS)
        .presentationDetents([.medium])
        #endif
        .onAppear {
            selectedTag = EmotionTag(rawValue: record.emotionTag ?? "")
            note        = record.failureNote ?? ""
            showTextInput = !(record.failureNote ?? "").isEmpty
        }
    }
}

// MARK: - Emotion Tag Button

struct EmotionTagButton: View {
    let tag: EmotionTag
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 6) {
                Text(tag.icon)
                    .font(.system(size: 28))
                Text(tag.label)
                    .font(.system(size: 12, weight: .medium, design: .rounded))
                    .foregroundStyle(isSelected ? Color.primary : Color.secondary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isSelected
                        ? Color.primary.opacity(0.1)
                        : Color.primary.opacity(0.04)
                    )
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? Color.primary.opacity(0.4) : Color.clear, lineWidth: 1.5)
            )
            .scaleEffect(isSelected ? 1.04 : 1.0)
            .animation(.spring(response: 0.2), value: isSelected)
        }
        .buttonStyle(.plain)
    }
}
