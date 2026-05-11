import Foundation
import SwiftData

@Model
final class ScheduleItem {
    var date: Date      // 하루 시작 기준으로 정규화
    var title: String
    var isCompleted: Bool
    var createdAt: Date

    init(date: Date, title: String) {
        self.date        = Calendar.current.startOfDay(for: date)
        self.title       = title
        self.isCompleted = false
        self.createdAt   = Date()
    }
}
