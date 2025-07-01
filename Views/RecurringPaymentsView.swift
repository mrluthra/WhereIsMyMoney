import SwiftUI

struct RecurringPaymentsView: View {
    let account: Account
    @ObservedObject var accountStore: AccountStore
    @StateObject private var recurringStore = RecurringPaymentStore()
    @EnvironmentObject var currencyManager: CurrencyManager
    @State private var showingAddPayment = false
    @State private var selectedPayment: RecurringPayment?
    @State private var showingEditPayment = false
    
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
                                colorForTransactionType: colorForTransactionType,
                                currencyManager: currencyManager,
                                onEdit: {
                                    selectedPayment = payment
                                    showingEditPayment = true
                                }
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
        .sheet(isPresented: $showingEditPayment) {
            if let payment = selectedPayment {
                EditRecurringPaymentView(
                    payment: payment,
                    account: account,
                    recurringStore: recurringStore,
                    accountStore: accountStore
                )
            }
        }
        .onAppear {
            // Configure the scheduler when the view appears
            RecurringPaymentScheduler.shared.configure(
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
    let currencyManager: CurrencyManager
    let onEdit: () -> Void
    
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
            
            // Amount and Controls
            VStack(alignment: .trailing, spacing: 8) {
                Text("\(payment.type == .expense ? "-" : "+")\(currencyManager.formatAmount(payment.amount))")
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(colorForTransactionType(payment.type))
                
                HStack(spacing: 8) {
                    // Edit button
                    Button(action: onEdit) {
                        Image(systemName: "pencil")
                            .font(.caption)
                            .foregroundColor(.blue)
                            .frame(width: 24, height: 24)
                            .background(Color.blue.opacity(0.1))
                            .clipShape(Circle())
                    }
                    .buttonStyle(PlainButtonStyle())
                    
                    // Active toggle
                    Toggle("", isOn: Binding(
                        get: { payment.isActive },
                        set: { _ in recurringStore.togglePaymentStatus(payment) }
                    ))
                    .labelsHidden()
                    .scaleEffect(0.8)
                }
            }
        }
        .padding(.vertical, 4)
        .opacity(payment.isActive ? 1.0 : 0.6)
        .contextMenu {
            Button(action: onEdit) {
                Label("Edit", systemImage: "pencil")
            }
            
            Button(action: {
                recurringStore.togglePaymentStatus(payment)
            }) {
                Label(payment.isActive ? "Deactivate" : "Activate",
                      systemImage: payment.isActive ? "pause.circle" : "play.circle")
            }
            
            Button(role: .destructive, action: {
                recurringStore.deleteRecurringPayment(payment)
            }) {
                Label("Delete", systemImage: "trash")
            }
        }
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
    .environmentObject(CurrencyManager())
}
