import Foundation
import SwiftUI

final class CountdownManager: ObservableObject {
    static let shared = CountdownManager()

    @Published var label: String = "Christmas"
    @Published var targetYear: Int = 2026
    @Published var targetMonth: Int = 12
    @Published var targetDay: Int = 25

    var targetDate: Date {
        var components = DateComponents()
        components.year = targetYear
        components.month = targetMonth
        components.day = targetDay
        return Calendar.current.startOfDay(for: Calendar.current.date(from: components)!)
    }

    var daysRemaining: Int {
        let today = Calendar.current.startOfDay(for: Date())
        let components = Calendar.current.dateComponents([.day], from: today, to: targetDate)
        return max(components.day ?? 0, 0)
    }
}
