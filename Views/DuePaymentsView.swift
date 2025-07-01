import SwiftUI

struct DuePaymentsView: View {
    let duePayments: [RecurringPayment]
    @ObservedObject var recurringStore: RecurringPaymentStore
    @ObservedObject var accountStore: AccountStore
    @EnvironmentObject var currencyManager: CurrencyManager
    @Environment(\.dismiss) private var dismiss
    
    private func colorForTransactionType(_ type: Transaction.TransactionType) -> Color {
        switch type {
        case .income: return .green
        case .expense: return .red
        case .transfer: return .blue
        }
    }
    
    private func processPayment(_ payment: RecurringPayment) {
        // Create transaction from payment
        let transaction = Transaction(
            amount: payment.amount,
            category: TransactionCategory.other, // We'll use the payment category
            accountId: payment.accountId,
            date: Date(),
            payee: payment.payee,
            type: payment.type,
            notes: "Recurring: \(payment.notes ?? "")"
        )
        
        // Add to account
        accountStore.addTransaction(transaction, to: payment.accountId)
        
        // Update recurring payment's next due date
        if let index = recurringStore.recurringPayments.firstIndex(where: { $0.id == payment.id }) {
            recurringStore.recurringPayments[index].lastProcessedDate = Date()
            recurringStore.recurringPayments[index].nextDueDate = payment.frequency.nextDate(from: payment.nextDueDate)
        }
    }
    
    var body: some View {
        NavigationView {
            VStack {
                if duePayments.isEmpty {
                    VStack(spacing: 16) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 50))
                            .foregroundColor(.green)
                        
                        Text("All Caught Up!")
                            .font(.headline)
                        
                        Text("No payments are due at this time")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    List {
                        ForEach(duePayments) { payment in
                            DuePaymentRowView(
                                payment: payment,
                                colorForTransactionType: colorForTransactionType,
                                onProcess: { processPayment(payment) },
                                currencyManager: currencyManager  // ← Added this parameter
                            )
                        }
                    }
                }
            }
            .navigationTitle("Due Payments")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

struct DuePaymentRowView: View {
    let payment: RecurringPayment
    let colorForTransactionType: (Transaction.TransactionType) -> Color
    let onProcess: () -> Void
    let currencyManager: CurrencyManager
    
    @State private var isProcessed = false
    
    var body: some View {
        HStack(spacing: 12) {
            // Icon
            ZStack {
                Circle()
                    .fill(colorForTransactionType(payment.type).opacity(0.2))
                    .frame(width: 40, height: 40)
                
                Image(systemName: payment.categoryIcon)
                    .font(.system(size: 16))
                    .foregroundColor(colorForTransactionType(payment.type))
            }
            
            // Payment Details
            VStack(alignment: .leading, spacing: 4) {
                Text(payment.name)
                    .font(.headline)
                    .strikethrough(isProcessed)
                
                Text(payment.payee)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                Text(payment.frequency.rawValue)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            // Amount and Action
            VStack(alignment: .trailing, spacing: 8) {
                Text("\(payment.type == .expense ? "-" : "+")\(currencyManager.formatAmount(payment.amount))")
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(colorForTransactionType(payment.type))
                    .strikethrough(isProcessed)
                
                if !isProcessed {
                    Button("Process") {
                        withAnimation {
                            isProcessed = true
                            onProcess()
                        }
                    }
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(.white)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 4)
                    .background(colorForTransactionType(payment.type))
                    .clipShape(Capsule())
                } else {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                        .font(.title3)
                }
            }
        }
        .padding(.vertical, 4)
        .opacity(isProcessed ? 0.6 : 1.0)
    }
}

#Preview {
    DuePaymentsView(
        duePayments: [],
        recurringStore: RecurringPaymentStore(),
        accountStore: AccountStore()
    )
    .environmentObject(CurrencyManager())
}
