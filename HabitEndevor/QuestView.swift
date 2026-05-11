import SwiftUI

// TODO: 퀘스트 시스템 — 나중에 사용자와 함께 구체화 예정 (현재 비활성화)

struct QuestView: View {
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "trophy")
                .font(.system(size: 60))
                .foregroundStyle(Color.secondary)
            Text("퀘스트")
                .font(.system(.title2, design: .rounded))
                .fontWeight(.bold)
            Text("준비 중이에요")
                .font(.subheadline)
                .foregroundStyle(Color.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .navigationTitle("퀘스트")
    }
}

/*
import SwiftUI
import SwiftData

struct QuestView: View {
    @Query private var habits: [Habit]
    @Query private var allRecords: [HabitRecord]
    @Query private var completedQuests: [CompletedQuest]

    private var completedTypes: Set<QuestType> {
        Set(completedQuests.compactMap(\.questType))
    }

    private var totalQuestCoins: Int {
        completedQuests.reduce(0) { $0 + $1.coinsAwarded }
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                questSummaryCard
                ForEach(QuestCategory.allCases) { category in
                    questCategorySection(category)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
        }
        .navigationTitle("퀘스트")
    }

    // MARK: - Summary Card

    private var questSummaryCard: some View {
        VStack(spacing: 14) {
            HStack(spacing: 0) {
                summaryItem(
                    icon: "trophy.fill",
                    color: Color(red: 0.8, green: 0.6, blue: 0.2),
                    value: "\(completedQuests.count) / \(allQuestDefinitions.count)",
                    label: "완료한 퀘스트"
                )
                Divider().frame(height: 44)
                summaryItem(
                    icon: "dollarsign.circle.fill",
                    color: .yellow,
                    value: coinText(totalQuestCoins),
                    label: "퀘스트 획득 코인"
                )
                Divider().frame(height: 44)
                summaryItem(
                    icon: "globe",
                    color: .blue,
                    value: "\(completedQuests.reduce(0) { $0 + $1.countriesAwarded })",
                    label: "보상 나라"
                )
            }

            // Overall progress bar
            let total = allQuestDefinitions.count
            let done  = completedQuests.count
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text("전체 달성도").font(.caption).foregroundStyle(Color.secondary)
                    Spacer()
                    Text("\(Int(Double(done) / Double(total) * 100))%").font(.caption).fontWeight(.semibold)
                }
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        Capsule().fill(Color.primary.opacity(0.08)).frame(height: 8)
                        Capsule()
                            .fill(LinearGradient(colors: [.yellow, .orange], startPoint: .leading, endPoint: .trailing))
                            .frame(width: geo.size.width * CGFloat(done) / CGFloat(max(total, 1)), height: 8)
                    }
                }
                .frame(height: 8)
            }
            .padding(.horizontal, 4)
        }
        .padding(.vertical, 16)
        .padding(.horizontal, 20)
        .cardBackground()
    }

    private func summaryItem(icon: String, color: Color, value: String, label: String) -> some View {
        VStack(spacing: 5) {
            Image(systemName: icon).font(.system(size: 18)).foregroundStyle(color)
            Text(value).font(.system(.subheadline, design: .rounded)).fontWeight(.bold)
            Text(label).font(.system(size: 10, design: .rounded)).foregroundStyle(Color.secondary)
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Category Section

    private func questCategorySection(_ category: QuestCategory) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: 6) {
                Text(category.emoji)
                Text(category.rawValue)
                    .font(.system(.subheadline, design: .rounded))
                    .fontWeight(.semibold)
                Spacer()
                let doneCount = category.quests.filter { completedTypes.contains($0.type) }.count
                Text("\(doneCount)/\(category.quests.count)")
                    .font(.caption)
                    .foregroundStyle(Color.secondary)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)

            ForEach(category.quests) { def in
                QuestCard(
                    definition: def,
                    isCompleted: completedTypes.contains(def.type),
                    completedDate: completedQuests.first { $0.questType == def.type }?.completedAt,
                    currentProgress: QuestService.progress(
                        type: def.type,
                        habits: habits,
                        allRecords: allRecords
                    )
                )
                if def.id != category.quests.last?.id {
                    Divider().padding(.leading, 16)
                }
            }
        }
        .cardBackground()
    }

    private func coinText(_ n: Int) -> String {
        if n >= 1_000_000 { return String(format: "%.1fM", Double(n) / 1_000_000) }
        if n >= 1_000     { return String(format: "%.1fK", Double(n) / 1_000) }
        return "\(n)"
    }
}

// MARK: - Quest Card

struct QuestCard: View {
    let definition: QuestDefinition
    let isCompleted: Bool
    let completedDate: Date?
    let currentProgress: Int

    private var progressRatio: Double {
        min(1.0, Double(currentProgress) / Double(max(definition.targetValue, 1)))
    }

    var body: some View {
        HStack(spacing: 12) {
            // Icon bubble
            Text(definition.icon)
                .font(.title2)
                .frame(width: 44, height: 44)
                .background(
                    Circle().fill(isCompleted
                        ? Color(red: 0.95, green: 0.82, blue: 0.3).opacity(0.3)
                        : Color.primary.opacity(0.06)
                    )
                )

            VStack(alignment: .leading, spacing: 5) {
                HStack {
                    Text(definition.title)
                        .font(.system(.body, design: .rounded))
                        .fontWeight(.semibold)
                    if isCompleted {
                        Text("완료!")
                            .font(.system(size: 10, weight: .bold, design: .rounded))
                            .foregroundStyle(.white)
                            .padding(.horizontal, 6).padding(.vertical, 2)
                            .background(Capsule().fill(Color(red: 0.8, green: 0.6, blue: 0.2)))
                    }
                    Spacer()
                    rewardBadge
                }

                Text(definition.description)
                    .font(.system(.caption, design: .rounded))
                    .foregroundStyle(Color.secondary)

                if !isCompleted {
                    progressBar
                    HStack {
                        Text("\(currentProgress) / \(definition.targetValue)")
                            .font(.system(size: 10, design: .rounded))
                            .foregroundStyle(Color.secondary)
                        Spacer()
                    }
                } else if let date = completedDate {
                    Text(completedDateLabel(date))
                        .font(.system(size: 10, design: .rounded))
                        .foregroundStyle(Color.secondary)
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .opacity(isCompleted ? 0.75 : 1.0)
    }

    private var rewardBadge: some View {
        HStack(spacing: 4) {
            Image(systemName: "circle.fill")
                .font(.system(size: 8))
                .foregroundStyle(.yellow)
            Text(coinShort(definition.coinReward))
                .font(.system(size: 11, weight: .semibold, design: .rounded))
            if definition.countryRewards > 0 {
                Text("🌍×\(definition.countryRewards)")
                    .font(.system(size: 11, design: .rounded))
            }
        }
        .padding(.horizontal, 8).padding(.vertical, 3)
        .background(Capsule().fill(Color.yellow.opacity(0.15)))
    }

    private var progressBar: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                Capsule().fill(Color.primary.opacity(0.08)).frame(height: 5)
                Capsule()
                    .fill(progressRatio >= 1.0 ? Color.green : Color.primary.opacity(0.7))
                    .frame(width: geo.size.width * CGFloat(progressRatio), height: 5)
            }
        }
        .frame(height: 5)
    }

    private func coinShort(_ n: Int) -> String {
        if n >= 1_000_000 { return "\(n / 1_000_000)M" }
        if n >= 1_000     { return "\(n / 1_000)K" }
        return "\(n)"
    }

    private func completedDateLabel(_ date: Date) -> String {
        let f = DateFormatter()
        f.locale = Locale(identifier: "ko_KR")
        f.dateFormat = "M월 d일 달성"
        return f.string(from: date)
    }
}

#Preview {
    NavigationStack { QuestView() }
        .modelContainer(for: [Habit.self, HabitRecord.self, CompletedQuest.self, PurchasedCountry.self], inMemory: true)
}
*/
