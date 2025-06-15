import Foundation

struct Transaction: Identifiable, Codable {
    var id: UUID
    var amount: Double
    var category: TransactionCategory
    var accountId: UUID
    var date: Date
    var payee: String
    var type: TransactionType
    var notes: String?
    
    // New properties for transfers
    var targetAccountId: UUID? // For transfers
    var isTransferSource: Bool? // true if this is the source side of transfer
    var linkedTransactionId: UUID? // Links source and target transactions
    
    enum TransactionType: String, CaseIterable, Codable {
        case income = "Income"
        case expense = "Expense"
        case transfer = "Transfer"
        
        var systemImage: String {
            switch self {
            case .income: return "arrow.down.circle.fill"
            case .expense: return "arrow.up.circle.fill"
            case .transfer: return "arrow.left.arrow.right.circle.fill"
            }
        }
        
        var color: String {
            switch self {
            case .income: return "AppGreen"
            case .expense: return "AppRed"
            case .transfer: return "AppBlue"
            }
        }
    }
    
    init(amount: Double, category: TransactionCategory, accountId: UUID, date: Date, payee: String, type: TransactionType, notes: String? = nil, targetAccountId: UUID? = nil, isTransferSource: Bool? = nil) {
        self.id = UUID()
        self.amount = amount
        self.category = category
        self.accountId = accountId
        self.date = date
        self.payee = payee
        self.type = type
        self.notes = notes
        self.targetAccountId = targetAccountId
        self.isTransferSource = isTransferSource
        self.linkedTransactionId = nil
    }
}
