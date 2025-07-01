import SwiftUI

struct EditTransactionView: View {
    let transaction: Transaction
    let accountId: UUID
    @ObservedObject var accountStore: AccountStore
    @StateObject private var categoryStore = CategoryStore()
    @EnvironmentObject var currencyManager: CurrencyManager
    
    @Environment(\.dismiss) private var dismiss
    
    @State private var amount: String
    @State private var payee: String
    @State private var notes: String
    @State private var selectedType: Transaction.TransactionType
    @State private var selectedCategory: CustomCategory?
    @State private var selectedDate: Date
    @State private var selectedAccountId: UUID?
    @State private var showingAccountSelection = false
    
    // Initialize with existing transaction data
    init(transaction: Transaction, accountId: UUID, accountStore: AccountStore) {
        self.transaction = transaction
        self.accountId = accountId
        self.accountStore = accountStore
        
        // Initialize state with existing values
        self._amount = State(initialValue: String(transaction.amount))
        self._payee = State(initialValue: transaction.payee)
        self._notes = State(initialValue: transaction.notes?.replacingOccurrences(of: "Category: ", with: "").components(separatedBy: " | ").dropFirst().joined(separator: " | ") ?? "")
        self._selectedType = State(initialValue: transaction.type)
        self._selectedDate = State(initialValue: transaction.date)
        self._selectedAccountId = State(initialValue: accountId)
    }
    
    private var availableCategories: [CustomCategory] {
        categoryStore.categoriesForType(selectedType == .income ? .income : .expense)
    }
    
    private var selectedAccount: Account? {
        guard let selectedAccountId = selectedAccountId else { return nil }
        return accountStore.getAccount(selectedAccountId)
    }
    
    private var availableAccounts: [Account] {
        accountStore.accounts.filter { $0.accountType != .credit || selectedType != .income }
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
    
    var body: some View {
        NavigationView {
            Form {
                if selectedType == .transfer {
                    transferNotEditableSection
                } else {
                    transactionDetailsSection
                    accountSelectionSection
                    categorySection
                    notesSection
                    previewSection
                }
            }
            .navigationTitle("Edit Transaction")
            .navigationBarTitleDisplayMode(.inline)
            .onAppear {
                setupInitialCategory()
            }
            .sheet(isPresented: $showingAccountSelection) {
                EditTransactionAccountSelectionSheet(
                    accounts: availableAccounts,
                    selectedAccountId: $selectedAccountId,
                    colorForAccount: colorForAccount,
                    currencyManager: currencyManager
                )
            }
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        saveChanges()
                    }
                    .fontWeight(.semibold)
                    .disabled(!isFormValid || selectedType == .transfer)
                }
            }
        }
    }
    
    // MARK: - Form Sections
    
    private var transferNotEditableSection: some View {
        Section {
            VStack(spacing: 16) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.system(size: 40))
                    .foregroundColor(.orange)
                
                Text("Transfer transactions cannot be edited")
                    .font(.headline)
                    .multilineTextAlignment(.center)
                
                Text("To modify this transfer, please delete it and create a new one.")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 20)
        }
    }
    
    private var transactionDetailsSection: some View {
        Section(header: Text("Transaction Details")) {
            // Transaction Type
            Picker("Type", selection: $selectedType) {
                ForEach([Transaction.TransactionType.income, Transaction.TransactionType.expense], id: \.self) { type in
                    Label(type.rawValue, systemImage: type.systemImage)
                        .tag(type)
                }
            }
            .pickerStyle(.segmented)
            .onChange(of: selectedType) { oldValue, newValue in
                selectedCategory = availableCategories.first
            }
            
            // Amount
            HStack {
                Text(selectedType == .expense ? "-" : "+")
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(colorForTransactionType(selectedType))
                
                TextField("0.00", text: $amount)
                    .keyboardType(.decimalPad)
                    .font(.headline)
                    .multilineTextAlignment(.trailing)
            }
            
            // Payee
            TextField("Payee/Merchant", text: $payee)
                .textInputAutocapitalization(.words)
            
            // Date
            DatePicker("Date", selection: $selectedDate, displayedComponents: .date)
        }
    }
    
    private var accountSelectionSection: some View {
        Section(header: Text("Account")) {
            Button(action: { showingAccountSelection = true }) {
                HStack(spacing: 12) {
                    if let account = selectedAccount {
                        // Account Icon
                        ZStack {
                            Circle()
                                .fill(colorForAccount(account.color).opacity(0.2))
                                .frame(width: 32, height: 32)
                            
                            Image(systemName: account.icon)
                                .font(.system(size: 14))
                                .foregroundColor(colorForAccount(account.color))
                        }
                        
                        // Account Details
                        VStack(alignment: .leading, spacing: 2) {
                            Text(account.name)
                                .font(.headline)
                                .foregroundColor(.primary)
                            
                            HStack {
                                Text(account.accountType.rawValue)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                
                                Text("•")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                
                                Text(currencyManager.formatAmount(account.currentBalance))
                                    .font(.caption)
                                    .foregroundColor(account.currentBalance >= 0 ? .green : .red)
                            }
                        }
                        
                        Spacer()
                        
                        // Change indicator
                        if let selectedId = selectedAccountId, selectedId != accountId {
                            VStack(alignment: .trailing, spacing: 2) {
                                Text("Changed")
                                    .font(.caption2)
                                    .fontWeight(.medium)
                                    .foregroundColor(.orange)
                                
                                Text("from \(accountStore.getAccountName(accountId))")
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
                                    .lineLimit(1)
                            }
                        }
                        
                        Image(systemName: "chevron.right")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    } else {
                        Text("Select Account")
                            .foregroundColor(.secondary)
                        Spacer()
                        Image(systemName: "chevron.right")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
            .buttonStyle(PlainButtonStyle())
        }
    }
    
    private var categorySection: some View {
        Section(header: Text("Category")) {
            if availableCategories.isEmpty {
                Text("No categories available")
                    .foregroundColor(.secondary)
            } else {
                Picker("Category", selection: $selectedCategory) {
                    ForEach(availableCategories, id: \.id) { category in
                        HStack {
                            Image(systemName: category.icon)
                                .foregroundColor(colorForCategoryColor(category.color))
                            Text(category.name)
                        }
                        .tag(category as CustomCategory?)
                    }
                }
                .pickerStyle(.menu)
            }
        }
    }
    
    private var notesSection: some View {
        Section(header: Text("Notes (Optional)")) {
            TextField("Add notes...", text: $notes, axis: .vertical)
                .lineLimit(3...6)
        }
    }
    
    private var previewSection: some View {
        Section(header: Text("Preview")) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(payee.isEmpty ? "Payee" : payee)
                        .font(.headline)
                        .foregroundColor(payee.isEmpty ? .secondary : .primary)
                    
                    if let category = selectedCategory {
                        HStack {
                            Image(systemName: category.icon)
                                .foregroundColor(colorForCategoryColor(category.color))
                            Text(category.name)
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    if let account = selectedAccount {
                        HStack {
                            Image(systemName: account.icon)
                                .foregroundColor(colorForAccount(account.color))
                            Text(account.name)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    Text("\(selectedType == .expense ? "-" : "+")\(currencyManager.formatAmount(Double(amount) ?? 0))")
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(colorForTransactionType(selectedType))
                    
                    Text(selectedDate.formatted(date: .abbreviated, time: .omitted))
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .padding(.vertical, 4)
        }
    }
    
    // MARK: - Helper Methods
    
    private func setupInitialCategory() {
        // Set initial category based on existing transaction
        if let existingNotes = transaction.notes,
           existingNotes.hasPrefix("Category: ") {
            let categoryName = String(existingNotes.dropFirst("Category: ".count)).components(separatedBy: " | ").first ?? ""
            selectedCategory = availableCategories.first { $0.name == categoryName }
        }
        
        if selectedCategory == nil {
            selectedCategory = availableCategories.first
        }
    }
    
    private var isFormValid: Bool {
        if selectedType == .transfer {
            return false
        }
        
        return !amount.isEmpty &&
        !payee.trimmingCharacters(in: .whitespaces).isEmpty &&
        Double(amount) != nil &&
        (Double(amount) ?? 0) > 0 &&
        selectedCategory != nil
    }
    
    private func saveChanges() {
        guard let transactionAmount = Double(amount),
              let category = selectedCategory,
              selectedType != .transfer,
              let targetAccountId = selectedAccountId else { return }
        
        var updatedTransaction = transaction
        updatedTransaction.amount = transactionAmount
        updatedTransaction.payee = payee.trimmingCharacters(in: .whitespaces)
        updatedTransaction.date = selectedDate
        updatedTransaction.type = selectedType
        updatedTransaction.notes = "Category: \(category.name)" + (notes.trimmingCharacters(in: .whitespaces).isEmpty ? "" : " | \(notes.trimmingCharacters(in: .whitespaces))")
        
        // Check if account changed
        if targetAccountId != accountId {
            // Move transaction to new account
            accountStore.moveTransaction(updatedTransaction, from: accountId, to: targetAccountId)
        } else {
            // Update transaction in same account
            accountStore.updateTransaction(updatedTransaction, in: accountId)
        }
        
        dismiss()
    }
}

// MARK: - Account Selection Sheet for Edit Transaction
struct EditTransactionAccountSelectionSheet: View {
    let accounts: [Account]
    @Binding var selectedAccountId: UUID?
    let colorForAccount: (String) -> Color
    let currencyManager: CurrencyManager
    
    @Environment(\.dismiss) private var dismiss
    @State private var tempSelectedAccountId: UUID?
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Header with current selection
                if let selectedId = tempSelectedAccountId,
                   let selectedAccount = accounts.first(where: { $0.id == selectedId }) {
                    VStack(spacing: 12) {
                        Text("Selected Account")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        
                        HStack(spacing: 12) {
                            ZStack {
                                Circle()
                                    .fill(colorForAccount(selectedAccount.color).opacity(0.2))
                                    .frame(width: 40, height: 40)
                                
                                Image(systemName: selectedAccount.icon)
                                    .font(.system(size: 18))
                                    .foregroundColor(colorForAccount(selectedAccount.color))
                            }
                            
                            VStack(alignment: .leading, spacing: 2) {
                                Text(selectedAccount.name)
                                    .font(.headline)
                                    .foregroundColor(.primary)
                                
                                HStack {
                                    Text(selectedAccount.accountType.rawValue)
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                    
                                    Text("•")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                    
                                    Text(currencyManager.formatAmount(selectedAccount.currentBalance))
                                        .font(.caption)
                                        .foregroundColor(selectedAccount.currentBalance >= 0 ? .green : .red)
                                }
                            }
                            
                            Spacer()
                            
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.green)
                                .font(.title2)
                        }
                        .padding()
                        .background(Color.green.opacity(0.1))
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                    .padding()
                    .background(Color(.systemGroupedBackground))
                }
                
                Divider()
                
                // Account list
                List {
                    Section("Available Accounts") {
                        ForEach(accounts) { account in
                            EditTransactionAccountSelectionRowView(
                                account: account,
                                isSelected: tempSelectedAccountId == account.id,
                                colorForAccount: colorForAccount,
                                currencyManager: currencyManager
                            ) {
                                tempSelectedAccountId = account.id
                            }
                        }
                    }
                }
                .listStyle(InsetGroupedListStyle())
            }
            .navigationTitle("Select Account")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        selectedAccountId = tempSelectedAccountId
                        dismiss()
                    }
                    .fontWeight(.semibold)
                    .disabled(tempSelectedAccountId == nil)
                }
            }
        }
        .onAppear {
            tempSelectedAccountId = selectedAccountId
        }
    }
}

// MARK: - Account Selection Row View for Edit Transaction
struct EditTransactionAccountSelectionRowView: View {
    let account: Account
    let isSelected: Bool
    let colorForAccount: (String) -> Color
    let currencyManager: CurrencyManager
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 16) {
                // Account Icon
                ZStack {
                    Circle()
                        .fill(colorForAccount(account.color).opacity(0.2))
                        .frame(width: 40, height: 40)
                    
                    Image(systemName: account.icon)
                        .font(.system(size: 18))
                        .foregroundColor(colorForAccount(account.color))
                }
                
                // Account Info
                VStack(alignment: .leading, spacing: 4) {
                    Text(account.name)
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    HStack {
                        Text(account.accountType.rawValue)
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        Text("•")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        Text(currencyManager.formatAmount(account.currentBalance))
                            .font(.caption)
                            .foregroundColor(account.currentBalance >= 0 ? .green : .red)
                    }
                }
                
                Spacer()
                
                // Selection indicator
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.blue)
                        .font(.title3)
                } else {
                    Image(systemName: "circle")
                        .foregroundColor(.secondary)
                        .font(.title3)
                }
            }
            .padding(.vertical, 4)
            .contentShape(Rectangle())
        }
        .buttonStyle(PlainButtonStyle())
    }
}

#Preview {
    EditTransactionView(
        transaction: Transaction(
            amount: 45.50,
            category: .food,
            accountId: UUID(),
            date: Date(),
            payee: "Starbucks",
            type: .expense,
            notes: "Category: Food & Dining | Morning coffee"
        ),
        accountId: UUID(),
        accountStore: AccountStore()
    )
    .environmentObject(CurrencyManager())
}
