import Foundation

struct CoinService {
    static func balance(
        records: [HabitRecord],
        purchases: [PurchasedCountry],
        questCoins: Int = 0
    ) -> Int {
        let earned = records.filter { $0.coinPaidAt != nil }.count * 1_000
        let spent  = purchases.reduce(0) { $0 + $1.pricePaid }
        return max(0, earned + questCoins - spent)
    }

    static func handleToggle(record: HabitRecord) {
        let today = Date.todayStart
        record.isChecked.toggle()

        if record.isChecked {
            if record.date == today, record.coinPaidAt == nil {
                record.coinPaidAt = Date()
            }
        } else {
            if record.date == today, record.coinPaidAt != nil {
                record.coinPaidAt = nil
            }
        }
    }
}
