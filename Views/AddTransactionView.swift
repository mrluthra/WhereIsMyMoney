import SwiftUI

struct AddTransactionView: View {
    let accountId: UUID
    @ObservedObject var accountStore: AccountStore
    
    // MARK: - Add Currency Manager
    @EnvironmentObject var currencyManager: CurrencyManager
    @StateObject private var categoryStore = CategoryStore()
    @StateObject private var smartEngine = SmartCategorizationEngine()
    @StateObject private var payeeSuggestionEngine = PayeeSuggestionEngine()
    @Environment(\.dismiss) private var dismiss
    
    @State private var amount = ""
    @State private var payee = ""
    @State private var notes = ""
    @State private var selectedType = Transaction.TransactionType.expense
    @State private var selectedCategory: CustomCategory?
    @State private var selectedDate = Date()
    @State private var showingTransferView = false
    @State private var aiSuggestedCategory: CustomCategory?
    @State private var showingAISuggestion = false
    @State private var payeeSuggestions: [PayeeSuggestionEngine.PayeeSuggestion] = []
    @State private var showingPayeeSuggestions = false
    
    private var availableCategories: [CustomCategory] {
        categoryStore.categoriesForType(selectedType == .income ? .income : .expense)
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
                transactionTypeSection
                
                if selectedType == .transfer {
                    transferSection
                } else {
                    detailsSection
                    
                    if showingAISuggestion, let suggested = aiSuggestedCategory {
                        aiSuggestionSection(suggested: suggested)
                    }
                    
                    categorySection
                    
                    if isFormValid {
                        previewSection
                    }
                }
            }
            .navigationTitle("Add Transaction")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        if selectedType == .transfer {
                            dismiss()
                        } else {
                            saveTransaction()
                        }
                    }
                    .fontWeight(.semibold)
                    .disabled(!isFormValid)
                }
            }
        }
        .onAppear {
            selectedCategory = availableCategories.first
        }
        .sheet(isPresented: $showingTransferView) {
            AddTransferView(accountStore: accountStore)
        }
    }
    
    // MARK: - Form Sections
    
    private var transactionTypeSection: some View {
        Section(header: Text("Transaction Type")) {
            Picker("Type", selection: $selectedType) {
                ForEach(Transaction.TransactionType.allCases, id: \.self) { type in
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
    
    private var transferSection: some View {
        Section {
            VStack(spacing: 16) {
                transferIcon
                transferTitle
                transferDescription
                transferButton
            }
            .padding(.vertical)
            .frame(maxWidth: .infinity)
        }
    }
    
    private var transferIcon: some View {
        Image(systemName: "arrow.left.arrow.right.circle.fill")
            .font(.system(size: 50))
            .foregroundColor(.blue)
    }
    
    private var transferTitle: some View {
        Text("Account to Account Transfer")
            .font(.headline)
            .multilineTextAlignment(.center)
    }
    
    private var transferDescription: some View {
        Text("Use the dedicated transfer interface for moving money between accounts with proper tracking.")
            .font(.subheadline)
            .foregroundColor(.secondary)
            .multilineTextAlignment(.center)
    }
    
    private var transferButton: some View {
        Button(action: {
            dismiss()
            showingTransferView = true
        }) {
            Label("Open Transfer Interface", systemImage: "arrow.left.arrow.right.circle.fill")
                .font(.headline)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.blue)
                .clipShape(RoundedRectangle(cornerRadius: 12))
        }
    }
    
    private var detailsSection: some View {
        Section(header: Text("Details")) {
            amountField
            payeeFieldWithSuggestions
            DatePicker("Date", selection: $selectedDate, displayedComponents: .date)
            notesField
        }
    }
    
    private var amountField: some View {
        HStack {
            amountPrefix
            TextField("Amount", text: $amount)
                .keyboardType(.decimalPad)
                .font(.headline)
                .onChange(of: amount) { oldValue, newValue in
                    checkForAISuggestion()
                }
        }
    }
    
    private var amountPrefix: some View {
        Text(selectedType == .expense ? "-\(currencyManager.currencySymbol)" : "+\(currencyManager.currencySymbol)")
            .font(.headline)
            .foregroundColor(colorForTransactionType(selectedType))
    }
    
    private var payeeFieldWithSuggestions: some View {
        VStack(spacing: 0) {
            payeeField
            
            if showingPayeeSuggestions && !payeeSuggestions.isEmpty {
                payeeSuggestionsView
            }
        }
    }
    
    private var payeeField: some View {
        TextField("Payee", text: $payee)
            .textInputAutocapitalization(.words)
            .onChange(of: payee) { oldValue, newValue in
                updatePayeeSuggestions(for: newValue)
                checkForAISuggestion()
            }
    }
    
    private var payeeSuggestionsView: some View {
        PayeeSuggestionView(
            suggestions: payeeSuggestions,
            onSelect: { suggestion in
                selectPayeeSuggestion(suggestion)
            }
        )
        .padding(.top, 8)
    }
    
    private var notesField: some View {
        TextField("Notes (Optional)", text: $notes, axis: .vertical)
            .lineLimit(3)
    }
    
    private func aiSuggestionSection(suggested: CustomCategory) -> some View {
        Section {
            HStack(spacing: 12) {
                aiIcon
                aiContent(suggested: suggested)
                Spacer()
                aiButtons(suggested: suggested)
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
    
    private func aiContent(suggested: CustomCategory) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            aiHeader
            aiDescription(suggested: suggested)
        }
    }
    
    private var aiHeader: some View {
        HStack {
            Text("AI Suggestion")
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundColor(.blue)
            
            Image(systemName: "sparkles")
                .font(.caption)
                .foregroundColor(.blue)
        }
    }
    
    private func aiDescription(suggested: CustomCategory) -> some View {
        Text("Suggested category: \(suggested.name)")
            .font(.caption)
            .foregroundColor(.secondary)
    }
    
    private func aiButtons(suggested: CustomCategory) -> some View {
        HStack(spacing: 8) {
            useButton(suggested: suggested)
            dismissButton
        }
    }
    
    private func useButton(suggested: CustomCategory) -> some View {
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
    }
    
    private var dismissButton: some View {
        Button("Dismiss") {
            showingAISuggestion = false
        }
        .font(.caption)
        .foregroundColor(.secondary)
    }
    
    private var categorySection: some View {
        Section(header: Text("Category")) {
            if availableCategories.isEmpty {
                noCategoriesView
            } else {
                categoryList
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
            
            Text("Add some categories first in Manage Categories")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 20)
    }
    
    private var categoryList: some View {
        ForEach(availableCategories, id: \.id) { category in
            categoryRow(for: category)
        }
    }
    
    private func categoryRow(for category: CustomCategory) -> some View {
        Button(action: {
            selectedCategory = category
            showingAISuggestion = false
        }) {
            HStack(spacing: 16) {
                categoryIcon(for: category)
                categoryInfo(for: category)
                Spacer()
                selectionIndicator(for: category)
            }
            .padding(.vertical, 8)
            .padding(.horizontal, 4)
            .background(backgroundFor(category: category))
            .clipShape(RoundedRectangle(cornerRadius: 12))
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
    
    private func categoryInfo(for category: CustomCategory) -> some View {
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
            } else {
                Image(systemName: "circle")
                    .font(.title2)
                    .foregroundColor(.secondary.opacity(0.3))
            }
        }
    }
    
    private func backgroundFor(category: CustomCategory) -> Color {
        selectedCategory?.id == category.id
        ? colorForCategoryColor(category.color).opacity(0.1)
        : Color.clear
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
        }
    }
    
    private var previewAmount: some View {
        Text("\(selectedType == .expense ? "-" : "+")\(currencyManager.formatAmount(Double(amount) ?? 0))")
            .font(.headline)
            .fontWeight(.semibold)
            .foregroundColor(colorForTransactionType(selectedType))
    }
    
    // MARK: - Helper Methods
    
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
        if selectedType == .transfer {
            return false
        }
        
        return !amount.isEmpty &&
        !payee.trimmingCharacters(in: .whitespaces).isEmpty &&
        Double(amount) != nil &&
        (Double(amount) ?? 0) > 0 &&
        selectedCategory != nil
    }
    
    private func saveTransaction() {
        guard let transactionAmount = Double(amount),
              let category = selectedCategory,
              selectedType != .transfer else { return }
        
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

#Preview {
    AddTransactionView(accountId: UUID(), accountStore: AccountStore())
        .environmentObject(CurrencyManager())
}
