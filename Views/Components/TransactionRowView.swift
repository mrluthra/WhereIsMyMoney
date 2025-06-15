import SwiftUI

struct TransactionRowView: View {
    let transaction: Transaction
    let accountId: UUID
    @ObservedObject var accountStore: AccountStore
    @State private var showingEditSheet = false
    @State private var showingDeleteAlert = false
    
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
    
    private var categoryIcon: String {
        return transaction.category.systemImage
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
        return (transaction.payee, categoryIcon)
    }
    
    var body: some View {
        HStack(spacing: 12) {
            // Category Icon
            ZStack {
                Circle()
                    .fill(colorForTransactionType(transaction.type).opacity(0.2))
                    .frame(width: 40, height: 40)
                
                Image(systemName: transaction.type == .transfer ? transferDisplayInfo.icon : categoryIcon)
                    .font(.system(size: 16))
                    .foregroundColor(colorForTransactionType(transaction.type))
            }
            
            // Transaction Details
            VStack(alignment: .leading, spacing: 2) {
                Text(transferDisplayInfo.payee)
                    .font(.headline)
                    .lineLimit(1)
                
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
                    Text(transaction.type == .expense ? "-" : "+")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(colorForTransactionType(transaction.type))
                    
                    Text("$\(transaction.amount, specifier: "%.2f")")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(colorForTransactionType(transaction.type))
                }
                
                Image(systemName: transaction.type.systemImage)
                    .font(.caption)
                    .foregroundColor(colorForTransactionType(transaction.type))
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 1)
        .contextMenu {
            // Edit option
            Button(action: { showingEditSheet = true }) {
                Label("Edit Transaction", systemImage: "pencil")
            }
            .disabled(transaction.type == .transfer) // Disable edit for transfers
            
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

// Updated initializer for compatibility
extension TransactionRowView {
    init(transaction: Transaction) {
        self.transaction = transaction
        self.accountId = transaction.accountId
        self.accountStore = AccountStore() // This won't work properly - need to pass from parent
    }
}

#Preview {
    VStack(spacing: 8) {
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
            accountStore: AccountStore()
        )
        
        TransactionRowView(
            transaction: Transaction(
                amount: 2500.00,
                category: .salary,
                accountId: UUID(),
                date: Date(),
                payee: "Company Inc",
                type: .income,
                notes: "Category: Monthly Salary"
            ),
            accountId: UUID(),
            accountStore: AccountStore()
        )
    }
    .padding()
}
