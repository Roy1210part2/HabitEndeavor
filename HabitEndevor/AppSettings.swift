import Foundation
import SwiftData

@Model
final class AppSettings {
    var weekStartsOnMonday: Bool
    var notificationHour: Int
    var notificationMinute: Int
    var prefersDarkMode: Bool
    var streakRescueEnabled: Bool?   // nil → false (optional for migration compat)
    var weeklyReviewEnabled: Bool?   // nil → false

    init(
        weekStartsOnMonday: Bool = true,
        notificationHour: Int = 22,
        notificationMinute: Int = 0,
        prefersDarkMode: Bool = false
    ) {
        self.weekStartsOnMonday = weekStartsOnMonday
        self.notificationHour = notificationHour
        self.notificationMinute = notificationMinute
        self.prefersDarkMode = prefersDarkMode
    }
}
