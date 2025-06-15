import Foundation
import SwiftUI

class RecurringPaymentStore: ObservableObject {
    @Published var recurringPayments: [RecurringPayment] = []
    
    private let userDefaults = UserDefaults.standard
    private let paymentsKey = "SavedRecurringPayments"
    
    init() {
        loadPayments()
        // Check for due payments on app launch
        _ = checkAndProcessDuePayments()
    }
    
    func addRecurringPayment(_ payment: RecurringPayment) {
        recurringPayments.append(payment)
        savePayments()
    }
    
    func deleteRecurringPayment(_ payment: RecurringPayment) {
        recurringPayments.removeAll { $0.id == payment.id }
        savePayments()
    }
    
    func updateRecurringPayment(_ payment: RecurringPayment) {
        if let index = recurringPayments.firstIndex(where: { $0.id == payment.id }) {
            recurringPayments[index] = payment
            savePayments()
        }
    }
    
    func togglePaymentStatus(_ payment: RecurringPayment) {
        if let index = recurringPayments.firstIndex(where: { $0.id == payment.id }) {
            recurringPayments[index].isActive.toggle()
            savePayments()
        }
    }
    
    func getPaymentsForAccount(_ accountId: UUID) -> [RecurringPayment] {
        return recurringPayments.filter { $0.accountId == accountId }
    }
    
    func getDuePayments() -> [RecurringPayment] {
        let today = Date()
        return recurringPayments.filter { payment in
            payment.isActive && payment.nextDueDate <= today
        }
    }
    
    func checkAndProcessDuePayments() -> [Transaction] {
        let duePayments = getDuePayments()
        var processedTransactions: [Transaction] = []
        
        for payment in duePayments {
            if let index = recurringPayments.firstIndex(where: { $0.id == payment.id }) {
                let transaction = recurringPayments[index].processPayment()
                processedTransactions.append(transaction)
            }
        }
        
        if !processedTransactions.isEmpty {
            savePayments()
        }
        
        return processedTransactions
    }
    
    private func savePayments() {
        if let encoded = try? JSONEncoder().encode(recurringPayments) {
            userDefaults.set(encoded, forKey: paymentsKey)
        }
    }
    
    private func loadPayments() {
        if let data = userDefaults.data(forKey: paymentsKey),
           let decoded = try? JSONDecoder().decode([RecurringPayment].self, from: data) {
            recurringPayments = decoded
        }
    }
}
