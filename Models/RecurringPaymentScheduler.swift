import Foundation
import BackgroundTasks
import UserNotifications

class RecurringPaymentScheduler: ObservableObject {
    static let shared = RecurringPaymentScheduler()
    
    private var recurringStore: RecurringPaymentStore?
    private var accountStore: AccountStore?
    private var timer: Timer?
    
    private init() {
        setupNotifications()
        scheduleBackgroundTask()
    }
    
    func configure(recurringStore: RecurringPaymentStore, accountStore: AccountStore) {
        self.recurringStore = recurringStore
        self.accountStore = accountStore
        startDailyCheck()
    }
    
    // MARK: - Daily Check (once per day)
    
    private func startDailyCheck() {
        // Check once daily at 12:01 AM (just after midnight)
        scheduleDailyCheck()
    }
    
    private func scheduleDailyCheck() {
        // Cancel existing timer
        timer?.invalidate()
        
        let calendar = Calendar.current
        let now = Date()
        
        // Set target time to 12:01 AM today
        var components = calendar.dateComponents([.year, .month, .day], from: now)
        components.hour = 0
        components.minute = 1
        components.second = 0
        
        guard let targetTime = calendar.date(from: components) else { return }
        
        // If 12:01 AM today has passed, schedule for 12:01 AM tomorrow
        let nextCheckTime = targetTime <= now ?
            calendar.date(byAdding: .day, value: 1, to: targetTime) ?? targetTime :
            targetTime
        
        let timeInterval = nextCheckTime.timeIntervalSinceNow
        
        timer = Timer.scheduledTimer(withTimeInterval: timeInterval, repeats: false) { [weak self] _ in
            self?.performDailyCheck()
        }
        
        print("Next recurring payment check scheduled for: \(nextCheckTime) (12:01 AM)")
    }
    
    private func performDailyCheck() {
        checkAndProcessDuePayments()
        // Schedule next daily check
        scheduleDailyCheck()
    }
    
    func stopDailyCheck() {
        timer?.invalidate()
        timer = nil
    }
    
    // MARK: - Manual Check (can be called from app delegate or user action)
    
    @discardableResult
    func checkAndProcessDuePayments() -> [Transaction] {
        guard let recurringStore = recurringStore,
              let accountStore = accountStore else {
            return []
        }
        
        let today = Calendar.current.startOfDay(for: Date())
        let duePayments = recurringStore.recurringPayments.filter { payment in
            payment.isActive && Calendar.current.startOfDay(for: payment.nextDueDate) <= today
        }
        
        var processedTransactions: [Transaction] = []
        
        for payment in duePayments {
            // Only process if not already processed today
            if !wasProcessedToday(payment) {
                let transaction = processPayment(payment, recurringStore: recurringStore)
                accountStore.addTransaction(transaction, to: payment.accountId)
                processedTransactions.append(transaction)
                
                print("Processed recurring payment: \(payment.name) - \(payment.amount)")
            }
        }
        
        if !processedTransactions.isEmpty {
            // Send single notification for all processed payments
            sendDailyProcessingNotification(count: processedTransactions.count, transactions: processedTransactions)
            print("Processed \(processedTransactions.count) recurring payments today")
        }
        
        return processedTransactions
    }
    
    private func wasProcessedToday(_ payment: RecurringPayment) -> Bool {
        guard let lastProcessed = payment.lastProcessedDate else { return false }
        return Calendar.current.isDate(lastProcessed, inSameDayAs: Date())
    }
    
    private func processPayment(_ payment: RecurringPayment, recurringStore: RecurringPaymentStore) -> Transaction {
        // Update the payment in the store
        if let index = recurringStore.recurringPayments.firstIndex(where: { $0.id == payment.id }) {
            recurringStore.recurringPayments[index].lastProcessedDate = Date()
            recurringStore.recurringPayments[index].nextDueDate = payment.frequency.nextDate(from: payment.nextDueDate)
        }
        
        // Create and return the transaction
        return Transaction(
            amount: payment.amount,
            category: TransactionCategory.other,
            accountId: payment.accountId,
            date: Date(),
            payee: payment.payee,
            type: payment.type,
            notes: "Recurring: \(payment.notes ?? "")"
        )
    }
    
    // MARK: - Background Task Setup
    
    private func scheduleBackgroundTask() {
        let request = BGAppRefreshTaskRequest(identifier: "com.yourapp.recurringpayments")
        // Schedule for next day at 12:01 AM
        let calendar = Calendar.current
        var components = calendar.dateComponents([.year, .month, .day], from: Date())
        components.day! += 1  // Tomorrow
        components.hour = 0
        components.minute = 1
        components.second = 0
        
        let tomorrow1201AM = calendar.date(from: components)
        request.earliestBeginDate = tomorrow1201AM
        
        do {
            try BGTaskScheduler.shared.submit(request)
            print("Background task scheduled for tomorrow at 12:01 AM")
        } catch {
            print("Could not schedule background task: \(error)")
        }
    }
    
    func handleBackgroundTask(_ task: BGAppRefreshTask) {
        // Schedule next background task
        scheduleBackgroundTask()
        
        task.expirationHandler = {
            task.setTaskCompleted(success: false)
        }
        
        // Process due payments in background
        DispatchQueue.global(qos: .background).async { [weak self] in
            _ = self?.checkAndProcessDuePayments() // Use _ to ignore the return value
            
            DispatchQueue.main.async {
                task.setTaskCompleted(success: true)
            }
        }
    }
    
    // MARK: - Notifications
    
    private func setupNotifications() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { granted, error in
            if granted {
                print("Notification permission granted")
            } else if let error = error {
                print("Notification permission error: \(error)")
            }
        }
    }
    
    private func sendPaymentNotification(for payment: RecurringPayment) {
        let content = UNMutableNotificationContent()
        content.title = "Payment Processed"
        content.body = "\(payment.name) - \(payment.type == .expense ? "-" : "+")\(String(format: "%.2f", payment.amount))"
        content.sound = .default
        
        let request = UNNotificationRequest(
            identifier: "payment-\(payment.id.uuidString)",
            content: content,
            trigger: nil // Immediate notification
        )
        
        UNUserNotificationCenter.current().add(request)
    }
    
    private func sendDailyProcessingNotification(count: Int, transactions: [Transaction]) {
        let content = UNMutableNotificationContent()
        content.title = "Daily Payments Processed"
        
        if count == 1 {
            let transaction = transactions.first!
            content.body = "1 recurring payment processed: \(transaction.payee)"
        } else {
            let totalAmount = transactions.reduce(0) { $0 + $1.amount }
            content.body = "\(count) recurring payments processed (Total: $\(String(format: "%.2f", totalAmount)))"
        }
        
        content.sound = .default
        content.badge = count as NSNumber
        
        let request = UNNotificationRequest(
            identifier: "daily-payments-\(Date().timeIntervalSince1970)",
            content: content,
            trigger: nil
        )
        
        UNUserNotificationCenter.current().add(request)
    }
    
    private func sendSummaryNotification(count: Int) {
        // This method is kept for compatibility but now calls the new method
        sendDailyProcessingNotification(count: count, transactions: [])
    }
    
    // MARK: - Upcoming Payments Notifications
    
    func scheduleUpcomingPaymentNotifications() {
        guard let recurringStore = recurringStore else { return }
        
        // Clear existing scheduled notifications
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
        
        let activePayments = recurringStore.recurringPayments.filter { $0.isActive }
        
        for payment in activePayments {
            scheduleNotificationForPayment(payment)
        }
    }
    
    private func scheduleNotificationForPayment(_ payment: RecurringPayment) {
        // Schedule notification 1 day before due date
        let calendar = Calendar.current
        let reminderDate = calendar.date(byAdding: .day, value: -1, to: payment.nextDueDate)
        
        guard let reminderDate = reminderDate, reminderDate > Date() else { return }
        
        let content = UNMutableNotificationContent()
        content.title = "Payment Due Tomorrow"
        content.body = "\(payment.name) - \(String(format: "%.2f", payment.amount)) due tomorrow"
        content.sound = .default
        
        let dateComponents = calendar.dateComponents([.year, .month, .day, .hour, .minute], from: reminderDate)
        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: false)
        
        let request = UNNotificationRequest(
            identifier: "reminder-\(payment.id.uuidString)",
            content: content,
            trigger: trigger
        )
        
        UNUserNotificationCenter.current().add(request)
    }
    
    // MARK: - Cleanup
    
    deinit {
        stopDailyCheck()
    }
}

// MARK: - Extension for easy app delegate integration

extension RecurringPaymentScheduler {
    func applicationDidEnterBackground() {
        scheduleBackgroundTask()
    }
    
    func applicationWillEnterForeground() {
        // Only check when app comes to foreground, not continuously
        checkAndProcessDuePayments()
        scheduleUpcomingPaymentNotifications()
        
        // Restart daily timer in case app was backgrounded for long time
        startDailyCheck()
    }
    
    // Manual trigger for testing or user-initiated check
    func forceCheckNow() -> [Transaction] {
        return checkAndProcessDuePayments()
    }
}
