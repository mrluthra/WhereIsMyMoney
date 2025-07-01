import UIKit
import BackgroundTasks

class AppDelegate: UIResponder, UIApplicationDelegate {
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        
        // Register background task
        BGTaskScheduler.shared.register(forTaskWithIdentifier: "com.yourapp.recurringpayments", using: nil) { task in
            RecurringPaymentScheduler.shared.handleBackgroundTask(task as! BGAppRefreshTask)
        }
        
        return true
    }
    
    func applicationDidEnterBackground(_ application: UIApplication) {
        RecurringPaymentScheduler.shared.applicationDidEnterBackground()
    }
    
    func applicationWillEnterForeground(_ application: UIApplication) {
        RecurringPaymentScheduler.shared.applicationWillEnterForeground()
    }
}
