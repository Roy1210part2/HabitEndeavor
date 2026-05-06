import Foundation

struct CoinService {
    static func balance(records: [HabitRecord], purchases: [PurchasedCountry]) -> Int {
        let earned = records.filter { $0.coinPaidAt != nil }.count * 1000
        let spent = purchases.reduce(0) { $0 + $1.pricePaid }
        return max(0, earned - spent)
    }

    static func handleToggle(record: HabitRecord) {
        let today = Date.todayStart
        record.isChecked.toggle()

        if record.isChecked {
            // 당일 체크이고 아직 코인 미지급이면 지급
            if record.date == today, record.coinPaidAt == nil {
                record.coinPaidAt = Date()
            }
        } else {
            // 당일 취소이면 코인 회수. 과거 날짜 취소는 회수 없음
            if record.date == today, record.coinPaidAt != nil {
                record.coinPaidAt = nil
            }
        }
    }
}
