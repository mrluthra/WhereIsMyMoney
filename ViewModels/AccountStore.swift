import Foundation
import SwiftUI

class AccountStore: ObservableObject {
    @Published var accounts: [Account] = []
    
    private let userDefaults = UserDefaults.standard
    private let accountsKey = "SavedAccounts"
    
    init() {
        loadAccounts()
    }
    
    // MARK: - Account Management
    
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
    
    func getAccount(_ accountId: UUID) -> Account? {
        return accounts.first(where: { $0.id == accountId })
    }
    
    func getAccountName(_ accountId: UUID) -> String {
        return accounts.first(where: { $0.id == accountId })?.name ?? "Unknown Account"
    }
    
    // MARK: - Transaction Management
    
    func addTransaction(_ transaction: Transaction, to accountId: UUID) {
        if let index = accounts.firstIndex(where: { $0.id == accountId }) {
            accounts[index].addTransaction(transaction)
            saveAccounts()
        }
    }
    
    func updateTransaction(_ updatedTransaction: Transaction, in accountId: UUID) {
        if let accountIndex = accounts.firstIndex(where: { $0.id == accountId }),
           let transactionIndex = accounts[accountIndex].transactions.firstIndex(where: { $0.id == updatedTransaction.id }) {
            accounts[accountIndex].transactions[transactionIndex] = updatedTransaction
            accounts[accountIndex].recalculateBalance()
            saveAccounts()
        }
    }
    
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
    
    // NEW: Move transaction from one account to another
    func moveTransaction(_ transaction: Transaction, from sourceAccountId: UUID, to targetAccountId: UUID) {
        // Don't allow moving transfer transactions
        guard transaction.type != .transfer else { return }
        
        // Remove transaction from source account
        if let sourceAccountIndex = accounts.firstIndex(where: { $0.id == sourceAccountId }) {
            accounts[sourceAccountIndex].transactions.removeAll { $0.id == transaction.id }
            accounts[sourceAccountIndex].recalculateBalance()
        }
        
        // Update transaction's account ID and add to target account
        var updatedTransaction = transaction
        updatedTransaction.accountId = targetAccountId
        
        if let targetAccountIndex = accounts.firstIndex(where: { $0.id == targetAccountId }) {
            accounts[targetAccountIndex].transactions.append(updatedTransaction)
            accounts[targetAccountIndex].recalculateBalance()
        }
        
        saveAccounts()
    }
    
    func getTransaction(_ transactionId: UUID) -> (transaction: Transaction, accountId: UUID)? {
        for account in accounts {
            if let transaction = account.transactions.first(where: { $0.id == transactionId }) {
                return (transaction, account.id)
            }
        }
        return nil
    }
    
    // MARK: - Transfer Management
    
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
    
    // MARK: - Financial Analytics
    
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
    
    // MARK: - Account Analysis
    
    func getAccountsByType(_ type: Account.AccountType) -> [Account] {
        return accounts.filter { $0.accountType == type }
    }
    
    func getAccountsWithTransactions() -> [Account] {
        return accounts.filter { !$0.transactions.isEmpty }
    }
    
    func getAccountsWithBalance(greaterThan amount: Double) -> [Account] {
        return accounts.filter { $0.currentBalance > amount }
    }
    
    func getAccountsWithBalance(lessThan amount: Double) -> [Account] {
        return accounts.filter { $0.currentBalance < amount }
    }
    
    // MARK: - Transaction Analysis
    
    func getAllTransactions() -> [Transaction] {
        return accounts.flatMap { $0.transactions }
    }
    
    func getTransactionsByType(_ type: Transaction.TransactionType) -> [Transaction] {
        return getAllTransactions().filter { $0.type == type }
    }
    
    func getTransactionsInDateRange(from startDate: Date, to endDate: Date) -> [Transaction] {
        return getAllTransactions().filter { transaction in
            transaction.date >= startDate && transaction.date <= endDate
        }
    }
    
    func getTotalIncomeForAccount(_ accountId: UUID, in dateRange: ClosedRange<Date>? = nil) -> Double {
        guard let account = getAccount(accountId) else { return 0 }
        
        let transactions = dateRange == nil ? account.transactions :
            account.transactions.filter { dateRange!.contains($0.date) }
        
        return transactions
            .filter { $0.type == .income }
            .reduce(0) { $0 + $1.amount }
    }
    
    func getTotalExpensesForAccount(_ accountId: UUID, in dateRange: ClosedRange<Date>? = nil) -> Double {
        guard let account = getAccount(accountId) else { return 0 }
        
        let transactions = dateRange == nil ? account.transactions :
            account.transactions.filter { dateRange!.contains($0.date) }
        
        return transactions
            .filter { $0.type == .expense }
            .reduce(0) { $0 + $1.amount }
    }
    
    func getNetChangeForAccount(_ accountId: UUID, in dateRange: ClosedRange<Date>? = nil) -> Double {
        let income = getTotalIncomeForAccount(accountId, in: dateRange)
        let expenses = getTotalExpensesForAccount(accountId, in: dateRange)
        return income - expenses
    }
    
    // MARK: - Account Validation
    
    func canDeleteAccount(_ account: Account) -> Bool {
        // Don't allow deletion if account has transactions
        return account.transactions.isEmpty
    }
    
    func canMergeAccounts(_ sourceAccount: Account, with targetAccount: Account) -> Bool {
        // Can only merge accounts of the same type
        return sourceAccount.accountType == targetAccount.accountType
    }
    
    func mergeAccounts(_ sourceAccount: Account, into targetAccount: Account) {
        guard canMergeAccounts(sourceAccount, with: targetAccount),
              let sourceIndex = accounts.firstIndex(where: { $0.id == sourceAccount.id }),
              let targetIndex = accounts.firstIndex(where: { $0.id == targetAccount.id }) else {
            return
        }
        
        // Move all transactions from source to target
        for transaction in sourceAccount.transactions {
            moveTransaction(transaction, from: sourceAccount.id, to: targetAccount.id)
        }
        
        // Update target account's starting balance
        accounts[targetIndex].startingBalance += sourceAccount.startingBalance
        accounts[targetIndex].recalculateBalance()
        
        // Remove source account
        accounts.remove(at: sourceIndex)
        saveAccounts()
    }
    
    // MARK: - Data Persistence
    
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
    
    // MARK: - Data Export/Import
    
    func exportAccountsToJSON() -> Data? {
        return try? JSONEncoder().encode(accounts)
    }
    
    func importAccountsFromJSON(_ data: Data) throws {
        let importedAccounts = try JSONDecoder().decode([Account].self, from: data)
        accounts = importedAccounts
        saveAccounts()
    }
    
    // MARK: - Search and Filtering
    
    func searchTransactions(_ query: String) -> [Transaction] {
        let lowercaseQuery = query.lowercased()
        return getAllTransactions().filter { transaction in
            transaction.payee.lowercased().contains(lowercaseQuery) ||
            transaction.notes?.lowercased().contains(lowercaseQuery) == true ||
            String(transaction.amount).contains(lowercaseQuery)
        }
    }
    
    func getRecentTransactions(limit: Int = 10) -> [Transaction] {
        return getAllTransactions()
            .sorted { $0.date > $1.date }
            .prefix(limit)
            .map { $0 }
    }
    
    func getLargestTransactions(limit: Int = 10) -> [Transaction] {
        return getAllTransactions()
            .sorted { $0.amount > $1.amount }
            .prefix(limit)
            .map { $0 }
    }
    
    // MARK: - Backup and Restore
    
    func createBackup() -> AccountBackup {
        return AccountBackup(
            accounts: accounts,
            backupDate: Date(),
            version: "1.0"
        )
    }
    
    func restoreFromBackup(_ backup: AccountBackup) {
        accounts = backup.accounts
        saveAccounts()
    }
}

// MARK: - Supporting Types

struct AccountBackup: Codable {
    let accounts: [Account]
    let backupDate: Date
    let version: String
}

// MARK: - AccountStore Extensions for Convenience

extension AccountStore {
    
    // Quick access to specific account types
    var debitAccounts: [Account] {
        return getAccountsByType(.debit)
    }
    
    var creditAccounts: [Account] {
        return getAccountsByType(.credit)
    }
    
    // Quick financial summaries
    var totalCash: Double {
        return debitAccounts.reduce(0) { $0 + max($1.currentBalance, 0) }
    }
    
    var totalCreditDebt: Double {
        return creditAccounts.reduce(0) { $0 + abs(min($1.currentBalance, 0)) }
    }
    
    var totalCreditAvailable: Double {
        return creditAccounts.reduce(0) { $0 + max($1.currentBalance, 0) }
    }
    
    // Account statistics
    var accountCount: Int {
        return accounts.count
    }
    
    var transactionCount: Int {
        return getAllTransactions().count
    }
    
    var averageAccountBalance: Double {
        guard !accounts.isEmpty else { return 0 }
        return accounts.reduce(0) { $0 + $1.currentBalance } / Double(accounts.count)
    }
}
