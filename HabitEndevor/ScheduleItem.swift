import Foundation
import SwiftData

@Model
final class ScheduleItem {
    var date: Date        // 하루 시작 기준으로 정규화
    var title: String
    var isCompleted: Bool
    var time: Date?       // optional 시각 (nil = 시각 없음)
    var createdAt: Date

    init(date: Date, title: String, time: Date? = nil) {
        self.date        = Calendar.current.startOfDay(for: date)
        self.title       = title
        self.isCompleted = false
        self.time        = time
        self.createdAt   = Date()
    }

    var timeLabel: String? {
        guard let t = time else { return nil }
        let f = DateFormatter()
        f.locale = Locale(identifier: "ko_KR")
        f.dateFormat = "a h:mm"
        return f.string(from: t)
    }
}
