import Foundation
import SwiftData

@Model
final class PurchasedCountry {
    var countryCode: String   // ISO 3166-1 alpha-2 (예: "KR")
    var purchasedAt: Date
    var pricePaid: Int

    init(countryCode: String, pricePaid: Int) {
        self.countryCode = countryCode
        self.purchasedAt = Date()
        self.pricePaid = pricePaid
    }
}
