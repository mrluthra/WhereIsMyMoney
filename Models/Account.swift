import Foundation
import SwiftUI

struct Account: Identifiable, Codable {
    var id: UUID
    var name: String
    var startingBalance: Double
    var currentBalance: Double
    var icon: String
    var color: String
    var accountType: AccountType
    var transactions: [Transaction]
    
    enum AccountType: String, CaseIterable, Codable {
        case debit = "Debit"
        case credit = "Credit"
        
        var systemImage: String {
            switch self {
            case .debit: return "creditcard"
            case .credit: return "creditcard.fill"
            }
        }
        
        var balanceMultiplier: Double {
            switch self {
            case .debit: return 1.0
            case .credit: return -1.0
            }
        }
    }
    
    init(name: String, startingBalance: Double, icon: String, color: String, accountType: AccountType) {
        self.id = UUID()
        self.name = name
        self.startingBalance = startingBalance * accountType.balanceMultiplier
        self.currentBalance = self.startingBalance
        self.icon = icon
        self.color = color
        self.accountType = accountType
        self.transactions = []
    }
    
    mutating func addTransaction(_ transaction: Transaction) {
        transactions.append(transaction)
        recalculateBalance()
    }
    
    // NEW: Public method to recalculate balance
    mutating func recalculateBalance() {
        currentBalance = startingBalance
        for transaction in transactions {
            switch transaction.type {
            case .income:
                currentBalance += transaction.amount
            case .expense:
                currentBalance -= transaction.amount
            case .transfer:
                if let isSource = transaction.isTransferSource {
                    if isSource {
                        currentBalance -= transaction.amount
                    } else {
                        currentBalance += transaction.amount
                    }
                }
            }
        }
    }
    
    var displayBalance: Double {
        return currentBalance
    }
    
    var isInDebt: Bool {
        return accountType == .credit && currentBalance < 0
    }
    
    var debtAmount: Double {
        return accountType == .credit ? abs(min(currentBalance, 0)) : 0
    }
}
