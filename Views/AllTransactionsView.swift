import SwiftUI

struct AllTransactionsView: View {
    let account: Account
    @ObservedObject var accountStore: AccountStore
    @StateObject private var receiptManager = ReceiptManager()
    @EnvironmentObject var currencyManager: CurrencyManager
    @State private var searchText = ""
    @State private var selectedFilter = FilterOption.all
    
    enum FilterOption: String, CaseIterable {
        case all = "All"
        case income = "Income"
        case expenses = "Expenses"
        case transfers = "Transfers"
        
        var systemImage: String {
            switch self {
            case .all: return "list.bullet"
            case .income: return "arrow.down.circle"
            case .expenses: return "arrow.up.circle"
            case .transfers: return "arrow.left.arrow.right.circle"
            }
        }
    }
    
    private var filteredTransactions: [Transaction] {
        let filtered = account.transactions.filter { transaction in
            // Filter by type
            switch selectedFilter {
            case .all:
                return true
            case .income:
                return transaction.type == .income
            case .expenses:
                return transaction.type == .expense
            case .transfers:
                return transaction.type == .transfer
            }
        }.filter { transaction in
            // Filter by search text
            if searchText.isEmpty {
                return true
            }
            
            return transaction.payee.localizedCaseInsensitiveContains(searchText) ||
                   transaction.notes?.localizedCaseInsensitiveContains(searchText) == true ||
                   String(transaction.amount).contains(searchText)
        }
        
        return filtered.sorted { $0.date > $1.date }
    }
    
    private var totalAmount: Double {
        filteredTransactions.reduce(0) { total, transaction in
            switch transaction.type {
            case .income:
                return total + transaction.amount
            case .expense:
                return total - transaction.amount
            case .transfer:
                return total // Transfers don't affect account total in this view
            }
        }
    }
    
    // Calculate running totals for each transaction
    private var transactionsWithRunningTotals: [(transaction: Transaction, runningTotal: Double)] {
        var runningTotal = account.startingBalance
        var results: [(transaction: Transaction, runningTotal: Double)] = []
        
        // Process transactions in chronological order (oldest first)
        let chronologicalTransactions = filteredTransactions.sorted { $0.date < $1.date }
        
        for transaction in chronologicalTransactions {
            switch transaction.type {
            case .income:
                runningTotal += transaction.amount
            case .expense:
                runningTotal -= transaction.amount
            case .transfer:
                // For transfers, we need to check if this account is the source or destination
                if let isSource = transaction.isTransferSource {
                    if isSource {
                        runningTotal -= transaction.amount // Money leaving this account
                    } else {
                        runningTotal += transaction.amount // Money coming into this account
                    }
                }
            }
            results.append((transaction: transaction, runningTotal: runningTotal))
        }
        
        // Return in reverse chronological order (newest first) for display
        return results.reversed()
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Summary Card
            VStack(spacing: 12) {
                HStack {
                    Text("\(filteredTransactions.count) Transactions")
                        .font(.headline)
                        .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    if selectedFilter != .all && selectedFilter != .transfers {
                        Text(currencyManager.formatAmount(abs(totalAmount)))
                            .font(.headline)
                            .fontWeight(.semibold)
                            .foregroundColor(totalAmount >= 0 ? .green : .red)
                    }
                }
                
                if selectedFilter != .all && selectedFilter != .transfers {
                    HStack {
                        Text(selectedFilter == .income ? "Total Income" : "Total Expenses")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        Spacer()
                    }
                }
                
                // Current Account Balance
                HStack {
                    Text("Current Balance")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    Text(currencyManager.formatAmount(account.currentBalance))
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(account.currentBalance >= 0 ? .green : .red)
                }
            }
            .padding()
            .background(Color(.systemGroupedBackground))
            
            // Filter Buttons
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(FilterOption.allCases, id: \.self) { option in
                        FilterChip(
                            title: option.rawValue,
                            systemImage: option.systemImage,
                            isSelected: selectedFilter == option
                        ) {
                            selectedFilter = option
                        }
                    }
                }
                .padding(.horizontal)
            }
            .padding(.vertical, 8)
            .background(Color(.systemGroupedBackground))
            
            // Search Bar
            if !filteredTransactions.isEmpty {
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.secondary)
                    
                    TextField("Search transactions...", text: $searchText)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                }
                .padding()
                .background(Color(.systemGroupedBackground))
            }
            
            // Transactions List
            if filteredTransactions.isEmpty {
                VStack(spacing: 16) {
                    Image(systemName: searchText.isEmpty ? "doc.text" : "magnifyingglass")
                        .font(.system(size: 50))
                        .foregroundColor(.secondary)
                    
                    Text(searchText.isEmpty ? "No transactions in this category" : "No matching transactions")
                        .font(.headline)
                        .foregroundColor(.secondary)
                    
                    if !searchText.isEmpty {
                        Text("Try adjusting your search terms")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                List {
                    ForEach(transactionsWithRunningTotals, id: \.transaction.id) { item in
                        TransactionRowWithTotalView(
                            transaction: item.transaction,
                            runningTotal: item.runningTotal,
                            accountId: account.id,
                            accountStore: accountStore,
                            receiptManager: receiptManager
                        )
                        .listRowInsets(EdgeInsets(top: 4, leading: 16, bottom: 4, trailing: 16))
                        .listRowBackground(Color.clear)
                    }
                }
                .listStyle(PlainListStyle())
            }
        }
        .navigationTitle("All Transactions")
        .navigationBarTitleDisplayMode(.inline)
        .background(Color(.systemGroupedBackground))
    }
}

// MARK: - Filter Chip Component
struct FilterChip: View {
    let title: String
    let systemImage: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Image(systemName: systemImage)
                    .font(.caption)
                
                Text(title)
                    .font(.caption)
                    .fontWeight(.medium)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(isSelected ? Color.blue : Color(.systemGray5))
            .foregroundColor(isSelected ? .white : .primary)
            .clipShape(Capsule())
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Transaction Row with Running Total
struct TransactionRowWithTotalView: View {
    let transaction: Transaction
    let runningTotal: Double
    let accountId: UUID
    @ObservedObject var accountStore: AccountStore
    @ObservedObject var receiptManager: ReceiptManager
    
    @EnvironmentObject var currencyManager: CurrencyManager
    @StateObject private var categoryStore = CategoryStore()
    @State private var showingEditSheet = false
    @State private var showingDeleteAlert = false
    @State private var showingReceiptDetail = false
    
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
    
    private var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: transaction.date)
    }
    
    private func colorForTransactionType(_ type: Transaction.TransactionType) -> Color {
        switch type {
        case .income: return .green
        case .expense: return .red
        case .transfer: return .blue
        }
    }
    
    private func colorForCategoryColor(_ colorName: String) -> Color {
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
    
    private var customCategoryName: String {
        if let notes = transaction.notes,
           notes.hasPrefix("Category: ") {
            let categoryPart = notes.components(separatedBy: " | ").first ?? notes
            return String(categoryPart.dropFirst("Category: ".count))
        }
        return transaction.category.rawValue
    }
    
    private var actualNotes: String? {
        if let notes = transaction.notes,
           notes.hasPrefix("Category: ") {
            let components = notes.components(separatedBy: " | ")
            return components.count > 1 ? components.dropFirst().joined(separator: " | ") : nil
        }
        return transaction.notes
    }
    
    // Better category icon and color logic
    private var categoryIconAndColor: (icon: String, color: Color) {
        // First try to get icon and color from custom categories
        if let notes = transaction.notes,
           notes.hasPrefix("Category: ") {
            let categoryName = String(notes.dropFirst("Category: ".count)).components(separatedBy: " | ").first ?? ""
            
            // Find matching custom category
            let allCategories = categoryStore.categoriesForType(.expense) + categoryStore.categoriesForType(.income)
            if let customCategory = allCategories.first(where: { $0.name == categoryName }) {
                return (customCategory.icon, colorForCategoryColor(customCategory.color))
            }
        }
        
        // Fallback to default transaction category icon with proper color
        return (transaction.category.systemImage, colorForTransactionType(transaction.type))
    }
    
    private var transferDisplayInfo: (payee: String, icon: String) {
        if transaction.type == .transfer {
            if let isSource = transaction.isTransferSource {
                if isSource {
                    return ("Transfer to \(transaction.payee.replacingOccurrences(of: "Transfer to ", with: ""))", "arrow.up.right.circle.fill")
                } else {
                    return ("Transfer from \(transaction.payee.replacingOccurrences(of: "Transfer from ", with: ""))", "arrow.down.left.circle.fill")
                }
            }
        }
        return (transaction.payee, categoryIconAndColor.icon)
    }
    
    // Check if transaction has associated receipt
    private var associatedReceipt: Receipt? {
        return receiptManager.receipts.first { $0.transactionId == transaction.id }
    }
    
    var body: some View {
        VStack(spacing: 8) {
            // Main Transaction Row
            HStack(spacing: 12) {
                // Category Icon with proper color
                ZStack {
                    Circle()
                        .fill(categoryIconAndColor.color.opacity(0.2))
                        .frame(width: 40, height: 40)
                    
                    Image(systemName: transaction.type == .transfer ? transferDisplayInfo.icon : categoryIconAndColor.icon)
                        .font(.system(size: 16))
                        .foregroundColor(categoryIconAndColor.color)
                }
                
                // Transaction Details
                VStack(alignment: .leading, spacing: 2) {
                    HStack {
                        Text(transferDisplayInfo.payee)
                            .font(.headline)
                            .lineLimit(1)
                        
                        Spacer()
                        
                        // Receipt icon if transaction has associated receipt
                        if associatedReceipt != nil {
                            Button(action: {
                                showingReceiptDetail = true
                            }) {
                                Image(systemName: "doc.text.image.fill")
                                    .font(.caption)
                                    .foregroundColor(.blue)
                                    .padding(4)
                                    .background(Color.blue.opacity(0.1))
                                    .clipShape(Circle())
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                    }
                    
                    HStack(spacing: 4) {
                        Text(customCategoryName)
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        Text("•")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        Text(formattedDate)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    if let notes = actualNotes, !notes.isEmpty {
                        Text(notes)
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .lineLimit(1)
                    }
                }
                
                Spacer()
                
                // Amount
                VStack(alignment: .trailing, spacing: 2) {
                    HStack(spacing: 4) {
                        Text(transaction.type == .expense || (transaction.type == .transfer && transaction.isTransferSource == true) ? "-" : "+")
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundColor(colorForTransactionType(transaction.type))
                        
                        Text(currencyManager.formatAmount(transaction.amount))
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundColor(colorForTransactionType(transaction.type))
                    }
                    
                    Image(systemName: transaction.type.systemImage)
                        .font(.caption)
                        .foregroundColor(colorForTransactionType(transaction.type))
                }
            }
            
            // Running Total Row
            HStack {
                Spacer()
                
                VStack(alignment: .trailing, spacing: 2) {
                    Text("Balance")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                    
                    Text(currencyManager.formatAmount(runningTotal))
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(runningTotal >= 0 ? .green : .red)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 2)
                        .background(Color(.systemGray6))
                        .clipShape(Capsule())
                }
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
        .contextMenu {
            // Receipt option if available
            if associatedReceipt != nil {
                Button(action: { showingReceiptDetail = true }) {
                    Label("View Receipt", systemImage: "doc.text.image")
                }
                
                Divider()
            }
            
            // Edit option
            Button(action: { showingEditSheet = true }) {
                Label("Edit Transaction", systemImage: "pencil")
            }
            .disabled(transaction.type == .transfer)
            
            // Delete option
            Button(action: { showingDeleteAlert = true }) {
                Label("Delete Transaction", systemImage: "trash")
            }
            
            Divider()
            
            // Info option
            Button(action: { /* Show transaction details */ }) {
                Label("Transaction Info", systemImage: "info.circle")
            }
        }
        .sheet(isPresented: $showingEditSheet) {
            EditTransactionView(
                transaction: transaction,
                accountId: accountId,
                accountStore: accountStore
            )
        }
        .sheet(isPresented: $showingReceiptDetail) {
            if let receipt = associatedReceipt {
                ReceiptDetailView(
                    receipt: receipt,
                    receiptManager: receiptManager,
                    accountStore: accountStore,
                    currencyManager: currencyManager
                )
            }
        }
        .alert("Delete Transaction", isPresented: $showingDeleteAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Delete", role: .destructive) {
                deleteTransaction()
            }
        } message: {
            if transaction.type == .transfer {
                Text("This will delete both sides of the transfer. This action cannot be undone.")
            } else {
                Text("Are you sure you want to delete this transaction? This action cannot be undone.")
            }
        }
    }
    
    private func deleteTransaction() {
        accountStore.deleteTransaction(transaction, from: accountId)
    }
}

#Preview {
    NavigationView {
        AllTransactionsView(
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
    .environmentObject(CurrencyManager())
}
