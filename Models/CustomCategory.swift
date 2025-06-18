import Foundation

struct CustomCategory: Identifiable, Codable, Hashable {
    var id: UUID
    var name: String
    var icon: String
    var color: String
    var type: TransactionType // income or expense
    var isDefault: Bool // true for built-in categories
    
    enum TransactionType: String, CaseIterable, Codable, Hashable {
        case income = "Income"
        case expense = "Expense"
    }
    
    init(name: String, icon: String, color: String, type: TransactionType, isDefault: Bool = false) {
        self.id = UUID()
        self.name = name
        self.icon = icon
        self.color = color
        self.type = type
        self.isDefault = isDefault
    }
    
    var systemImage: String {
        return icon
    }
    
    // MARK: - Hashable Conformance
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    static func == (lhs: CustomCategory, rhs: CustomCategory) -> Bool {
        return lhs.id == rhs.id
    }
}
