import SwiftUI

struct AccountDetailView: View {
    let account: Account
    @ObservedObject var accountStore: AccountStore
    @EnvironmentObject var currencyManager: CurrencyManager
    
    @State private var showingAddTransaction = false
    @State private var showingAddTransfer = false
    @State private var showingRecurringPayments = false
    @State private var showingExportSheet = false
    
    private var sortedTransactions: [Transaction] {
        account.transactions.sorted { $0.date > $1.date }
    }
    
    private var recentTransactions: [Transaction] {
        Array(sortedTransactions.prefix(5))
    }
    
    var body: some View {
        ScrollView {
            LazyVStack(spacing: 20) {
                // Account Summary Card
                accountSummaryCard
                
                // Quick Stats
                if !account.transactions.isEmpty {
                    quickStatsSection
                }
                
                // Recent Transactions
                if !recentTransactions.isEmpty {
                    recentTransactionsSection
                }
                
                // View All Transactions Button
                if sortedTransactions.count > 5 {
                    viewAllTransactionsButton
                }
                
                // Empty State
                if account.transactions.isEmpty {
                    emptyStateView
                }
            }
            .padding()
        }
        .background(Color(.systemGroupedBackground).ignoresSafeArea())
        .navigationTitle(account.name)
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                navigationMenu
            }
        }
        .sheet(isPresented: $showingAddTransaction) {
            AddTransactionView(accountId: account.id, accountStore: accountStore)
        }
        .sheet(isPresented: $showingAddTransfer) {
            AddTransferView(accountStore: accountStore)
        }
        .sheet(isPresented: $showingRecurringPayments) {
            RecurringPaymentsView(account: account, accountStore: accountStore)
        }
        .sheet(isPresented: $showingExportSheet) {
            ExportTransactionsView(accountStore: accountStore, preselectedAccount: account)
        }
    }
    
    // MARK: - Account Summary Card
    
    private var accountSummaryCard: some View {
        VStack(spacing: 16) {
            // Account Type and Icon
            HStack {
                Image(systemName: account.accountType.iconName)
                    .font(.title2)
                    .foregroundColor(account.accountType.color)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(account.accountType.displayName)
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Text(account.name)
                        .font(.headline)
                        .fontWeight(.semibold)
                }
                
                Spacer()
            }
            
            // Balance
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(account.accountType == .credit ? "Current Balance" : "Balance")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Text(currencyManager.formatAmount(account.currentBalance))
                        .font(.system(size: 28, weight: .bold, design: .rounded))
                        .foregroundColor(balanceColor)
                }
                
                Spacer()
                
                if account.accountType == .credit {
                    creditCardInfo
                }
            }
            
            // Account Details
            accountDetailsGrid
        }
        .padding()
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 4)
    }
    
    private var balanceColor: Color {
        switch account.accountType {
        case .debit:
            return account.currentBalance >= 0 ? .green : .red
        case .credit:
            return account.currentBalance <= 0 ? .green : .red
        }
    }
    
    private var creditCardInfo: some View {
        VStack(alignment: .trailing, spacing: 4) {
            if account.accountType == .credit {
                Text("Current Status")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                if account.currentBalance < 0 {
                    Text(currencyManager.formatAmount(abs(account.currentBalance)))
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(.red)
                    Text("debt")
                        .font(.caption)
                        .foregroundColor(.red)
                } else {
                    Text(currencyManager.formatAmount(account.currentBalance))
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(.green)
                    Text("available")
                        .font(.caption)
                        .foregroundColor(.green)
                }
            }
        }
    }
    
    private var accountDetailsGrid: some View {
        HStack(spacing: 20) {
            if account.accountType == .credit {
                VStack(spacing: 4) {
                    Text("Starting Debt")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Text(currencyManager.formatAmount(abs(account.startingBalance)))
                        .font(.subheadline)
                        .fontWeight(.semibold)
                }
                
                VStack(spacing: 4) {
                    Text("Current Debt")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Text(currencyManager.formatAmount(account.debtAmount))
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(.red)
                }
            } else {
                VStack(spacing: 4) {
                    Text("Starting Balance")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Text(currencyManager.formatAmount(account.startingBalance))
                        .font(.subheadline)
                        .fontWeight(.semibold)
                }
            }
            
            VStack(spacing: 4) {
                Text("Transactions")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Text("\(account.transactions.count)")
                    .font(.subheadline)
                    .fontWeight(.semibold)
            }
            
            Spacer()
        }
    }
    
    // MARK: - Quick Stats Section
    
    private var quickStatsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("This Month")
                .font(.headline)
                .fontWeight(.semibold)
            
            HStack(spacing: 20) {
                StatCard(
                    title: "Income",
                    amount: totalIncome,
                    color: .green,
                    currencyManager: currencyManager
                )
                
                StatCard(
                    title: "Expenses",
                    amount: totalExpenses,
                    color: .red,
                    currencyManager: currencyManager
                )
                
                StatCard(
                    title: "Net",
                    amount: totalIncome + totalExpenses,
                    color: (totalIncome + totalExpenses) >= 0 ? .green : .red,
                    currencyManager: currencyManager
                )
            }
        }
    }
    
    // MARK: - Recent Transactions Section
    
    private var recentTransactionsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Recent Transactions")
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Spacer()
                
                if sortedTransactions.count > 5 {
                    NavigationLink(destination: AllTransactionsView(account: account, accountStore: accountStore)) {
                        Text("See All")
                            .font(.subheadline)
                            .foregroundColor(.blue)
                    }
                }
            }
            
            LazyVStack(spacing: 8) {
                ForEach(recentTransactions) { transaction in
                    TransactionRowView(
                        transaction: transaction,
                        accountId: account.id,
                        accountStore: accountStore,
                        receiptManager: ReceiptManager()
                    )
                }
            }
        }
    }
    
    // MARK: - View All Transactions Button
    
    private var viewAllTransactionsButton: some View {
        NavigationLink(destination: AllTransactionsView(account: account, accountStore: accountStore)) {
            HStack {
                Text("View all \(sortedTransactions.count) transactions")
                    .font(.subheadline)
                    .foregroundColor(.blue)
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(.blue)
            }
            .padding()
            .background(Color.blue.opacity(0.1))
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
        .buttonStyle(PlainButtonStyle())
        .padding(.horizontal)
    }
    
    // MARK: - Empty State
    
    private var emptyStateView: some View {
        VStack(spacing: 16) {
            Image(systemName: "creditcard")
                .font(.system(size: 50))
                .foregroundColor(.secondary)
            
            Text("No Transactions Yet")
                .font(.headline)
                .foregroundColor(.secondary)
            
            Text("Add your first transaction to start tracking your finances")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            
            Button("Add Transaction") {
                showingAddTransaction = true
            }
            .buttonStyle(.borderedProminent)
        }
        .padding(.vertical, 40)
    }
    
    // MARK: - Navigation Menu
    
    private var navigationMenu: some View {
        Menu {
            Button(action: { showingAddTransaction = true }) {
                Label("Add Transaction", systemImage: "plus")
            }
            
            Button(action: { showingAddTransfer = true }) {
                Label("Transfer Money", systemImage: "arrow.left.arrow.right.circle.fill")
            }
            
            Button(action: { showingRecurringPayments = true }) {
                Label("Recurring Payments", systemImage: "calendar.badge.clock")
            }
            
            Divider()
            
//            if !account.transactions.isEmpty {
//                NavigationLink(destination: AllTransactionsView(account: account, accountStore: accountStore)) {
//                    Label("View All Transactions", systemImage: "list.bullet")
//                }
//                
//                Divider()
//            }
            
            Button(action: { showingExportSheet = true }) {
                Label("Export Transactions", systemImage: "square.and.arrow.up")
            }
        } label: {
            Image(systemName: "ellipsis.circle")
                .font(.title3)
        }
    }
    
    // MARK: - Computed Properties
    private var totalIncome: Double {
        let currentMonth = Calendar.current.component(.month, from: Date())
        let currentYear = Calendar.current.component(.year, from: Date())
        
        return account.transactions
            .filter { transaction in
                let transactionMonth = Calendar.current.component(.month, from: transaction.date)
                let transactionYear = Calendar.current.component(.year, from: transaction.date)
                return transactionMonth == currentMonth &&
                       transactionYear == currentYear &&
                       transaction.type == .income
            }
            .reduce(0) { $0 + $1.amount }
    }
    
    private var totalExpenses: Double {
        let currentMonth = Calendar.current.component(.month, from: Date())
        let currentYear = Calendar.current.component(.year, from: Date())
        
        return account.transactions
            .filter { transaction in
                let transactionMonth = Calendar.current.component(.month, from: transaction.date)
                let transactionYear = Calendar.current.component(.year, from: transaction.date)
                return transactionMonth == currentMonth &&
                       transactionYear == currentYear &&
                       transaction.type == .expense
            }
            .reduce(0) { $0 + $1.amount }
    }
}

// MARK: - Stat Card Component

struct StatCard: View {
    let title: String
    let amount: Double
    let color: Color
    let currencyManager: CurrencyManager
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
            
            Text(currencyManager.formatAmount(abs(amount)))
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundColor(color)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(color.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
}

// MARK: - Account Type Extensions

extension Account.AccountType {
    var iconName: String {
        switch self {
        case .debit: return "creditcard"
        case .credit: return "creditcard.fill"
        }
    }
    
    var color: Color {
        switch self {
        case .debit: return .blue
        case .credit: return .orange
        }
    }
    
    var displayName: String {
        switch self {
        case .debit: return "Debit Account"
        case .credit: return "Credit Card"
        }
    }
}

#Preview {
    NavigationView {
        AccountDetailView(
            account: Account(
                name: "Sample Account",
                startingBalance: 1000.0,
                icon: "creditcard",
                color: "Blue",
                accountType: .debit
            ),
            accountStore: AccountStore()
        )
    }
    .environmentObject(CurrencyManager())
}
