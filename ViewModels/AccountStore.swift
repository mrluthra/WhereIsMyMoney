import Foundation
import SwiftUI

class AccountStore: ObservableObject {
    @Published var accounts: [Account] = []
    
    private let userDefaults = UserDefaults.standard
    private let accountsKey = "SavedAccounts"
    
    init() {
        loadAccounts()
    }
    
    func addAccount(_ account: Account) {
        accounts.append(account)
        saveAccounts()
    }
    
    func updateAccount(_ account: Account) {
        if let index = accounts.firstIndex(where: { $0.id == account.id }) {
            accounts[index] = account
            saveAccounts()
        }
    }
    
    func deleteAccount(_ account: Account) {
        accounts.removeAll { $0.id == account.id }
        saveAccounts()
    }
    
    func addTransaction(_ transaction: Transaction, to accountId: UUID) {
        if let index = accounts.firstIndex(where: { $0.id == accountId }) {
            accounts[index].addTransaction(transaction)
            saveAccounts()
        }
    }
    
    // NEW: Update existing transaction
    func updateTransaction(_ updatedTransaction: Transaction, in accountId: UUID) {
        if let accountIndex = accounts.firstIndex(where: { $0.id == accountId }),
           let transactionIndex = accounts[accountIndex].transactions.firstIndex(where: { $0.id == updatedTransaction.id }) {
            accounts[accountIndex].transactions[transactionIndex] = updatedTransaction
            accounts[accountIndex].recalculateBalance()
            saveAccounts()
        }
    }
    
    // NEW: Delete transaction
    func deleteTransaction(_ transaction: Transaction, from accountId: UUID) {
        if let accountIndex = accounts.firstIndex(where: { $0.id == accountId }) {
            accounts[accountIndex].transactions.removeAll { $0.id == transaction.id }
            accounts[accountIndex].recalculateBalance()
            
            // If it's a transfer, also delete the linked transaction
            if transaction.type == .transfer, let linkedId = transaction.linkedTransactionId {
                deleteLinkedTransferTransaction(linkedId: linkedId, excludingAccount: accountId)
            }
            
            saveAccounts()
        }
    }
    
    // NEW: Delete linked transfer transaction
    private func deleteLinkedTransferTransaction(linkedId: UUID, excludingAccount: UUID) {
        for accountIndex in accounts.indices {
            if accounts[accountIndex].id != excludingAccount {
                if let transactionIndex = accounts[accountIndex].transactions.firstIndex(where: { $0.id == linkedId }) {
                    accounts[accountIndex].transactions.remove(at: transactionIndex)
                    accounts[accountIndex].recalculateBalance()
                    break
                }
            }
        }
    }
    
    // NEW: Get transaction by ID across all accounts
    func getTransaction(_ transactionId: UUID) -> (transaction: Transaction, accountId: UUID)? {
        for account in accounts {
            if let transaction = account.transactions.first(where: { $0.id == transactionId }) {
                return (transaction, account.id)
            }
        }
        return nil
    }
    
    // Transfer method for handling transfers
    func addTransfer(amount: Double, fromAccountId: UUID, toAccountId: UUID, date: Date, notes: String?) {
        let sourceTransaction = Transaction(
            amount: amount,
            category: .transfer,
            accountId: fromAccountId,
            date: date,
            payee: "Transfer to \(getAccountName(toAccountId))",
            type: .transfer,
            notes: notes,
            targetAccountId: toAccountId,
            isTransferSource: true
        )
        
        let targetTransaction = Transaction(
            amount: amount,
            category: .transfer,
            accountId: toAccountId,
            date: date,
            payee: "Transfer from \(getAccountName(fromAccountId))",
            type: .transfer,
            notes: notes,
            targetAccountId: fromAccountId,
            isTransferSource: false
        )
        
        var linkedSourceTransaction = sourceTransaction
        var linkedTargetTransaction = targetTransaction
        linkedSourceTransaction.linkedTransactionId = targetTransaction.id
        linkedTargetTransaction.linkedTransactionId = sourceTransaction.id
        
        addTransaction(linkedSourceTransaction, to: fromAccountId)
        addTransaction(linkedTargetTransaction, to: toAccountId)
    }
    
    func getAccountName(_ accountId: UUID) -> String {
        return accounts.first(where: { $0.id == accountId })?.name ?? "Unknown Account"
    }
    
    func getAccount(_ accountId: UUID) -> Account? {
        return accounts.first(where: { $0.id == accountId })
    }
    
    func totalBalance() -> Double {
        return accounts.reduce(0) { total, account in
            total + account.currentBalance
        }
    }
    
    func netWorth() -> Double {
        let debitTotal = accounts
            .filter { $0.accountType == .debit }
            .reduce(0) { $0 + $1.currentBalance }
        
        let creditDebt = accounts
            .filter { $0.accountType == .credit }
            .reduce(0) { $0 + abs(min($1.currentBalance, 0)) }
        
        return debitTotal - creditDebt
    }
    
    func totalAssets() -> Double {
        return accounts
            .filter { $0.accountType == .debit }
            .reduce(0) { $0 + max($1.currentBalance, 0) }
    }
    
    func totalDebt() -> Double {
        return accounts
            .filter { $0.accountType == .credit }
            .reduce(0) { total, account in
                total + abs(min(account.currentBalance, 0))
            }
    }
    
    func totalAvailableCredit() -> Double {
        return accounts
            .filter { $0.accountType == .credit }
            .reduce(0) { total, account in
                total + max(account.currentBalance, 0)
            }
    }
    
    func hasDebt() -> Bool {
        return totalDebt() > 0
    }
    
    func hasAssets() -> Bool {
        return totalAssets() > 0
    }
    
    func financialHealthScore() -> Double {
        let assets = totalAssets()
        let debt = totalDebt()
        
        if assets == 0 && debt == 0 { return 50 }
        if debt == 0 { return 100 }
        if assets == 0 { return 0 }
        
        let ratio = assets / (assets + debt)
        return ratio * 100
    }
    
    private func saveAccounts() {
        if let encoded = try? JSONEncoder().encode(accounts) {
            userDefaults.set(encoded, forKey: accountsKey)
        }
    }
    
    private func loadAccounts() {
        if let data = userDefaults.data(forKey: accountsKey),
           let decoded = try? JSONDecoder().decode([Account].self, from: data) {
            accounts = decoded
        }
    }
}
