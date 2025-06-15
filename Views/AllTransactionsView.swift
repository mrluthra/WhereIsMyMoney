import SwiftUI

struct AllTransactionsView: View {
    let account: Account
    @ObservedObject var accountStore: AccountStore
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
                        Text("$\(abs(totalAmount), specifier: "%.2f")")
                            .font(.headline)
                            .fontWeight(.semibold)
                            .foregroundColor(totalAmount >= 0 ? .green : .red)
                    }
                }
                
                // Filter Picker
                Picker("Filter", selection: $selectedFilter) {
                    ForEach(FilterOption.allCases, id: \.self) { filter in
                        Label(filter.rawValue, systemImage: filter.systemImage)
                            .tag(filter)
                    }
                }
                .pickerStyle(.segmented)
            }
            .padding()
            .background(Color(.systemBackground))
            
            // Search Bar
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.secondary)
                
                TextField("Search transactions...", text: $searchText)
                    .textFieldStyle(PlainTextFieldStyle())
                
                if !searchText.isEmpty {
                    Button(action: { searchText = "" }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.secondary)
                    }
                }
            }
            .padding()
            .background(Color(.systemGray6))
            .clipShape(RoundedRectangle(cornerRadius: 10))
            .padding(.horizontal)
            .padding(.bottom)
            
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
                    ForEach(filteredTransactions) { transaction in
                        TransactionRowView(
                            transaction: transaction,
                            accountId: account.id,
                            accountStore: accountStore
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
}
