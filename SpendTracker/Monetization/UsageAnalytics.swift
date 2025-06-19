import Foundation
import SwiftUI

// MARK: - Usage Analytics

class UsageAnalytics: ObservableObject {
    @Published var dailyActiveUsers: Int = 0
    @Published var conversionRate: Double = 0.0
    @Published var averageSessionDuration: TimeInterval = 0
    @Published var retentionRate: Double = 0.0
    
    static let shared = UsageAnalytics()
    
    private init() {}
    
    func trackFeatureUsage(_ feature: String) {
        // Track which features drive the most engagement
        UserDefaults.standard.set(
            UserDefaults.standard.integer(forKey: "feature_\(feature)") + 1,
            forKey: "feature_\(feature)"
        )
    }
    
    func trackPaywallShow(trigger: String) {
        // Track what triggers paywall views most
        UserDefaults.standard.set(
            UserDefaults.standard.integer(forKey: "paywall_\(trigger)") + 1,
            forKey: "paywall_\(trigger)"
        )
    }
    
    func trackConversion() {
        UserDefaults.standard.set(
            UserDefaults.standard.integer(forKey: "conversions") + 1,
            forKey: "conversions"
        )
    }
    
    func trackTrialStart() {
        UserDefaults.standard.set(
            UserDefaults.standard.integer(forKey: "trial_starts") + 1,
            forKey: "trial_starts"
        )
    }
    
    func trackPaywallView() {
        UserDefaults.standard.set(
            UserDefaults.standard.integer(forKey: "paywall_views") + 1,
            forKey: "paywall_views"
        )
    }
    
    func trackAppOpen() {
        UserDefaults.standard.set(
            UserDefaults.standard.integer(forKey: "app_opens") + 1,
            forKey: "app_opens"
        )
    }
    
    func calculateConversionFunnel() -> [String: Int] {
        return [
            "app_opens": UserDefaults.standard.integer(forKey: "app_opens"),
            "paywall_views": UserDefaults.standard.integer(forKey: "paywall_views"),
            "trial_starts": UserDefaults.standard.integer(forKey: "trial_starts"),
            "conversions": UserDefaults.standard.integer(forKey: "conversions")
        ]
    }
    
    func getConversionRate() -> Double {
        let opens = UserDefaults.standard.integer(forKey: "app_opens")
        let conversions = UserDefaults.standard.integer(forKey: "conversions")
        
        guard opens > 0 else { return 0.0 }
        return (Double(conversions) / Double(opens)) * 100
    }
}
