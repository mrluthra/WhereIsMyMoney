import SwiftUI

struct QuickAddTransactionView: View {
    @ObservedObject var accountStore: AccountStore
    @StateObject private var categoryStore = CategoryStore()
    @StateObject private var smartEngine = SmartCategorizationEngine() // Add AI engine
    @StateObject private var payeeSuggestionEngine = PayeeSuggestionEngine() // Add payee suggestions
    @Environment(\.dismiss) private var dismiss
    
    @State private var amount = ""
    @State private var payee = ""
    @State private var notes = ""
    @State private var selectedType = Transaction.TransactionType.expense
    @State private var selectedCategory: CustomCategory?
    @State private var selectedDate = Date()
    @State private var selectedAccountId: UUID?
    @State private var showingAccountSelection = false
    @State private var aiSuggestedCategory: CustomCategory? // AI suggestion
    @State private var showingAISuggestion = false // Show AI banner
    @State private var payeeSuggestions: [PayeeSuggestionEngine.PayeeSuggestion] = [] // Payee suggestions
    @State private var showingPayeeSuggestions = false // Show payee dropdown
    
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
                // Account Selection Section
                Section(header: Text("Select Account")) {
                    if accountStore.accounts.isEmpty {
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
                    } else {
                        Button(action: { showingAccountSelection = true }) {
                            HStack(spacing: 16) {
                                if let account = selectedAccount {
                                    // Selected account display
                                    ZStack {
                                        Circle()
                                            .fill(colorForAccount(account.color).opacity(0.2))
                                            .frame(width: 40, height: 40)
                                        
                                        Image(systemName: account.icon)
                                            .font(.system(size: 18))
                                            .foregroundColor(colorForAccount(account.color))
                                    }
                                    
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
                                            
                                            Text("$\(account.currentBalance, specifier: "%.2f")")
                                                .font(.caption)
                                                .foregroundColor(account.currentBalance >= 0 ? .green : .red)
                                        }
                                    }
                                } else {
                                    // No account selected
                                    ZStack {
                                        Circle()
                                            .fill(Color.gray.opacity(0.2))
                                            .frame(width: 40, height: 40)
                                        
                                        Image(systemName: "plus")
                                            .font(.system(size: 18))
                                            .foregroundColor(.gray)
                                    }
                                    
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text("Select Account")
                                            .font(.headline)
                                            .foregroundColor(.primary)
                                        
                                        Text("Choose which account for this transaction")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }
                                }
                                
                                Spacer()
                                
                                Image(systemName: "chevron.right")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            .padding(.vertical, 8)
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                }
                
                if selectedAccountId != nil {
                    // Transaction Type Section
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
                            checkForAISuggestion() // Check AI suggestion when type changes
                        }
                    }
                    
                    Section(header: Text("Transaction Details")) {
                        HStack {
                            Text(selectedType == .expense ? "-$" : "+$")
                                .font(.headline)
                                .foregroundColor(colorForTransactionType(selectedType))
                            
                            TextField("Amount", text: $amount)
                                .keyboardType(.decimalPad)
                                .font(.headline)
                                .onChange(of: amount) { oldValue, newValue in
                                    checkForAISuggestion() // Check AI suggestion when amount changes
                                }
                        }
                        
                        VStack(spacing: 0) {
                            TextField("Payee/Description", text: $payee)
                                .textInputAutocapitalization(.words)
                                .onChange(of: payee) { oldValue, newValue in
                                    updatePayeeSuggestions(for: newValue)
                                    checkForAISuggestion() // Check AI suggestion when payee changes
                                }
                            
                            // Payee Suggestions Dropdown
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
                        
                        DatePicker("Date", selection: $selectedDate, displayedComponents: .date)
                        
                        TextField("Notes (Optional)", text: $notes, axis: .vertical)
                            .lineLimit(2...4)
                    }
                    
                    // NEW: AI Suggestion Banner
                    if showingAISuggestion, let suggested = aiSuggestedCategory {
                        Section {
                            HStack(spacing: 12) {
                                // AI Icon
                                ZStack {
                                    Circle()
                                        .fill(Color.blue.opacity(0.2))
                                        .frame(width: 35, height: 35)
                                    
                                    Image(systemName: "brain.head.profile")
                                        .font(.system(size: 16))
                                        .foregroundColor(.blue)
                                }
                                
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
                                
                                Spacer()
                                
                                // Accept/Dismiss buttons
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
                            .padding()
                            .background(Color.blue.opacity(0.05))
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                        }
                    }
                    
                    // Category Selection Section
                    Section(header: Text("Category")) {
                        if availableCategories.isEmpty {
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
                        } else {
                            // Quick category selection - show top 6 categories
                            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 3), spacing: 12) {
                                ForEach(Array(availableCategories.prefix(6)), id: \.id) { category in
                                    Button(action: {
                                        selectedCategory = category
                                        showingAISuggestion = false // Hide AI suggestion when manually selected
                                    }) {
                                        VStack(spacing: 8) {
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
                                            
                                            Text(category.name)
                                                .font(.caption)
                                                .fontWeight(.medium)
                                                .foregroundColor(selectedCategory?.id == category.id ? .primary : .secondary)
                                                .multilineTextAlignment(.center)
                                                .lineLimit(2)
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
                            }
                            .padding(.vertical, 8)
                            
                            // Show more categories if available
                            if availableCategories.count > 6 {
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
                        }
                    }
                    
                    // Preview Section
                    if isFormValid {
                        Section(header: Text("Preview")) {
                            HStack(spacing: 12) {
                                if let category = selectedCategory {
                                    Image(systemName: category.icon)
                                        .foregroundColor(colorForCategoryColor(category.color))
                                }
                                
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
                                
                                Spacer()
                                
                                Text("\(selectedType == .expense ? "-" : "+")$\(Double(amount) ?? 0, specifier: "%.2f")")
                                    .font(.headline)
                                    .fontWeight(.semibold)
                                    .foregroundColor(colorForTransactionType(selectedType))
                            }
                            .padding(.vertical, 4)
                        }
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
                colorForAccount: colorForAccount
            )
        }
        .onAppear {
            // Auto-select first account if only one exists
            if accountStore.accounts.count == 1 {
                selectedAccountId = accountStore.accounts.first?.id
            }
            
            // Set initial category
            selectedCategory = availableCategories.first
        }
    }
    
    // NEW: Payee Suggestion Logic
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
        
        // Auto-suggest category based on payee's history
        if let matchingCategory = availableCategories.first(where: {
            $0.name.lowercased() == suggestion.mostCommonCategory.lowercased()
        }) {
            selectedCategory = matchingCategory
            showingAISuggestion = false // Don't show AI suggestion if we have historical data
        }
        
        // Pre-fill amount if user has consistent spending with this payee
        if suggestion.averageAmount > 0 && amount.isEmpty {
            amount = String(format: "%.2f", suggestion.averageAmount)
        }
    }
    
    // NEW: AI Suggestion Logic
    private func checkForAISuggestion() {
        // Only suggest if we have enough information and no category selected yet
        guard !payee.isEmpty,
              payee.count > 2,
              selectedCategory == nil || showingAISuggestion else { return }
        
        let amountValue = Double(amount) ?? 0
        
        // Get AI suggestion
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
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            List {
                ForEach(accounts) { account in
                    Button(action: {
                        selectedAccountId = account.id
                        dismiss()
                    }) {
                        HStack(spacing: 16) {
                            ZStack {
                                Circle()
                                    .fill(colorForAccount(account.color).opacity(0.2))
                                    .frame(width: 40, height: 40)
                                
                                Image(systemName: account.icon)
                                    .font(.system(size: 18))
                                    .foregroundColor(colorForAccount(account.color))
                            }
                            
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
                                    
                                    Text("$\(account.currentBalance, specifier: "%.2f")")
                                        .font(.caption)
                                        .foregroundColor(account.currentBalance >= 0 ? .green : .red)
                                }
                            }
                            
                            Spacer()
                            
                            if selectedAccountId == account.id {
                                Image(systemName: "checkmark.circle.fill")
                                    .font(.title2)
                                    .foregroundColor(.blue)
                            }
                        }
                        .padding(.vertical, 4)
                    }
                    .buttonStyle(PlainButtonStyle())
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
                Button(action: {
                    selectedCategory = category
                    dismiss()
                }) {
                    HStack(spacing: 16) {
                        ZStack {
                            Circle()
                                .fill(colorForCategoryColor(category.color).opacity(0.2))
                                .frame(width: 40, height: 40)
                            
                            Image(systemName: category.icon)
                                .font(.system(size: 18))
                                .foregroundColor(colorForCategoryColor(category.color))
                        }
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text(category.name)
                                .font(.headline)
                                .foregroundColor(.primary)
                            
                            Text(category.type.rawValue)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                        
                        if selectedCategory?.id == category.id {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.title2)
                                .foregroundColor(colorForCategoryColor(category.color))
                        }
                    }
                    .padding(.vertical, 4)
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
        .navigationTitle("Select Category")
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    QuickAddTransactionView(accountStore: AccountStore())
}
