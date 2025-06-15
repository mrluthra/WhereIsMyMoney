import SwiftUI

struct TransactionDetailView: View {
    let transaction: Transaction
    let accountId: UUID
    @ObservedObject var accountStore: AccountStore
    @Environment(\.dismiss) private var dismiss
    @State private var showingEditSheet = false
    @State private var showingDeleteAlert = false
    
    private var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE, MMMM d, yyyy 'at' h:mm a"
        return formatter.string(from: transaction.date)
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
    
    private func colorForTransactionType(_ type: Transaction.TransactionType) -> Color {
        switch type {
        case .income: return .green
        case .expense: return .red
        case .transfer: return .blue
        }
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Header Card
                    VStack(spacing: 16) {
                        // Amount
                        VStack(spacing: 8) {
                            Text("\(transaction.type == .expense ? "-" : "+")$\(transaction.amount, specifier: "%.2f")")
                                .font(.system(size: 36, weight: .bold, design: .rounded))
                                .foregroundColor(colorForTransactionType(transaction.type))
                            
                            Text(transaction.type.rawValue)
                                .font(.headline)
                                .foregroundColor(.secondary)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 4)
                                .background(colorForTransactionType(transaction.type).opacity(0.2))
                                .clipShape(Capsule())
                        }
                        
                        Divider()
                        
                        // Payee
                        VStack(spacing: 4) {
                            Text("Payee")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Text(transaction.payee)
                                .font(.title2)
                                .fontWeight(.semibold)
                        }
                    }
                    .padding()
                    .background(Color(.systemBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                    .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
                }
                
                // Details Cards
                VStack(spacing: 16) {
                    // Date & Time
                    DetailCard(
                        title: "Date & Time",
                        content: formattedDate,
                        icon: "calendar"
                    )
                    
                    // Category
                    DetailCard(
                        title: "Category",
                        content: customCategoryName,
                        icon: transaction.category.systemImage
                    )
                    
                    // Account
                    if let account = accountStore.getAccount(accountId) {
                        DetailCard(
                            title: "Account",
                            content: account.name,
                            icon: account.icon
                        )
                    }
                    
                    // Notes
                    if let notes = actualNotes, !notes.isEmpty {
                        DetailCard(
                            title: "Notes",
                            content: notes,
                            icon: "note.text"
                        )
                    }
                    
                    // Transfer Details
                    if transaction.type == .transfer {
                        if let targetAccountId = transaction.targetAccountId,
                           let targetAccount = accountStore.getAccount(targetAccountId) {
                            DetailCard(
                                title: transaction.isTransferSource == true ? "Transfer To" : "Transfer From",
                                content: targetAccount.name,
                                icon: "arrow.left.arrow.right"
                            )
                        }
                        
                        if let linkedId = transaction.linkedTransactionId {
                            DetailCard(
                                title: "Linked Transaction ID",
                                content: linkedId.uuidString.prefix(8).description,
                                icon: "link"
                            )
                        }
                    }
                    
                    // Transaction ID
                    DetailCard(
                        title: "Transaction ID",
                        content: transaction.id.uuidString.prefix(8).description,
                        icon: "number"
                    )
                }
                .padding(.horizontal)
                .padding(.bottom, 20)
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Transaction Details")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Close") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Menu {
                        Button(action: { showingEditSheet = true }) {
                            Label("Edit Transaction", systemImage: "pencil")
                        }
                        .disabled(transaction.type == .transfer)
                        
                        Button(action: { showingDeleteAlert = true }) {
                            Label("Delete Transaction", systemImage: "trash")
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                    }
                }
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
                accountStore.deleteTransaction(transaction, from: accountId)
                dismiss()
            }
        } message: {
            if transaction.type == .transfer {
                Text("This will delete both sides of the transfer. This action cannot be undone.")
            } else {
                Text("Are you sure you want to delete this transaction? This action cannot be undone.")
            }
        }
    }
}

struct DetailCard: View {
    let title: String
    let content: String
    let icon: String
    
    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(.blue)
                .frame(width: 30)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Text(content)
                    .font(.headline)
                    .foregroundColor(.primary)
            }
            
            Spacer()
        }
        .padding()
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 1)
    }
}

#Preview {
    TransactionDetailView(
        transaction: Transaction(
            amount: 45.50,
            category: .food,
            accountId: UUID(),
            date: Date(),
            payee: "Starbucks",
            type: .expense,
            notes: "Category: Coffee & Drinks | Morning coffee with extra shot"
        ),
        accountId: UUID(),
        accountStore: AccountStore()
    )
}
