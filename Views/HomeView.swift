import SwiftUI

struct HomeView: View {
    @StateObject private var accountStore = AccountStore()
    @StateObject private var recurringStore = RecurringPaymentStore()
    @State private var showingAddAccount = false
    @State private var showingManageCategories = false
    @State private var showingDuePayments = false
    @State private var showingAddTransfer = false
    
    private var duePayments: [RecurringPayment] {
        recurringStore.getDuePayments()
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // Header with financial overview
                    VStack(spacing: 12) {
                        VStack(spacing: 8) {
                            Text("Net Worth")
                                .font(.headline)
                                .foregroundColor(.secondary)
                            
                            Text("$\(accountStore.netWorth(), specifier: "%.2f")")
                                .font(.system(size: 32, weight: .bold, design: .rounded))
                                .foregroundColor(accountStore.netWorth() >= 0 ? .green : .red)
                        }
                        
                        // Show financial breakdown if there's debt
                        if accountStore.hasDebt() || accountStore.hasAssets() {
                            HStack(spacing: 20) {
                                if accountStore.hasAssets() {
                                    VStack(spacing: 4) {
                                        Text("Assets")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                        Text("$\(accountStore.totalAssets(), specifier: "%.2f")")
                                            .font(.subheadline)
                                            .fontWeight(.semibold)
                                            .foregroundColor(.green)
                                    }
                                }
                                
                                if accountStore.hasDebt() {
                                    VStack(spacing: 4) {
                                        Text("Debt")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                        Text("$\(accountStore.totalDebt(), specifier: "%.2f")")
                                            .font(.subheadline)
                                            .fontWeight(.semibold)
                                            .foregroundColor(.red)
                                    }
                                }
                                
                                if accountStore.totalAvailableCredit() > 0 {
                                    VStack(spacing: 4) {
                                        Text("Available Credit")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                        Text("$\(accountStore.totalAvailableCredit(), specifier: "%.2f")")
                                            .font(.subheadline)
                                            .fontWeight(.semibold)
                                            .foregroundColor(.blue)
                                    }
                                }
                            }
                            .padding()
                            .background(Color(.systemGray6))
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                        }
                        
                        // Financial health indicator
                        if accountStore.hasAssets() || accountStore.hasDebt() {
                            let healthScore = accountStore.financialHealthScore()
                            HStack {
                                Text("Financial Health")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                
                                Spacer()
                                
                                Text("\(Int(healthScore))%")
                                    .font(.caption)
                                    .fontWeight(.semibold)
                                    .foregroundColor(healthScore >= 70 ? .green : healthScore >= 40 ? .orange : .red)
                            }
                            .padding(.horizontal)
                        }
                    }
                    .padding(.top, 20)
                    
                    // Due Payments Alert
                    if !duePayments.isEmpty {
                        VStack(spacing: 12) {
                            HStack {
                                Image(systemName: "exclamationmark.triangle.fill")
                                    .foregroundColor(.orange)
                                Text("You have \(duePayments.count) payment(s) due")
                                    .font(.headline)
                                    .foregroundColor(.primary)
                                Spacer()
                            }
                            
                            Button(action: { showingDuePayments = true }) {
                                Text("Review Due Payments")
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                                    .foregroundColor(.white)
                                    .frame(maxWidth: .infinity)
                                    .padding()
                                    .background(Color.orange)
                                    .clipShape(RoundedRectangle(cornerRadius: 12))
                            }
                        }
                        .padding()
                        .background(Color.orange.opacity(0.1))
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                        .padding(.horizontal)
                    }
                    
                    // Quick Actions
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Quick Actions")
                            .font(.headline)
                            .padding(.horizontal)
                        
                        VStack(spacing: 12) {
                            HStack(spacing: 12) {
                                QuickActionButton(
                                    title: "Add Account",
                                    icon: "plus.circle.fill",
                                    color: .blue,
                                    action: { showingAddAccount = true }
                                )
                                
                                QuickActionButton(
                                    title: "Transfer Money",
                                    icon: "arrow.left.arrow.right.circle.fill",
                                    color: .purple,
                                    action: { showingAddTransfer = true }
                                )
                            }
                            
                            HStack(spacing: 12) {
                                QuickActionButton(
                                    title: "Manage Categories",
                                    icon: "tag.circle.fill",
                                    color: .orange,
                                    action: { showingManageCategories = true }
                                )
                                
                                QuickActionButton(
                                    title: "View Reports",
                                    icon: "chart.bar.fill",
                                    color: .green,
                                    action: { /* Future feature */ }
                                )
                            }
                        }
                        .padding(.horizontal)
                    }
                    
                    // Accounts Section
                    VStack(alignment: .leading, spacing: 16) {
                        HStack {
                            Text("Accounts")
                                .font(.title2)
                                .fontWeight(.semibold)
                            
                            Spacer()
                            
                            Button(action: { showingAddAccount = true }) {
                                HStack {
                                    Image(systemName: "plus.circle.fill")
                                        .font(.title2)
                                    Text("Add")
                                }
                                .foregroundColor(.blue)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(Color.blue.opacity(0.1))
                                .clipShape(Capsule())
                            }
                        }
                        .padding(.horizontal)
                        
                        if accountStore.accounts.isEmpty {
                            // Empty state
                            VStack(spacing: 12) {
                                Image(systemName: "creditcard")
                                    .font(.system(size: 50))
                                    .foregroundColor(.secondary)
                                
                                Text("No Accounts Yet")
                                    .font(.headline)
                                    .foregroundColor(.secondary)
                                
                                Text("Tap the 'Add' button to add your first account")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                                    .multilineTextAlignment(.center)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 40)
                        } else {
                            // Account cards - separate by type
                            VStack(alignment: .leading, spacing: 12) {
                                // Debit accounts (Assets)
                                let debitAccounts = accountStore.accounts.filter { $0.accountType == .debit }
                                if !debitAccounts.isEmpty {
                                    VStack(alignment: .leading, spacing: 8) {
                                        HStack {
                                            Text("Assets")
                                                .font(.headline)
                                                .foregroundColor(.green)
                                            Spacer()
                                            Text("$\(accountStore.totalAssets(), specifier: "%.2f")")
                                                .font(.subheadline)
                                                .fontWeight(.semibold)
                                                .foregroundColor(.green)
                                        }
                                        .padding(.horizontal)
                                        
                                        LazyVStack(spacing: 8) {
                                            ForEach(debitAccounts) { account in
                                                NavigationLink(destination: AccountDetailView(account: account, accountStore: accountStore)) {
                                                    AccountCardView(account: account)
                                                }
                                                .buttonStyle(PlainButtonStyle())
                                            }
                                        }
                                        .padding(.horizontal)
                                    }
                                }
                                
                                // Credit accounts (Liabilities)
                                let creditAccounts = accountStore.accounts.filter { $0.accountType == .credit }
                                if !creditAccounts.isEmpty {
                                    VStack(alignment: .leading, spacing: 8) {
                                        HStack {
                                            Text("Credit Cards")
                                                .font(.headline)
                                                .foregroundColor(.orange)
                                            Spacer()
                                            if accountStore.totalDebt() > 0 {
                                                Text("$\(accountStore.totalDebt(), specifier: "%.2f") debt")
                                                    .font(.subheadline)
                                                    .fontWeight(.semibold)
                                                    .foregroundColor(.red)
                                            } else {
                                                Text("$\(accountStore.totalAvailableCredit(), specifier: "%.2f") available")
                                                    .font(.subheadline)
                                                    .fontWeight(.semibold)
                                                    .foregroundColor(.green)
                                            }
                                        }
                                        .padding(.horizontal)
                                        
                                        LazyVStack(spacing: 8) {
                                            ForEach(creditAccounts) { account in
                                                NavigationLink(destination: AccountDetailView(account: account, accountStore: accountStore)) {
                                                    AccountCardView(account: account)
                                                }
                                                .buttonStyle(PlainButtonStyle())
                                            }
                                        }
                                        .padding(.horizontal)
                                    }
                                }
                            }
                        }
                    }
                }
            }
            .background(Color(.systemGroupedBackground).ignoresSafeArea())
            .navigationTitle("WhereIsMyMoney")
            .navigationBarTitleDisplayMode(.large)
        }
        .sheet(isPresented: $showingAddAccount) {
            AddAccountView(accountStore: accountStore)
        }
        .sheet(isPresented: $showingManageCategories) {
            ManageCategoriesView()
        }
        .sheet(isPresented: $showingDuePayments) {
            DuePaymentsView(
                duePayments: duePayments,
                recurringStore: recurringStore,
                accountStore: accountStore
            )
        }
        .sheet(isPresented: $showingAddTransfer) {
            AddTransferView(accountStore: accountStore)
        }
        .onAppear {
            // Process any due payments when app launches
            let processedTransactions = recurringStore.checkAndProcessDuePayments()
            
            // Add processed transactions to their respective accounts
            for transaction in processedTransactions {
                accountStore.addTransaction(transaction, to: transaction.accountId)
            }
        }
    }
}

struct QuickActionButton: View {
    let title: String
    let icon: String
    let color: Color
    let action: () -> Void
    
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
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(Color(.systemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 1)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

#Preview {
    HomeView()
}
