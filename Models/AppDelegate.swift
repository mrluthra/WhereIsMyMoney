import UIKit
import SwiftUI
import UserNotifications

class AppDelegate: NSObject, UIApplicationDelegate {
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // Configure app for iPad support
        configureAppForDevice()
        
        // Configure background app refresh
        configureBackgroundTasks()
        
        // Clear any cached launch screens to ensure new logo shows
        clearLaunchScreenCache()
        
        return true
    }
    
    // MARK: - Device Configuration
    private func configureAppForDevice() {
        // Ensure proper appearance handling for iPad
        if UIDevice.current.userInterfaceIdiom == .pad {
            // iPad specific configuration
            UIApplication.shared.isIdleTimerDisabled = false
            
            // Configure navigation bar appearance for iPad
            let appearance = UINavigationBarAppearance()
            appearance.configureWithDefaultBackground()
            appearance.largeTitleTextAttributes = [
                .foregroundColor: UIColor.label,
                .font: UIFont.systemFont(ofSize: 34, weight: .bold)
            ]
            appearance.titleTextAttributes = [
                .foregroundColor: UIColor.label,
                .font: UIFont.systemFont(ofSize: 17, weight: .semibold)
            ]
            
            UINavigationBar.appearance().standardAppearance = appearance
            UINavigationBar.appearance().scrollEdgeAppearance = appearance
            UINavigationBar.appearance().compactAppearance = appearance
            
            // Note: Split view configuration will be handled in SwiftUI views
            // UISplitViewController appearance is not available as appearance proxy
        }
        
        // Universal configuration
        configureAppearance()
    }
    
    private func configureAppearance() {
        // Configure tab bar appearance
        let tabBarAppearance = UITabBarAppearance()
        tabBarAppearance.configureWithDefaultBackground()
        UITabBar.appearance().standardAppearance = tabBarAppearance
        UITabBar.appearance().scrollEdgeAppearance = tabBarAppearance
        
        // Configure colors
        UIView.appearance(whenContainedInInstancesOf: [UIAlertController.self]).tintColor = UIColor.systemBlue
    }
    
    // MARK: - Background Tasks
    private func configureBackgroundTasks() {
        // Register background tasks for recurring payments
        BGTaskScheduler.shared.register(
            forTaskWithIdentifier: "com.testapp.whereismymoney.recurringpayments",
            using: nil
        ) { task in
            self.handleBackgroundRecurringPayments(task: task as! BGAppRefreshTask)
        }
    }
    
    private func handleBackgroundRecurringPayments(task: BGAppRefreshTask) {
        // Handle background processing of recurring payments
        task.expirationHandler = {
            task.setTaskCompleted(success: false)
        }
        
        // Process recurring payments in background
        DispatchQueue.global(qos: .background).async {
            // Your background processing logic here
            let success = RecurringPaymentScheduler.shared.processBackgroundPayments()
            
            DispatchQueue.main.async {
                task.setTaskCompleted(success: success)
                self.scheduleNextBackgroundRefresh()
            }
        }
    }
    
    private func scheduleNextBackgroundRefresh() {
        let request = BGAppRefreshTaskRequest(identifier: "com.testapp.whereismymoney.recurringpayments")
        request.earliestBeginDate = Date(timeIntervalSinceNow: 24 * 60 * 60) // 24 hours
        
        try? BGTaskScheduler.shared.submit(request)
    }
    
    // MARK: - Launch Screen Cache Clearing
    private func clearLaunchScreenCache() {
        // Clear launch screen cache to ensure new logo appears
        if let bundleID = Bundle.main.bundleIdentifier {
            UserDefaults.standard.removeObject(forKey: "SBIconVisibilityPreferences")
            UserDefaults.standard.removeObject(forKey: "SBIconVisibilityPreferences-\(bundleID)")
            UserDefaults.standard.synchronize()
        }
        
        // Clear system caches
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene {
                for window in windowScene.windows {
                    window.rootViewController?.setNeedsStatusBarAppearanceUpdate()
                }
            }
        }
    }
    
    // MARK: - Scene Configuration
    func application(_ application: UIApplication, configurationForConnecting connectingSceneSession: UISceneSession, options: UIScene.ConnectionOptions) -> UISceneConfiguration {
        let configuration = UISceneConfiguration(name: "Default Configuration", sessionRole: connectingSceneSession.role)
        configuration.delegateClass = SceneDelegate.self
        return configuration
    }
    
    // MARK: - App Lifecycle
    func applicationDidEnterBackground(_ application: UIApplication) {
        // Schedule background refresh
        scheduleNextBackgroundRefresh()
        
        // Save any pending data
        saveAppState()
    }
    
    func applicationWillEnterForeground(_ application: UIApplication) {
        // Refresh data when app comes to foreground
        NotificationCenter.default.post(name: .appWillEnterForeground, object: nil)
    }
    
    func applicationDidBecomeActive(_ application: UIApplication) {
        // Clear badge count using modern API
        if #available(iOS 16.0, *) {
            UNUserNotificationCenter.current().setBadgeCount(0) { error in
                if let error = error {
                    print("Failed to clear badge count: \(error)")
                }
            }
        } else {
            // Fallback for older iOS versions
            application.applicationIconBadgeNumber = 0
        }
        
        // Check for any pending recurring payments
        NotificationCenter.default.post(name: .checkRecurringPayments, object: nil)
    }
    
    private func saveAppState() {
        // Save any critical app state
        UserDefaults.standard.synchronize()
    }
}

// MARK: - Scene Delegate
class SceneDelegate: NSObject, UIWindowSceneDelegate {
    
    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        guard let windowScene = scene as? UIWindowScene else { return }
        
        // Configure window for iPad
        if UIDevice.current.userInterfaceIdiom == .pad {
            // Set minimum size for iPad windows
            windowScene.sizeRestrictions?.minimumSize = CGSize(width: 768, height: 1024)
            windowScene.sizeRestrictions?.maximumSize = CGSize(width: 1366, height: 1024)
        }
    }
    
    func sceneDidBecomeActive(_ scene: UIScene) {
        // Clear any cached content that might show old logo
        if let windowScene = scene as? UIWindowScene {
            for window in windowScene.windows {
                window.rootViewController?.setNeedsStatusBarAppearanceUpdate()
            }
        }
    }
    
    func sceneWillEnterForeground(_ scene: UIScene) {
        // Post notification for views to refresh
        NotificationCenter.default.post(name: .sceneWillEnterForeground, object: nil)
    }
}

// MARK: - Notification Extensions
extension Notification.Name {
    static let appWillEnterForeground = Notification.Name("appWillEnterForeground")
    static let sceneWillEnterForeground = Notification.Name("sceneWillEnterForeground")
    static let checkRecurringPayments = Notification.Name("checkRecurringPayments")
}

// MARK: - Background Task Identifier
import BackgroundTasks

extension BGTaskScheduler {
    static let recurringPaymentsIdentifier = "com.testapp.whereismymoney.recurringpayments"
}

// MARK: - Recurring Payment Scheduler Extension
extension RecurringPaymentScheduler {
    func processBackgroundPayments() -> Bool {
        // Implement background payment processing
        // Return true if successful, false otherwise
        return true
    }
}
