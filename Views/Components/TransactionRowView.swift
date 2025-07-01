import SwiftUI

struct TransactionRowView: View {
    let transaction: Transaction
    let accountId: UUID
    @ObservedObject var accountStore: AccountStore
    @ObservedObject var receiptManager: ReceiptManager
    
    // Optional running total - if provided, it will be displayed
    let runningTotal: Double?
    
    @EnvironmentObject var currencyManager: CurrencyManager
    
    @StateObject private var categoryStore = CategoryStore()
    @State private var showingEditSheet = false
    @State private var showingDeleteAlert = false
    @State private var showingReceiptDetail = false
    
    @Environment(\.colorScheme) private var colorScheme
    
    // Primary initializer with optional running total
    init(transaction: Transaction, accountId: UUID, accountStore: AccountStore, receiptManager: ReceiptManager, runningTotal: Double? = nil) {
        self.transaction = transaction
        self.accountId = accountId
        self.accountStore = accountStore
        self.receiptManager = receiptManager
        self.runningTotal = runningTotal
    }
    
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
            
            // Running Total Row (only displayed if runningTotal is provided)
            if let runningTotal = runningTotal {
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

// Keep existing initializers for backward compatibility
extension TransactionRowView {
    init(transaction: Transaction) {
        self.transaction = transaction
        self.accountId = transaction.accountId
        self.accountStore = AccountStore()
        self.receiptManager = ReceiptManager()
        self.runningTotal = nil
    }
    
    init(transaction: Transaction, accountId: UUID, accountStore: AccountStore) {
        self.transaction = transaction
        self.accountId = accountId
        self.accountStore = accountStore
        self.receiptManager = ReceiptManager()
        self.runningTotal = nil
    }
}

#Preview {
    VStack(spacing: 8) {
        // Preview without running total
        TransactionRowView(
            transaction: Transaction(
                amount: 45.50,
                category: .food,
                accountId: UUID(),
                date: Date(),
                payee: "Starbucks",
                type: .expense,
                notes: "Category: Coffee & Drinks | Morning coffee"
            ),
            accountId: UUID(),
            accountStore: AccountStore(),
            receiptManager: ReceiptManager()
        )
        
        // Preview with running total
        TransactionRowView(
            transaction: Transaction(
                amount: 150.00,
                category: .salary,
                accountId: UUID(),
                date: Date().addingTimeInterval(-86400),
                payee: "Employer Inc",
                type: .income,
                notes: "Category: Salary | Weekly paycheck"
            ),
            accountId: UUID(),
            accountStore: AccountStore(),
            receiptManager: ReceiptManager(),
            runningTotal: 1654.50
        )
    }
    .padding()
    .environmentObject(CurrencyManager())
}
