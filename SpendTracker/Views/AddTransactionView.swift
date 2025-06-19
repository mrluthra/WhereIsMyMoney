import SwiftUI

struct AddTransactionView: View {
    let accountId: UUID
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
    @State private var showingTransferView = false
    @State private var aiSuggestedCategory: CustomCategory? // AI suggestion
    @State private var showingAISuggestion = false // Show AI banner
    @State private var payeeSuggestions: [PayeeSuggestionEngine.PayeeSuggestion] = [] // Payee suggestions
    @State private var showingPayeeSuggestions = false // Show payee dropdown
    
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
                Section(header: Text("Transaction Type")) {
                    Picker("Type", selection: $selectedType) {
                        ForEach(Transaction.TransactionType.allCases, id: \.self) { type in
                            Label(type.rawValue, systemImage: type.systemImage)
                                .tag(type)
                        }
                    }
                    .pickerStyle(.segmented)
                    .onChange(of: selectedType) { oldValue, newValue in
                        // Reset category when type changes
                        selectedCategory = availableCategories.first
                        checkForAISuggestion() // Check AI suggestion when type changes
                    }
                }
                
                if selectedType == .transfer {
                    // Transfer-specific UI
                    Section {
                        VStack(spacing: 16) {
                            Image(systemName: "arrow.left.arrow.right.circle.fill")
                                .font(.system(size: 50))
                                .foregroundColor(.blue)
                            
                            Text("Account to Account Transfer")
                                .font(.headline)
                                .multilineTextAlignment(.center)
                            
                            Text("Use the dedicated transfer interface for moving money between accounts with proper tracking.")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                            
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
                        .padding(.vertical)
                        .frame(maxWidth: .infinity)
                    }
                } else {
                    // Regular transaction UI
                    Section(header: Text("Details")) {
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
                        
                        // FIXED: Payee field with suggestions
                        VStack(spacing: 0) {
                            TextField("Payee", text: $payee)
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
                            .lineLimit(3)
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
                    
                    Section(header: Text("Category")) {
                        if availableCategories.isEmpty {
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
                        } else {
                            ForEach(availableCategories, id: \.id) { category in
                                Button(action: {
                                    selectedCategory = category
                                    showingAISuggestion = false // Hide AI suggestion when manually selected
                                }) {
                                    HStack(spacing: 16) {
                                        // Category Icon
                                        ZStack {
                                            Circle()
                                                .fill(colorForCategoryColor(category.color).opacity(0.2))
                                                .frame(width: 40, height: 40)
                                            
                                            Image(systemName: category.icon)
                                                .font(.system(size: 18))
                                                .foregroundColor(colorForCategoryColor(category.color))
                                        }
                                        
                                        // Category Info
                                        VStack(alignment: .leading, spacing: 2) {
                                            Text(category.name)
                                                .font(.headline)
                                                .foregroundColor(.primary)
                                            
                                            Text(category.type.rawValue)
                                                .font(.caption)
                                                .foregroundColor(.secondary)
                                        }
                                        
                                        Spacer()
                                        
                                        // Selection Indicator
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
                                    .padding(.vertical, 8)
                                    .padding(.horizontal, 4)
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
                    }
                    
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
                            // This shouldn't happen since we handle transfers differently
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
            // Set initial category when view appears
            selectedCategory = availableCategories.first
        }
        .sheet(isPresented: $showingTransferView) {
            AddTransferView(accountStore: accountStore)
        }
    }
    
    // MARK: - NEW: Payee Suggestion Logic
    
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
        if selectedType == .transfer {
            return false // Transfers are handled separately
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
            category: TransactionCategory.other, // We'll keep using the enum for now, but store the name in notes
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
}
