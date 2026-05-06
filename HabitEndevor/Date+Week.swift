import Foundation

extension Date {
    func weekDates(startsOnMonday: Bool) -> [Date] {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: self)
        let weekday = calendar.component(.weekday, from: today) // 1=일, 2=월, ..., 7=토

        let daysFromStart: Int
        if startsOnMonday {
            daysFromStart = (weekday + 5) % 7  // 월=0, 화=1, ..., 일=6
        } else {
            daysFromStart = weekday - 1         // 일=0, 월=1, ..., 토=6
        }

        let weekStart = calendar.date(byAdding: .day, value: -daysFromStart, to: today)!
        return (0..<7).compactMap { calendar.date(byAdding: .day, value: $0, to: weekStart) }
    }

    var isToday: Bool {
        Calendar.current.isDateInToday(self)
    }

    var isFuture: Bool {
        self > Calendar.current.startOfDay(for: Date())
    }

    func koreanWeekday() -> String {
        let weekday = Calendar.current.component(.weekday, from: self)
        return ["일", "월", "화", "수", "목", "금", "토"][weekday - 1]
    }

    func dayNumber() -> Int {
        Calendar.current.component(.day, from: self)
    }

    static var todayStart: Date {
        Calendar.current.startOfDay(for: Date())
    }
}
