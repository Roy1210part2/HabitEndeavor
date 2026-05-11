import Foundation

struct CoinService {

    // MARK: - Balance

    static func balance(
        records: [HabitRecord],
        purchases: [PurchasedCountry],
        questCoins: Int = 0
    ) -> Int {
        let earned = records.filter { $0.coinPaidAt != nil }.count * 1_000
        let spent  = purchases.reduce(0) { $0 + $1.pricePaid }
        return max(0, earned + questCoins - spent)
    }

    // MARK: - Coin Award / Revoke (CheckboxView 전용)

    // 오늘 날짜 체크인 시 코인 지급
    static func awardIfToday(record: HabitRecord) {
        guard record.date == Date.todayStart, record.coinPaidAt == nil else { return }
        record.coinPaidAt = Date()
    }

    // 오늘 날짜 체크인 취소 시 코인 회수
    static func revokeIfToday(record: HabitRecord) {
        guard record.date == Date.todayStart else { return }
        record.coinPaidAt = nil
    }

    // MARK: - Legacy (QuestService 등 기존 호환)

    static func handleToggle(record: HabitRecord) {
        record.isChecked.toggle()
        if record.isChecked {
            awardIfToday(record: record)
        } else {
            revokeIfToday(record: record)
        }
    }
}
