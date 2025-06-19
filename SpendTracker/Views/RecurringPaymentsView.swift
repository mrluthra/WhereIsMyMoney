import SwiftUI

struct RecurringPaymentsView: View {
    let account: Account
    @ObservedObject var accountStore: AccountStore
    @StateObject private var recurringStore = RecurringPaymentStore()
    @State private var showingAddPayment = false
    
    private var accountPayments: [RecurringPayment] {
        recurringStore.getPaymentsForAccount(account.id)
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
            VStack {
                if accountPayments.isEmpty {
                    // Empty state
                    VStack(spacing: 16) {
                        Image(systemName: "calendar.badge.clock")
                            .font(.system(size: 50))
                            .foregroundColor(.secondary)
                        
                        Text("No Recurring Payments")
                            .font(.headline)
                            .foregroundColor(.secondary)
                        
                        Text("Set up automatic payments for bills, subscriptions, and regular income")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                        
                        Button(action: { showingAddPayment = true }) {
                            Label("Add Recurring Payment", systemImage: "plus.circle.fill")
                                .font(.headline)
                                .foregroundColor(.blue)
                                .padding()
                                .background(Color.blue.opacity(0.1))
                                .clipShape(Capsule())
                        }
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    List {
                        ForEach(accountPayments) { payment in
                            RecurringPaymentRowView(
                                payment: payment,
                                recurringStore: recurringStore,
                                colorForTransactionType: colorForTransactionType
                            )
                        }
                        .onDelete(perform: deletePayments)
                    }
                }
            }
            .navigationTitle("Recurring Payments")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showingAddPayment = true }) {
                        Image(systemName: "plus")
                    }
                }
            }
        }
        .sheet(isPresented: $showingAddPayment) {
            AddRecurringPaymentView(
                account: account,
                recurringStore: recurringStore,
                accountStore: accountStore
            )
        }
    }
    
    private func deletePayments(offsets: IndexSet) {
        for index in offsets {
            let payment = accountPayments[index]
            recurringStore.deleteRecurringPayment(payment)
        }
    }
}

struct RecurringPaymentRowView: View {
    let payment: RecurringPayment
    @ObservedObject var recurringStore: RecurringPaymentStore
    let colorForTransactionType: (Transaction.TransactionType) -> Color
    
    private var nextDueDateFormatted: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: payment.nextDueDate)
    }
    
    private var isDue: Bool {
        payment.nextDueDate <= Date()
    }
    
    var body: some View {
        HStack(spacing: 12) {
            // Icon and Status
            VStack {
                ZStack {
                    Circle()
                        .fill(colorForTransactionType(payment.type).opacity(0.2))
                        .frame(width: 40, height: 40)
                    
                    Image(systemName: payment.categoryIcon)
                        .font(.system(size: 16))
                        .foregroundColor(colorForTransactionType(payment.type))
                }
                
                // Status indicator
                Circle()
                    .fill(payment.isActive ? .green : .gray)
                    .frame(width: 8, height: 8)
            }
            
            // Payment Details
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(payment.name)
                        .font(.headline)
                        .lineLimit(1)
                    
                    if isDue && payment.isActive {
                        Text("DUE")
                            .font(.caption)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.red)
                            .clipShape(Capsule())
                    }
                }
                
                Text(payment.payee)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                HStack(spacing: 4) {
                    Image(systemName: payment.frequency.systemImage)
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Text(payment.frequency.rawValue)
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Text("•")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Text("Next: \(nextDueDateFormatted)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
            
            // Amount and Toggle
            VStack(alignment: .trailing, spacing: 8) {
                Text("\(payment.type == .expense ? "-" : "+")$\(payment.amount, specifier: "%.2f")")
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(colorForTransactionType(payment.type))
                
                Toggle("", isOn: Binding(
                    get: { payment.isActive },
                    set: { _ in recurringStore.togglePaymentStatus(payment) }
                ))
                .labelsHidden()
                .scaleEffect(0.8)
            }
        }
        .padding(.vertical, 4)
        .opacity(payment.isActive ? 1.0 : 0.6)
    }
}

#Preview {
    RecurringPaymentsView(
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
