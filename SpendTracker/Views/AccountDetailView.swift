import SwiftUI

struct AccountDetailView: View {
    let account: Account
    @ObservedObject var accountStore: AccountStore
    @StateObject private var receiptManager = ReceiptManager()
    @State private var showingAddTransaction = false
    @State private var showingRecurringPayments = false
    @State private var showingAddTransfer = false
    @StateObject private var recurringStore = RecurringPaymentStore()
    
    @Environment(\.colorScheme) private var colorScheme
    
    private var sortedTransactions: [Transaction] {
        account.transactions.sorted { $0.date > $1.date }
    }
    
    private var accountRecurringPayments: [RecurringPayment] {
        recurringStore.getPaymentsForAccount(account.id)
    }
    
    private var activeRecurringPayments: Int {
        accountRecurringPayments.filter { $0.isActive }.count
    }
    
    private func colorForAccount(_ colorName: String) -> Color {
        switch colorName {
        case "Blue": return .blue
        case "Green": return .green
        case "Purple": return .purple
        case "Orange": return .orange
        case "Red": return .red
        case "Yellow": return .yellow
        default: return .blue
        }
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Account Header
                VStack(spacing: 16) {
                    // Account Icon and Info
                    HStack(spacing: 16) {
                        ZStack {
                            Circle()
                                .fill(colorForAccount(account.color).opacity(0.2))
                                .frame(width: 60, height: 60)
                            
                            Image(systemName: account.icon)
                                .font(.title)
                                .foregroundColor(colorForAccount(account.color))
                        }
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text(account.name)
                                .font(.title2)
                                .fontWeight(.semibold)
                            
                            HStack(spacing: 8) {
                                Text(account.accountType.rawValue)
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 2)
                                    .background(Color.secondary.opacity(0.1))
                                    .clipShape(Capsule())
                                
                                if account.accountType == .credit && account.isInDebt {
                                    Text("DEBT")
                                        .font(.caption)
                                        .fontWeight(.bold)
                                        .foregroundColor(.white)
                                        .padding(.horizontal, 6)
                                        .padding(.vertical, 1)
                                        .background(Color.red)
                                        .clipShape(Capsule())
                                }
                            }
                        }
                        
                        Spacer()
                    }
                    
                    // Balance Card
                    VStack(spacing: 12) {
                        VStack(spacing: 4) {
                            if account.accountType == .credit {
                                if account.currentBalance < 0 {
                                    Text("Current Debt")
                                        .font(.subheadline)
                                        .foregroundColor(.secondary)
                                    
                                    Text("$\(abs(account.currentBalance), specifier: "%.2f")")
                                        .font(.system(size: 32, weight: .bold, design: .rounded))
                                        .foregroundColor(.red)
                                } else {
                                    Text("Credit Available")
                                        .font(.subheadline)
                                        .foregroundColor(.secondary)
                                    
                                    Text("$\(account.currentBalance, specifier: "%.2f")")
                                        .font(.system(size: 32, weight: .bold, design: .rounded))
                                        .foregroundColor(.green)
                                }
                            } else {
                                Text("Current Balance")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                                
                                Text("$\(account.currentBalance, specifier: "%.2f")")
                                    .font(.system(size: 32, weight: .bold, design: .rounded))
                                    .foregroundColor(account.currentBalance >= 0 ? .green : .red)
                            }
                        }
                        
                        Divider()
                        
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                if account.accountType == .credit {
                                    Text("Starting Debt")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                    Text("$\(abs(account.startingBalance), specifier: "%.2f")")
                                        .font(.subheadline)
                                        .fontWeight(.medium)
                                } else {
                                    Text("Starting Balance")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                    Text("$\(account.startingBalance, specifier: "%.2f")")
                                        .font(.subheadline)
                                        .fontWeight(.medium)
                                }
                            }
                            
                            Spacer()
                            
                            VStack(alignment: .center, spacing: 4) {
                                Text("Transactions")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                Text("\(account.transactions.count)")
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                            }
                            
                            Spacer()
                            
                            VStack(alignment: .trailing, spacing: 4) {
                                Text("Recurring")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                Text("\(activeRecurringPayments)")
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                            }
                        }
                    }
                    .padding()
                    .background(Color(.systemBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                    .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
                }
                .padding(.horizontal)
                .padding(.top)
                
                // FIXED: Quick Actions with Dark Mode Support
                VStack(alignment: .leading, spacing: 12) {
                    Text("Quick Actions")
                        .font(.headline)
                        .padding(.horizontal)
                    
                    HStack(spacing: 12) {
                        AccountQuickActionCard(
                            title: "Add Transaction",
                            icon: "plus.circle.fill",
                            color: .blue,
                            action: { showingAddTransaction = true }
                        )
                        
                        AccountQuickActionCard(
                            title: "Transfer Money",
                            icon: "arrow.left.arrow.right.circle.fill",
                            color: .purple,
                            action: { showingAddTransfer = true }
                        )
                        
                        AccountQuickActionCard(
                            title: "Recurring Payments",
                            icon: "calendar.badge.clock",
                            color: .orange,
                            action: { showingRecurringPayments = true }
                        )
                    }
                    .padding(.horizontal)
                }
                
                // Quick Stats
                if !account.transactions.isEmpty {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Financial Overview")
                            .font(.headline)
                            .padding(.horizontal)
                        
                        HStack(spacing: 12) {
                            StatCardView(
                                title: account.accountType == .credit ? "Payments" : "Income",
                                amount: totalIncome,
                                color: .green,
                                icon: "arrow.down.circle.fill"
                            )
                            
                            StatCardView(
                                title: account.accountType == .credit ? "Charges" : "Expenses",
                                amount: totalExpenses,
                                color: .red,
                                icon: "arrow.up.circle.fill"
                            )
                        }
                        .padding(.horizontal)
                        
                        // Net change for credit cards, net income for debit
                        HStack(spacing: 12) {
                            if account.accountType == .credit {
                                StatCardView(
                                    title: "Net Change",
                                    amount: totalIncome - totalExpenses,
                                    color: (totalIncome - totalExpenses) >= 0 ? .green : .red,
                                    icon: "chart.line.uptrend.xyaxis"
                                )
                            } else {
                                StatCardView(
                                    title: "Net Income",
                                    amount: totalIncome - totalExpenses,
                                    color: (totalIncome - totalExpenses) >= 0 ? .green : .red,
                                    icon: "chart.line.uptrend.xyaxis"
                                )
                            }
                            
                            StatCardView(
                                title: "Avg Transaction",
                                amount: account.transactions.isEmpty ? 0 : (totalIncome + totalExpenses) / Double(account.transactions.count),
                                color: .blue,
                                icon: "calculator"
                            )
                        }
                        .padding(.horizontal)
                    }
                }
                
                // Recent Recurring Payments Preview
                if !accountRecurringPayments.isEmpty {
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Text("Recurring Payments")
                                .font(.headline)
                            
                            Spacer()
                            
                            Button(action: { showingRecurringPayments = true }) {
                                HStack {
                                    Text("View All")
                                    Image(systemName: "chevron.right")
                                        .font(.caption)
                                }
                                .font(.subheadline)
                                .foregroundColor(.blue)
                            }
                        }
                        .padding(.horizontal)
                        
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 12) {
                                ForEach(Array(accountRecurringPayments.prefix(3))) { payment in
                                    RecurringPaymentPreviewCard(payment: payment)
                                }
                            }
                            .padding(.horizontal)
                        }
                    }
                }
                
                // Transactions Section
                VStack(alignment: .leading, spacing: 16) {
                    HStack {
                        Text("Recent Transactions")
                            .font(.headline)
                        
                        Spacer()
                        
                        Button(action: { showingAddTransaction = true }) {
                            Label("Add", systemImage: "plus.circle.fill")
                                .font(.subheadline)
                                .foregroundColor(.blue)
                        }
                    }
                    .padding(.horizontal)
                    
                    if sortedTransactions.isEmpty {
                        // Empty state
                        VStack(spacing: 12) {
                            Image(systemName: "doc.text")
                                .font(.system(size: 40))
                                .foregroundColor(.secondary)
                            
                            Text("No Transactions Yet")
                                .font(.headline)
                                .foregroundColor(.secondary)
                            
                            Text("Tap 'Add' to record your first transaction")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 40)
                    } else {
                        LazyVStack(spacing: 8) {
                            ForEach(Array(sortedTransactions.prefix(10))) { transaction in
                                TransactionRowView(
                                    transaction: transaction,
                                    accountId: account.id,
                                    accountStore: accountStore,
                                    receiptManager: receiptManager
                                )
                            }
                            
                            if sortedTransactions.count > 10 {
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
                        }
                        .padding(.horizontal)
                    }
                }
            }
            .padding(.bottom, 20)
        }
        .background(Color(.systemGroupedBackground).ignoresSafeArea())
        .navigationTitle(account.name)
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
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
                    
                    if !account.transactions.isEmpty {
                        NavigationLink(destination: AllTransactionsView(account: account, accountStore: accountStore)) {
                            Label("View All Transactions", systemImage: "list.bullet")
                        }
                        
                        Divider()
                    }
                    
                    Button(action: { /* Add export functionality */ }) {
                        Label("Export Transactions", systemImage: "square.and.arrow.up")
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                        .font(.title3)
                }
            }
        }
        // FIXED: Pass accountId to AddTransactionView for payee suggestions
        .sheet(isPresented: $showingAddTransaction) {
            AddTransactionView(accountId: account.id, accountStore: accountStore)
        }
        .sheet(isPresented: $showingRecurringPayments) {
            RecurringPaymentsView(account: account, accountStore: accountStore)
        }
        .sheet(isPresented: $showingAddTransfer) {
            AddTransferView(accountStore: accountStore)
        }
    }
    
    private var totalIncome: Double {
        account.transactions
            .filter { $0.type == .income }
            .reduce(0) { $0 + $1.amount }
    }
    
    private var totalExpenses: Double {
        account.transactions
            .filter { $0.type == .expense }
            .reduce(0) { $0 + $1.amount }
    }
}

// MARK: - FIXED: Account Quick Action Card with Dark Mode Support

struct AccountQuickActionCard: View {
    let title: String
    let icon: String
    let color: Color
    let action: () -> Void
    
    @Environment(\.colorScheme) private var colorScheme
    
    private var cardBackgroundColor: Color {
        if colorScheme == .dark {
            return Color(.systemGray6)
        } else {
            return Color(.systemBackground)
        }
    }
    
    private var borderColor: Color {
        if colorScheme == .dark {
            return Color(.systemGray4)
        } else {
            return Color.clear
        }
    }
    
    private var shadowColor: Color {
        if colorScheme == .dark {
            return Color.clear
        } else {
            return Color.black.opacity(0.05)
        }
    }
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundColor(color)
                
                Text(title)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(.primary)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 80)
            .background(cardBackgroundColor)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .shadow(color: shadowColor, radius: 4, x: 0, y: 1)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(borderColor, lineWidth: colorScheme == .dark ? 1 : 0)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct RecurringPaymentPreviewCard: View {
    let payment: RecurringPayment
    
    @Environment(\.colorScheme) private var colorScheme
    
    private var cardBackgroundColor: Color {
        if colorScheme == .dark {
            return Color(.systemGray6)
        } else {
            return Color(.systemBackground)
        }
    }
    
    private var borderColor: Color {
        if colorScheme == .dark {
            return Color(.systemGray4)
        } else {
            return Color.clear
        }
    }
    
    private var shadowColor: Color {
        if colorScheme == .dark {
            return Color.clear
        } else {
            return Color.black.opacity(0.05)
        }
    }
    
    private func colorForTransactionType(_ type: Transaction.TransactionType) -> Color {
        switch type {
        case .income: return .green
        case .expense: return .red
        case .transfer: return .blue
        }
    }
    
    private var nextDueDateFormatted: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        return formatter.string(from: payment.nextDueDate)
    }
    
    private var isDue: Bool {
        payment.nextDueDate <= Date()
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: payment.categoryIcon)
                    .foregroundColor(colorForTransactionType(payment.type))
                    .frame(width: 20)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(payment.name)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .lineLimit(1)
                    
                    Text(payment.payee)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }
                
                Spacer()
            }
            
            Divider()
            
            VStack(alignment: .leading, spacing: 4) {
                Text("\(payment.type == .expense ? "-" : "+")$\(payment.amount, specifier: "%.2f")")
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(colorForTransactionType(payment.type))
                
                HStack {
                    Text(payment.frequency.rawValue)
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    if isDue && payment.isActive {
                        Text("DUE")
                            .font(.caption)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                            .padding(.horizontal, 4)
                            .padding(.vertical, 1)
                            .background(Color.red)
                            .clipShape(Capsule())
                    } else {
                        Text(nextDueDateFormatted)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
        }
        .padding()
        .frame(width: 180)
        .background(cardBackgroundColor)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .shadow(color: shadowColor, radius: 4, x: 0, y: 1)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(borderColor, lineWidth: colorScheme == .dark ? 1 : 0)
        )
        .opacity(payment.isActive ? 1.0 : 0.6)
    }
}

struct StatCardView: View {
    let title: String
    let amount: Double
    let color: Color
    let icon: String
    
    @Environment(\.colorScheme) private var colorScheme
    
    private var cardBackgroundColor: Color {
        if colorScheme == .dark {
            return Color(.systemGray6)
        } else {
            return Color(.systemBackground)
        }
    }
    
    private var borderColor: Color {
        if colorScheme == .dark {
            return Color(.systemGray4)
        } else {
            return Color.clear
        }
    }
    
    private var shadowColor: Color {
        if colorScheme == .dark {
            return Color.clear
        } else {
            return Color.black.opacity(0.05)
        }
    }
    
    var body: some View {
        VStack(spacing: 8) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(color)
                Text(title)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                Spacer()
            }
            
            HStack {
                Text("$\(amount, specifier: "%.2f")")
                    .font(.title3)
                    .fontWeight(.semibold)
                    .foregroundColor(color)
                Spacer()
            }
        }
        .padding()
        .background(cardBackgroundColor)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .shadow(color: shadowColor, radius: 4, x: 0, y: 1)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(borderColor, lineWidth: colorScheme == .dark ? 1 : 0)
        )
    }
}

#Preview {
    NavigationView {
        AccountDetailView(
            account: Account(
                name: "Chase Checking",
                startingBalance: 1500.00,
                icon: "creditcard",
                color: "Blue",
                accountType: .debit
            ),
            accountStore: AccountStore()
        )
    }
}
