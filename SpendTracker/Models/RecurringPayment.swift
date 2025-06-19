import Foundation

struct RecurringPayment: Identifiable, Codable {
    var id: UUID
    var name: String
    var amount: Double
    var category: String // Category name
    var categoryIcon: String
    var accountId: UUID
    var frequency: Frequency
    var nextDueDate: Date
    var payee: String
    var notes: String?
    var type: Transaction.TransactionType
    var isActive: Bool
    var lastProcessedDate: Date?
    
    enum Frequency: String, CaseIterable, Codable {
        case daily = "Daily"
        case weekly = "Weekly"
        case biweekly = "Bi-weekly"
        case monthly = "Monthly"
        case quarterly = "Quarterly"
        case yearly = "Yearly"
        
        var systemImage: String {
            switch self {
            case .daily: return "calendar"
            case .weekly: return "calendar.badge.clock"
            case .biweekly: return "calendar.badge.plus"
            case .monthly: return "calendar.circle"
            case .quarterly: return "calendar.badge.exclamationmark"
            case .yearly: return "calendar.badge.minus"
            }
        }
        
        func nextDate(from date: Date) -> Date {
            let calendar = Calendar.current
            switch self {
            case .daily:
                return calendar.date(byAdding: .day, value: 1, to: date) ?? date
            case .weekly:
                return calendar.date(byAdding: .weekOfYear, value: 1, to: date) ?? date
            case .biweekly:
                return calendar.date(byAdding: .weekOfYear, value: 2, to: date) ?? date
            case .monthly:
                return calendar.date(byAdding: .month, value: 1, to: date) ?? date
            case .quarterly:
                return calendar.date(byAdding: .month, value: 3, to: date) ?? date
            case .yearly:
                return calendar.date(byAdding: .year, value: 1, to: date) ?? date
            }
        }
    }
    
    init(name: String, amount: Double, category: String, categoryIcon: String, accountId: UUID, frequency: Frequency, nextDueDate: Date, payee: String, type: Transaction.TransactionType, notes: String? = nil) {
        self.id = UUID()
        self.name = name
        self.amount = amount
        self.category = category
        self.categoryIcon = categoryIcon
        self.accountId = accountId
        self.frequency = frequency
        self.nextDueDate = nextDueDate
        self.payee = payee
        self.notes = notes
        self.type = type
        self.isActive = true
        self.lastProcessedDate = nil
    }
    
    mutating func processPayment() -> Transaction {
        lastProcessedDate = Date()
        nextDueDate = frequency.nextDate(from: nextDueDate)
        
        return Transaction(
            amount: amount,
            category: TransactionCategory.other, // We'll update this
            accountId: accountId,
            date: Date(),
            payee: payee,
            type: type,
            notes: "Recurring: \(notes ?? "")"
        )
    }
}
