import Foundation
import SwiftData

@Model
final class AppSettings {
    var weekStartsOnMonday: Bool
    var notificationHour: Int
    var notificationMinute: Int
    var prefersDarkMode: Bool
    var streakRescueEnabled: Bool
    var weeklyReviewEnabled: Bool

    init(
        weekStartsOnMonday: Bool = true,
        notificationHour: Int = 22,
        notificationMinute: Int = 0,
        prefersDarkMode: Bool = false,
        streakRescueEnabled: Bool = false,
        weeklyReviewEnabled: Bool = false
    ) {
        self.weekStartsOnMonday = weekStartsOnMonday
        self.notificationHour = notificationHour
        self.notificationMinute = notificationMinute
        self.prefersDarkMode = prefersDarkMode
        self.streakRescueEnabled = streakRescueEnabled
        self.weeklyReviewEnabled = weeklyReviewEnabled
    }
}
