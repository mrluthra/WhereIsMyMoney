import SwiftUI

struct EditRecurringPaymentView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var recurringStore: RecurringPaymentStore
    @ObservedObject var accountStore: AccountStore
    @EnvironmentObject var currencyManager: CurrencyManager
    
    // ADD: CategoryStore to access custom categories
    @StateObject private var categoryStore = CategoryStore()
    
    let payment: RecurringPayment
    let account: Account
    
    @State private var paymentName: String
    @State private var amount: String
    @State private var payee: String
    @State private var selectedType: Transaction.TransactionType
    @State private var selectedFrequency: RecurringPayment.Frequency
    @State private var nextDueDate: Date
    @State private var notes: String
    @State private var selectedCategory: String
    @State private var selectedCategoryIcon: String
    @State private var isActive: Bool
    
    // UPDATED: Use custom categories instead of default enum
    private var availableCategories: [CustomCategory] {
        switch selectedType {
        case .income:
            return categoryStore.categoriesForType(.income)
        case .expense:
            return categoryStore.categoriesForType(.expense)
        case .transfer:
            return [] // No categories for transfers
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
    
    private var isValidForm: Bool {
        !paymentName.trimmingCharacters(in: .whitespaces).isEmpty &&
        !payee.trimmingCharacters(in: .whitespaces).isEmpty &&
        (Double(amount) ?? 0) > 0
    }
    
    init(payment: RecurringPayment, account: Account, recurringStore: RecurringPaymentStore, accountStore: AccountStore) {
        self.payment = payment
        self.account = account
        self.recurringStore = recurringStore
        self.accountStore = accountStore
        
        // Initialize state with current payment values
        _paymentName = State(initialValue: payment.name)
        _amount = State(initialValue: String(payment.amount))
        _payee = State(initialValue: payment.payee)
        _selectedType = State(initialValue: payment.type)
        _selectedFrequency = State(initialValue: payment.frequency)
        _nextDueDate = State(initialValue: payment.nextDueDate)
        _notes = State(initialValue: payment.notes ?? "")
        _selectedCategory = State(initialValue: payment.category)
        _selectedCategoryIcon = State(initialValue: payment.categoryIcon)
        _isActive = State(initialValue: payment.isActive)
    }
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Payment Details")) {
                    TextField("Payment Name", text: $paymentName)
                    
                    TextField("Payee", text: $payee)
                    
                    HStack {
                        Text(selectedType == .expense ? "-\(currencyManager.currencySymbol)" : "+\(currencyManager.currencySymbol)")
                            .font(.headline)
                            .foregroundColor(colorForTransactionType(selectedType))
                        
                        TextField("Amount", text: $amount)
                            .keyboardType(.decimalPad)
                            .font(.headline)
                    }
                    
                    Picker("Type", selection: $selectedType) {
                        ForEach([Transaction.TransactionType.income, Transaction.TransactionType.expense], id: \.self) { type in
                            Label(type.rawValue, systemImage: type.systemImage)
                                .tag(type)
                        }
                    }
                    .pickerStyle(.segmented)
                    .onChange(of: selectedType) { oldValue, newValue in
                        // Reset category when type changes
                        if let firstCategory = availableCategories.first {
                            selectedCategory = firstCategory.name
                            selectedCategoryIcon = firstCategory.icon
                        }
                    }
                }
                
                Section(header: Text("Schedule")) {
                    Picker("Frequency", selection: $selectedFrequency) {
                        ForEach(RecurringPayment.Frequency.allCases, id: \.self) { frequency in
                            Label(frequency.rawValue, systemImage: frequency.systemImage)
                                .tag(frequency)
                        }
                    }
                    
                    DatePicker("Next Due Date", selection: $nextDueDate, displayedComponents: .date)
                    
                    TextField("Notes (Optional)", text: $notes, axis: .vertical)
                        .lineLimit(3)
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
                            
                            Text("Categories will be available once you select a transaction type")
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                        }
                        .padding(.vertical)
                    } else {
                        // UPDATED: Show custom categories with icons and colors
                        Picker("Category", selection: $selectedCategory) {
                            ForEach(availableCategories, id: \.id) { category in
                                HStack {
                                    Image(systemName: category.icon)
                                        .foregroundColor(colorForCategoryColor(category.color))
                                    Text(category.name)
                                }
                                .tag(category.name)
                            }
                        }
                        .onChange(of: selectedCategory) { oldValue, newValue in
                            // Update icon when category changes
                            if let category = availableCategories.first(where: { $0.name == newValue }) {
                                selectedCategoryIcon = category.icon
                            }
                        }
                        
                        // Show selected category preview
                        if let selectedCat = availableCategories.first(where: { $0.name == selectedCategory }) {
                            HStack {
                                Image(systemName: selectedCat.icon)
                                    .foregroundColor(colorForCategoryColor(selectedCat.color))
                                Text("Selected: \(selectedCat.name)")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            .padding(.vertical, 4)
                        }
                    }
                }
                
                Section(header: Text("Status")) {
                    Toggle("Active", isOn: $isActive)
                        .toggleStyle(SwitchToggleStyle(tint: .green))
                    
                    if !isActive {
                        Text("Inactive payments will not generate transactions")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                if payment.lastProcessedDate != nil {
                    Section(header: Text("Payment History")) {
                        HStack {
                            Image(systemName: "clock")
                                .foregroundColor(.secondary)
                            Text("Last Processed")
                            Spacer()
                            Text(payment.lastProcessedDate?.formatted(date: .abbreviated, time: .shortened) ?? "Never")
                                .foregroundColor(.secondary)
                        }
                    }
                }
            }
            .navigationTitle("Edit Payment")
            .navigationBarTitleDisplayMode(.inline)
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
                    .disabled(!isValidForm)
                }
            }
        }
        .onAppear {
            // Ensure category is properly set on appear
            if !availableCategories.isEmpty && !availableCategories.contains(where: { $0.name == selectedCategory }) {
                if let firstCategory = availableCategories.first {
                    selectedCategory = firstCategory.name
                    selectedCategoryIcon = firstCategory.icon
                }
            }
        }
    }
    
    private func saveChanges() {
        guard let paymentAmount = Double(amount) else { return }
        
        var updatedPayment = payment
        updatedPayment.name = paymentName.trimmingCharacters(in: .whitespaces)
        updatedPayment.amount = paymentAmount
        updatedPayment.payee = payee.trimmingCharacters(in: .whitespaces)
        updatedPayment.type = selectedType
        updatedPayment.frequency = selectedFrequency
        updatedPayment.nextDueDate = nextDueDate
        updatedPayment.notes = notes.trimmingCharacters(in: .whitespaces).isEmpty ? nil : notes.trimmingCharacters(in: .whitespaces)
        updatedPayment.category = selectedCategory
        updatedPayment.categoryIcon = selectedCategoryIcon
        updatedPayment.isActive = isActive
        
        recurringStore.updateRecurringPayment(updatedPayment)
        dismiss()
    }
}

#Preview {
    EditRecurringPaymentView(
        payment: RecurringPayment(
            name: "Netflix Subscription",
            amount: 15.99,
            category: "Entertainment",
            categoryIcon: "tv.fill",
            accountId: UUID(),
            frequency: .monthly,
            nextDueDate: Date(),
            payee: "Netflix",
            type: .expense,
            notes: "Monthly streaming"
        ),
        account: Account(
            name: "Chase Checking",
            startingBalance: 1500.00,
            icon: "creditcard",
            color: "Blue",
            accountType: .debit
        ),
        recurringStore: RecurringPaymentStore(),
        accountStore: AccountStore()
    )
    .environmentObject(CurrencyManager())
}
