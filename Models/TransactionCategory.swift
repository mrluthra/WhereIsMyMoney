import Foundation

enum TransactionCategory: String, CaseIterable, Codable {
    // Expense Categories
    case food = "Food & Dining"
    case transportation = "Transportation"
    case shopping = "Shopping"
    case entertainment = "Entertainment"
    case bills = "Bills & Utilities"
    case healthcare = "Healthcare"
    case education = "Education"
    case travel = "Travel"
    case other = "Other"
    
    // Income Categories
    case salary = "Salary"
    case freelance = "Freelance"
    case investment = "Investment"
    case gift = "Gift"
    case bonus = "Bonus"
    
    // Transfer Category
    case transfer = "Transfer"
    
    var systemImage: String {
        switch self {
        case .food: return "fork.knife"
        case .transportation: return "car.fill"
        case .shopping: return "bag.fill"
        case .entertainment: return "tv.fill"
        case .bills: return "doc.text.fill"
        case .healthcare: return "cross.fill"
        case .education: return "book.fill"
        case .travel: return "airplane"
        case .salary: return "dollarsign.circle.fill"
        case .freelance: return "laptopcomputer"
        case .investment: return "chart.line.uptrend.xyaxis"
        case .gift: return "gift.fill"
        case .bonus: return "star.fill"
        case .transfer: return "arrow.left.arrow.right.circle.fill"
        case .other: return "questionmark.circle.fill"
        }
    }
}
