import SwiftUI

struct QuickAddTransactionView: View {
    @ObservedObject var accountStore: AccountStore
    @StateObject private var categoryStore = CategoryStore()
    @StateObject private var smartEngine = SmartCategorizationEngine()
    @StateObject private var payeeSuggestionEngine = PayeeSuggestionEngine()
    @EnvironmentObject var currencyManager: CurrencyManager
    @Environment(\.dismiss) private var dismiss
    
    @State private var amount = ""
    @State private var payee = ""
    @State private var notes = ""
    @State private var selectedType = Transaction.TransactionType.expense
    @State private var selectedCategory: CustomCategory?
    @State private var selectedDate = Date()
    @State private var selectedAccountId: UUID?
    @State private var showingAccountSelection = false
    @State private var aiSuggestedCategory: CustomCategory?
    @State private var showingAISuggestion = false
    @State private var payeeSuggestions: [PayeeSuggestionEngine.PayeeSuggestion] = []
    @State private var showingPayeeSuggestions = false
    
    private var availableCategories: [CustomCategory] {
        categoryStore.categoriesForType(selectedType == .income ? .income : .expense)
    }
    
    private var selectedAccount: Account? {
        guard let accountId = selectedAccountId else { return nil }
        return accountStore.getAccount(accountId)
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
    
    var body: some View {
        NavigationView {
            Form {
                accountSelectionSection
                
                if selectedAccountId != nil {
                    transactionTypeSection
                    transactionDetailsSection
                    
                    if showingAISuggestion, let suggested = aiSuggestedCategory {
                        aiSuggestionSection(suggested: suggested)
                    }
                    
                    categorySelectionSection
                    
                    if isFormValid {
                        previewSection
                    }
                }
            }
            .navigationTitle("Quick Add Transaction")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        saveTransaction()
                    }
                    .fontWeight(.semibold)
                    .disabled(!isFormValid)
                }
            }
        }
        .sheet(isPresented: $showingAccountSelection) {
            AccountSelectionSheet(
                accounts: accountStore.accounts,
                selectedAccountId: $selectedAccountId,
                colorForAccount: colorForAccount,
                currencyManager: currencyManager
            )
        }
        .onAppear {
            setupInitialValues()
        }
    }
    
    // MARK: - Form Sections
    
    private var accountSelectionSection: some View {
        Section(header: Text("Select Account")) {
            if accountStore.accounts.isEmpty {
                noAccountsView
            } else {
                accountSelectionButton
            }
        }
    }
    
    private var noAccountsView: some View {
        VStack(spacing: 12) {
            Image(systemName: "creditcard.slash")
                .font(.title)
                .foregroundColor(.secondary)
            
            Text("No Accounts Available")
                .font(.headline)
                .foregroundColor(.secondary)
            
            Text("Please add an account first before creating transactions")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 20)
    }
    
    private var accountSelectionButton: some View {
        Button(action: { showingAccountSelection = true }) {
            HStack(spacing: 16) {
                accountIcon
                accountDetails
                Spacer()
                chevronIcon
            }
            .padding(.vertical, 8)
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private var accountIcon: some View {
        Group {
            if let account = selectedAccount {
                ZStack {
                    Circle()
                        .fill(colorForAccount(account.color).opacity(0.2))
                        .frame(width: 40, height: 40)
                    
                    Image(systemName: account.icon)
                        .font(.system(size: 18))
                        .foregroundColor(colorForAccount(account.color))
                }
            } else {
                ZStack {
                    Circle()
                        .fill(Color.gray.opacity(0.2))
                        .frame(width: 40, height: 40)
                    
                    Image(systemName: "plus")
                        .font(.system(size: 18))
                        .foregroundColor(.gray)
                }
            }
        }
    }
    
    private var accountDetails: some View {
        Group {
            if let account = selectedAccount {
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
            } else {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Select Account")
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    Text("Choose which account for this transaction")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
    }
    
    private var chevronIcon: some View {
        Image(systemName: "chevron.right")
            .font(.caption)
            .foregroundColor(.secondary)
    }
    
    private var transactionTypeSection: some View {
        Section(header: Text("Transaction Type")) {
            Picker("Type", selection: $selectedType) {
                ForEach([Transaction.TransactionType.income, Transaction.TransactionType.expense], id: \.self) { type in
                    Label(type.rawValue, systemImage: type.systemImage)
                        .tag(type)
                }
            }
            .pickerStyle(.segmented)
            .onChange(of: selectedType) { oldValue, newValue in
                selectedCategory = availableCategories.first
                checkForAISuggestion()
            }
        }
    }
    
    private var transactionDetailsSection: some View {
        Section(header: Text("Transaction Details")) {
            amountField
            payeeField
            DatePicker("Date", selection: $selectedDate, displayedComponents: .date)
            notesField
        }
    }
    
    private var amountField: some View {
        HStack {
            Text(selectedType == .expense ? "-\(currencyManager.currencySymbol)" : "+\(currencyManager.currencySymbol)")
                .font(.headline)
                .foregroundColor(colorForTransactionType(selectedType))
            
            TextField("Amount", text: $amount)
                .keyboardType(.decimalPad)
                .font(.headline)
                .onChange(of: amount) { oldValue, newValue in
                    checkForAISuggestion()
                }
        }
    }
    
    private var payeeField: some View {
        VStack(spacing: 0) {
            TextField("Payee/Description", text: $payee)
                .textInputAutocapitalization(.words)
                .onChange(of: payee) { oldValue, newValue in
                    updatePayeeSuggestions(for: newValue)
                    checkForAISuggestion()
                }
            
            if showingPayeeSuggestions && !payeeSuggestions.isEmpty {
                PayeeSuggestionView(
                    suggestions: payeeSuggestions,
                    onSelect: { suggestion in
                        selectPayeeSuggestion(suggestion)
                    }
                )
                .padding(.top, 8)
            }
        }
    }
    
    private var notesField: some View {
        TextField("Notes (Optional)", text: $notes, axis: .vertical)
            .lineLimit(2...4)
    }
    
    private func aiSuggestionSection(suggested: CustomCategory) -> some View {
        Section {
            HStack(spacing: 12) {
                aiIcon
                aiSuggestionContent(suggested: suggested)
                Spacer()
                aiActionButtons(suggested: suggested)
            }
            .padding()
            .background(Color.blue.opacity(0.05))
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
    }
    
    private var aiIcon: some View {
        ZStack {
            Circle()
                .fill(Color.blue.opacity(0.2))
                .frame(width: 35, height: 35)
            
            Image(systemName: "brain.head.profile")
                .font(.system(size: 16))
                .foregroundColor(.blue)
        }
    }
    
    private func aiSuggestionContent(suggested: CustomCategory) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text("AI Suggestion")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(.blue)
                
                Image(systemName: "sparkles")
                    .font(.caption)
                    .foregroundColor(.blue)
            }
            
            Text("Suggested category: \(suggested.name)")
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
    
    private func aiActionButtons(suggested: CustomCategory) -> some View {
        HStack(spacing: 8) {
            Button("Use") {
                selectedCategory = suggested
                showingAISuggestion = false
            }
            .font(.caption)
            .fontWeight(.medium)
            .foregroundColor(.white)
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(Color.blue)
            .clipShape(Capsule())
            
            Button("Dismiss") {
                showingAISuggestion = false
            }
            .font(.caption)
            .foregroundColor(.secondary)
        }
    }
    
    private var categorySelectionSection: some View {
        Section(header: Text("Category")) {
            if availableCategories.isEmpty {
                noCategoriesView
            } else {
                categoryGrid
                
                if availableCategories.count > 6 {
                    viewAllCategoriesLink
                }
            }
        }
    }
    
    private var noCategoriesView: some View {
        VStack(spacing: 12) {
            Image(systemName: "tag.slash")
                .font(.title)
                .foregroundColor(.secondary)
            
            Text("No Categories Available")
                .font(.headline)
                .foregroundColor(.secondary)
            
            Text("Please add categories first in Manage Categories")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 20)
    }
    
    private var categoryGrid: some View {
        LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 3), spacing: 12) {
            ForEach(Array(availableCategories.prefix(6)), id: \.id) { category in
                categoryButton(for: category)
            }
        }
        .padding(.vertical, 8)
    }
    
    private func categoryButton(for category: CustomCategory) -> some View {
        Button(action: {
            selectedCategory = category
            showingAISuggestion = false
        }) {
            VStack(spacing: 8) {
                categoryButtonIcon(for: category)
                categoryButtonText(for: category)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 8)
            .background(
                selectedCategory?.id == category.id
                ? colorForCategoryColor(category.color).opacity(0.1)
                : Color.clear
            )
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private func categoryButtonIcon(for category: CustomCategory) -> some View {
        ZStack {
            Circle()
                .fill(selectedCategory?.id == category.id
                      ? colorForCategoryColor(category.color)
                      : colorForCategoryColor(category.color).opacity(0.2))
                .frame(width: 40, height: 40)
            
            Image(systemName: category.icon)
                .font(.system(size: 16))
                .foregroundColor(selectedCategory?.id == category.id
                               ? .white
                               : colorForCategoryColor(category.color))
        }
    }
    
    private func categoryButtonText(for category: CustomCategory) -> some View {
        Text(category.name)
            .font(.caption)
            .fontWeight(.medium)
            .foregroundColor(selectedCategory?.id == category.id ? .primary : .secondary)
            .multilineTextAlignment(.center)
            .lineLimit(2)
    }
    
    private var viewAllCategoriesLink: some View {
        NavigationLink(destination: CategorySelectionView(
            categories: availableCategories,
            selectedCategory: $selectedCategory,
            colorForCategoryColor: colorForCategoryColor
        )) {
            HStack {
                Text("View All Categories")
                    .font(.subheadline)
                    .foregroundColor(.blue)
                Spacer()
                Text("\(availableCategories.count) total")
                    .font(.caption)
                    .foregroundColor(.secondary)
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding(.vertical, 4)
        }
    }
    
    private var previewSection: some View {
        Section(header: Text("Preview")) {
            HStack(spacing: 12) {
                previewIcon
                previewDetails
                Spacer()
                previewAmount
            }
            .padding(.vertical, 4)
        }
    }
    
    private var previewIcon: some View {
        Group {
            if let category = selectedCategory {
                Image(systemName: category.icon)
                    .foregroundColor(colorForCategoryColor(category.color))
            }
        }
    }
    
    private var previewDetails: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(payee)
                .font(.headline)
            if let category = selectedCategory {
                Text(category.name)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            if let account = selectedAccount {
                Text(account.name)
                    .font(.caption)
                    .foregroundColor(.blue)
            }
        }
    }
    
    private var previewAmount: some View {
        Text("\(selectedType == .expense ? "-" : "+")\(currencyManager.formatAmount(Double(amount) ?? 0))")
            .font(.headline)
            .fontWeight(.semibold)
            .foregroundColor(colorForTransactionType(selectedType))
    }
    
    // MARK: - Helper Methods
    
    private func setupInitialValues() {
        if accountStore.accounts.count == 1 {
            selectedAccountId = accountStore.accounts.first?.id
        }
        selectedCategory = availableCategories.first
    }
    
    private func updatePayeeSuggestions(for query: String) {
        if query.count >= 2 {
            payeeSuggestions = payeeSuggestionEngine.getPayeeSuggestions(
                for: query,
                from: accountStore.accounts,
                categories: availableCategories,
                limit: 5
            )
            showingPayeeSuggestions = !payeeSuggestions.isEmpty
        } else {
            payeeSuggestions = []
            showingPayeeSuggestions = false
        }
    }
    
    private func selectPayeeSuggestion(_ suggestion: PayeeSuggestionEngine.PayeeSuggestion) {
        payee = suggestion.name
        showingPayeeSuggestions = false
        
        if let matchingCategory = availableCategories.first(where: {
            $0.name.lowercased() == suggestion.mostCommonCategory.lowercased()
        }) {
            selectedCategory = matchingCategory
            showingAISuggestion = false
        }
        
        if suggestion.averageAmount > 0 && amount.isEmpty {
            amount = String(format: "%.2f", suggestion.averageAmount)
        }
    }
    
    private func checkForAISuggestion() {
        guard !payee.isEmpty,
              payee.count > 2,
              selectedCategory == nil || showingAISuggestion else { return }
        
        let amountValue = Double(amount) ?? 0
        
        let suggestion = smartEngine.suggestCategory(
            for: payee,
            amount: amountValue,
            existingCategories: availableCategories
        )
        
        if let suggestion = suggestion, suggestion.id != selectedCategory?.id {
            aiSuggestedCategory = suggestion
            withAnimation(.easeInOut(duration: 0.3)) {
                showingAISuggestion = true
            }
        }
    }
    
    private var isFormValid: Bool {
        !amount.isEmpty &&
        !payee.trimmingCharacters(in: .whitespaces).isEmpty &&
        Double(amount) != nil &&
        (Double(amount) ?? 0) > 0 &&
        selectedCategory != nil &&
        selectedAccountId != nil
    }
    
    private func saveTransaction() {
        guard let transactionAmount = Double(amount),
              let category = selectedCategory,
              let accountId = selectedAccountId else { return }
        
        let newTransaction = Transaction(
            amount: transactionAmount,
            category: TransactionCategory.other,
            accountId: accountId,
            date: selectedDate,
            payee: payee.trimmingCharacters(in: .whitespaces),
            type: selectedType,
            notes: "Category: \(category.name)" + (notes.trimmingCharacters(in: .whitespaces).isEmpty ? "" : " | \(notes.trimmingCharacters(in: .whitespaces))")
        )
        
        accountStore.addTransaction(newTransaction, to: accountId)
        dismiss()
    }
}

// MARK: - Account Selection Sheet

struct AccountSelectionSheet: View {
    let accounts: [Account]
    @Binding var selectedAccountId: UUID?
    let colorForAccount: (String) -> Color
    let currencyManager: CurrencyManager  // ← Added this parameter
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            List {
                ForEach(accounts) { account in
                    accountRow(for: account)
                }
            }
            .navigationTitle("Select Account")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
    }
    
    private func accountRow(for account: Account) -> some View {
        Button(action: {
            selectedAccountId = account.id
            dismiss()
        }) {
            HStack(spacing: 16) {
                accountIcon(for: account)
                accountDetails(for: account)
                Spacer()
                selectionIndicator(for: account)
            }
            .padding(.vertical, 4)
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private func accountIcon(for account: Account) -> some View {
        ZStack {
            Circle()
                .fill(colorForAccount(account.color).opacity(0.2))
                .frame(width: 40, height: 40)
            
            Image(systemName: account.icon)
                .font(.system(size: 18))
                .foregroundColor(colorForAccount(account.color))
        }
    }
    
    private func accountDetails(for account: Account) -> some View {
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
    }
    
    private func selectionIndicator(for account: Account) -> some View {
        Group {
            if selectedAccountId == account.id {
                Image(systemName: "checkmark.circle.fill")
                    .font(.title2)
                    .foregroundColor(.blue)
            }
        }
    }
}

// MARK: - Category Selection View

struct CategorySelectionView: View {
    let categories: [CustomCategory]
    @Binding var selectedCategory: CustomCategory?
    let colorForCategoryColor: (String) -> Color
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        List {
            ForEach(categories, id: \.id) { category in
                categoryRow(for: category)
            }
        }
        .navigationTitle("Select Category")
        .navigationBarTitleDisplayMode(.inline)
    }
    
    private func categoryRow(for category: CustomCategory) -> some View {
        Button(action: {
            selectedCategory = category
            dismiss()
        }) {
            HStack(spacing: 16) {
                categoryIcon(for: category)
                categoryDetails(for: category)
                Spacer()
                selectionIndicator(for: category)
            }
            .padding(.vertical, 4)
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private func categoryIcon(for category: CustomCategory) -> some View {
        ZStack {
            Circle()
                .fill(colorForCategoryColor(category.color).opacity(0.2))
                .frame(width: 40, height: 40)
            
            Image(systemName: category.icon)
                .font(.system(size: 18))
                .foregroundColor(colorForCategoryColor(category.color))
        }
    }
    
    private func categoryDetails(for category: CustomCategory) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(category.name)
                .font(.headline)
                .foregroundColor(.primary)
            
            Text(category.type.rawValue)
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
    
    private func selectionIndicator(for category: CustomCategory) -> some View {
        Group {
            if selectedCategory?.id == category.id {
                Image(systemName: "checkmark.circle.fill")
                    .font(.title2)
                    .foregroundColor(colorForCategoryColor(category.color))
            }
        }
    }
}

#Preview {
    QuickAddTransactionView(accountStore: AccountStore())
        .environmentObject(CurrencyManager())
}
