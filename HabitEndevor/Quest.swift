import Foundation
import SwiftData
import SwiftUI

// TODO: 퀘스트 시스템 — 나중에 구체화 예정
// CompletedQuest 모델은 SwiftData 스키마 호환성 유지를 위해 살려둠

@Model
final class CompletedQuest {
    var questID: String
    var completedAt: Date
    var coinsAwarded: Int
    init(questID: String, coinsAwarded: Int) {
        self.questID = questID
        self.completedAt = Date()
        self.coinsAwarded = coinsAwarded
    }
}

// QuestService 스텁 (CheckboxView 호환성 유지, 기능 비활성화)
struct QuestService {
    static func checkAndComplete(
        habits: [Habit], allRecords: [HabitRecord],
        completedQuests: [CompletedQuest], purchases: [PurchasedCountry],
        context: ModelContext
    ) { /* 비활성화 — 퀘스트 시스템 구체화 후 복원 */ }
}

/*
import Foundation
import SwiftData

// MARK: - Completed Quest (persisted)

@Model
final class CompletedQuest {
    var questTypeRaw: String
    var completedAt: Date
    var coinsAwarded: Int
    var countriesAwarded: Int

    init(type: QuestType, coinsAwarded: Int, countriesAwarded: Int) {
        self.questTypeRaw = type.rawValue
        self.completedAt = Date()
        self.coinsAwarded = coinsAwarded
        self.countriesAwarded = countriesAwarded
    }

    var questType: QuestType? { QuestType(rawValue: questTypeRaw) }
}

// MARK: - Quest Type

enum QuestType: String, CaseIterable {
    case streak3, streak7, streak14, streak21, streak30, streak66
    case total1, total10, total50, total100, total365
    case perfectDay, perfectWeek
    case addFirstHabit, add3Habits
    case failureLog10
}

// MARK: - Quest Category

enum QuestCategory: String, CaseIterable, Identifiable {
    case streak  = "연속 달성"
    case total   = "총 달성"
    case perfect = "완벽함"
    case misc    = "특별 도전"

    var id: String { rawValue }
    var emoji: String {
        switch self {
        case .streak:  return "🔥"
        case .total:   return "⭐️"
        case .perfect: return "👑"
        case .misc:    return "🎯"
        }
    }

    var quests: [QuestDefinition] {
        allQuestDefinitions.filter { $0.category == self }
    }
}

// MARK: - Quest Definition (in-code, not persisted)

struct QuestDefinition: Identifiable {
    let type: QuestType
    let title: String
    let description: String
    let icon: String
    let coinReward: Int
    let countryRewards: Int
    let category: QuestCategory
    let targetValue: Int

    var id: String { type.rawValue }
}

let allQuestDefinitions: [QuestDefinition] = [
    // MARK: Streak
    QuestDefinition(type: .streak3,   title: "첫 연속기록",        description: "어떤 습관이든 3일 연속 달성",          icon: "🔥", coinReward:     2_000, countryRewards: 0, category: .streak,  targetValue: 3),
    QuestDefinition(type: .streak7,   title: "일주일 의지",       description: "7일 연속 달성",                        icon: "🌟", coinReward:     5_000, countryRewards: 1, category: .streak,  targetValue: 7),
    QuestDefinition(type: .streak14,  title: "2주 영웅",          description: "14일 연속 달성",                       icon: "⚡️", coinReward:    10_000, countryRewards: 1, category: .streak,  targetValue: 14),
    QuestDefinition(type: .streak21,  title: "21일의 기적",       description: "21일 연속 달성",                       icon: "💎", coinReward:    20_000, countryRewards: 2, category: .streak,  targetValue: 21),
    QuestDefinition(type: .streak30,  title: "한달 전사",         description: "30일 연속 달성",                       icon: "🏆", coinReward:    35_000, countryRewards: 2, category: .streak,  targetValue: 30),
    QuestDefinition(type: .streak66,  title: "진짜 습관",         description: "66일 연속 달성 — 뇌가 바뀌는 날",      icon: "👑", coinReward:   100_000, countryRewards: 5, category: .streak,  targetValue: 66),
    // MARK: Total
    QuestDefinition(type: .total1,    title: "시작이 반",         description: "첫 번째 습관 성공",                       icon: "🌱", coinReward:       500, countryRewards: 0, category: .total,   targetValue: 1),
    QuestDefinition(type: .total10,   title: "입문자",            description: "총 10회 습관 성공",                       icon: "📊", coinReward:     2_000, countryRewards: 0, category: .total,   targetValue: 10),
    QuestDefinition(type: .total50,   title: "성실러",            description: "총 50회 습관 성공",                       icon: "💪", coinReward:     5_000, countryRewards: 1, category: .total,   targetValue: 50),
    QuestDefinition(type: .total100,  title: "백회 용사",         description: "총 100회 습관 성공",                      icon: "🎖️", coinReward:   10_000, countryRewards: 1, category: .total,   targetValue: 100),
    QuestDefinition(type: .total365,  title: "365일의 기적",      description: "총 365회 습관 성공",                      icon: "🌏", coinReward:    50_000, countryRewards: 5, category: .total,   targetValue: 365),
    // MARK: Perfect
    QuestDefinition(type: .perfectDay,  title: "완벽한 하루",    description: "오늘 모든 습관 달성",                    icon: "✨", coinReward:     1_000, countryRewards: 0, category: .perfect, targetValue: 1),
    QuestDefinition(type: .perfectWeek, title: "완벽한 일주일",  description: "7일 연속 모든 습관 완료",                icon: "🎯", coinReward:    20_000, countryRewards: 2, category: .perfect, targetValue: 7),
    // MARK: Misc
    QuestDefinition(type: .addFirstHabit, title: "새 출발",       description: "첫 번째 습관 등록",                    icon: "➕", coinReward:       500, countryRewards: 0, category: .misc,    targetValue: 1),
    QuestDefinition(type: .add3Habits,    title: "다재다능",       description: "습관 3개 이상 등록",                   icon: "🎪", coinReward:     1_000, countryRewards: 0, category: .misc,    targetValue: 3),
    QuestDefinition(type: .failureLog10,  title: "자기반성 마스터", description: "실패 사유 10번 기록",                 icon: "📝", coinReward:     2_000, countryRewards: 0, category: .misc,    targetValue: 10),
]

// MARK: - Quest Service

struct QuestService {

    static func progress(
        type: QuestType,
        habits: [Habit],
        allRecords: [HabitRecord]
    ) -> Int {
        switch type {

        case .streak3, .streak7, .streak14, .streak21, .streak30, .streak66:
            return habits.map { StreakService.currentStreak(for: $0) }.max() ?? 0

        case .total1, .total10, .total50, .total100, .total365:
            return allRecords.filter(\.isChecked).count

        case .perfectDay:
            guard !habits.isEmpty else { return 0 }
            let today = Date.todayStart
            let allDone = habits.allSatisfy { habit in
                allRecords.first {
                    $0.habit?.persistentModelID == habit.persistentModelID && $0.date == today
                }?.isChecked == true
            }
            return allDone ? 1 : 0

        case .perfectWeek:
            guard !habits.isEmpty else { return 0 }
            let cal = Calendar.current
            var count = 0
            for offset in 0..<7 {
                let date = cal.date(byAdding: .day, value: -offset, to: Date.todayStart)!
                let allDone = habits.allSatisfy { habit in
                    allRecords.first {
                        $0.habit?.persistentModelID == habit.persistentModelID && $0.date == date
                    }?.isChecked == true
                }
                if allDone { count += 1 } else { break }
            }
            return count

        case .addFirstHabit, .add3Habits:
            return habits.filter(\.isActive).count

        case .failureLog10:
            return allRecords.filter { ($0.failureNote ?? "").isEmpty == false }.count
        }
    }

    static func checkAndComplete(
        habits: [Habit],
        allRecords: [HabitRecord],
        completedQuests: [CompletedQuest],
        purchases: [PurchasedCountry],
        context: ModelContext
    ) {
        let completedTypes = Set(completedQuests.compactMap(\.questType))
        var ownedCodes = Set(purchases.map(\.countryCode))

        for def in allQuestDefinitions {
            guard !completedTypes.contains(def.type) else { continue }
            let p = progress(type: def.type, habits: habits, allRecords: allRecords)
            guard p >= def.targetValue else { continue }

            let completed = CompletedQuest(
                type: def.type,
                coinsAwarded: def.coinReward,
                countriesAwarded: def.countryRewards
            )
            context.insert(completed)

            if def.countryRewards > 0 {
                let available = allCountries.filter { !ownedCodes.contains($0.id) }
                let toUnlock = Array(available.shuffled().prefix(def.countryRewards))
                for country in toUnlock {
                    context.insert(PurchasedCountry(countryCode: country.id, pricePaid: 0))
                    ownedCodes.insert(country.id)
                }
            }
            try? context.save()
        }
    }
}
*/
