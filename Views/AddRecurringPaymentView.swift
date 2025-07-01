import SwiftUI

struct AddRecurringPaymentView: View {
    let account: Account
    @ObservedObject var recurringStore: RecurringPaymentStore
    @ObservedObject var accountStore: AccountStore
    @StateObject private var categoryStore = CategoryStore()
    @StateObject private var currencyManager = CurrencyManager()
    
    @Environment(\.dismiss) private var dismiss
    
    @State private var paymentName = ""
    @State private var amount = ""
    @State private var payee = ""
    @State private var notes = ""
    @State private var selectedType = Transaction.TransactionType.expense
    @State private var selectedCategory = "Bills & Utilities"
    @State private var selectedCategoryIcon = "doc.text.fill"
    @State private var selectedCategoryColor = "Blue" // Add this for color tracking
    @State private var selectedFrequency = RecurringPayment.Frequency.monthly
    @State private var startDate = Date()
    
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
                Section(header: Text("Payment Details")) {
                    TextField("Payment Name", text: $paymentName)
                        .textInputAutocapitalization(.words)
                    
                    TextField("Payee/Company", text: $payee)
                        .textInputAutocapitalization(.words)
                    
                    HStack {
                        //Text(selectedType == .expense ? "-$" : "+$")
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
                            selectedCategoryColor = firstCategory.color
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
                    
                    DatePicker("Start Date", selection: $startDate, displayedComponents: .date)
                    
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
                            
                            Text("Add some categories first in Manage Categories")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 20)
                    } else {
                        LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 12) {
                            ForEach(availableCategories, id: \.id) { category in
                                Button(action: {
                                    selectedCategory = category.name
                                    selectedCategoryIcon = category.icon
                                    selectedCategoryColor = category.color
                                }) {
                                    VStack(spacing: 8) {
                                        ZStack {
                                            Circle()
                                                .fill(selectedCategory == category.name ?
                                                      colorForCategoryColor(category.color) :
                                                      colorForCategoryColor(category.color).opacity(0.2))
                                                .frame(width: 40, height: 40)
                                            
                                            Image(systemName: category.icon)
                                                .font(.title3)
                                                .foregroundColor(selectedCategory == category.name ?
                                                               .white :
                                                               colorForCategoryColor(category.color))
                                        }
                                        
                                        Text(category.name)
                                            .font(.caption)
                                            .fontWeight(.medium)
                                            .foregroundColor(selectedCategory == category.name ? .primary : .secondary)
                                            .multilineTextAlignment(.center)
                                            .lineLimit(2)
                                    }
                                    .frame(height: 80)
                                    .frame(maxWidth: .infinity)
                                    .background(
                                        selectedCategory == category.name
                                        ? colorForCategoryColor(category.color).opacity(0.1)
                                        : Color.clear
                                    )
                                    .clipShape(RoundedRectangle(cornerRadius: 12))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 12)
                                            .stroke(selectedCategory == category.name ?
                                                   colorForCategoryColor(category.color) :
                                                   Color.clear, lineWidth: 2)
                                    )
                                }
                                .buttonStyle(PlainButtonStyle())
                            }
                        }
                        .padding(.vertical, 8)
                    }
                }
                
                if isFormValid {
                    Section(header: Text("Preview")) {
                        VStack(spacing: 12) {
                            HStack(spacing: 12) {
                                Image(systemName: selectedCategoryIcon)
                                    .foregroundColor(colorForCategoryColor(selectedCategoryColor))
                                
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(paymentName)
                                        .font(.headline)
                                    Text("\(payee) • \(selectedFrequency.rawValue)")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                                
                                Spacer()
                                
                               //Text("\(selectedType == .expense ? "-" : "+")$\(Double(amount) ?? 0, specifier: "%.2f")")
                                Text("\(selectedType == .expense ? "-" : "+")\(currencyManager.formatAmount(Double(amount) ?? 0))")
                                    .font(.headline)
                                    .fontWeight(.semibold)
                                    .foregroundColor(colorForTransactionType(selectedType))
                            }
                            
                            HStack {
                                Text("Next payment:")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                Spacer()
                                Text("\(startDate, formatter: dateFormatter)")
                                    .font(.caption)
                                    .fontWeight(.medium)
                            }
                        }
                        .padding(.vertical, 4)
                    }
                }
            }
            .navigationTitle("Add Recurring Payment")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        saveRecurringPayment()
                    }
                    .fontWeight(.semibold)
                    .disabled(!isFormValid)
                }
            }
        }
        .onAppear {
            // Set initial category when view appears
            if let firstCategory = availableCategories.first {
                selectedCategory = firstCategory.name
                selectedCategoryIcon = firstCategory.icon
                selectedCategoryColor = firstCategory.color
            }
        }
    }
    
    private var isFormValid: Bool {
        !paymentName.trimmingCharacters(in: .whitespaces).isEmpty &&
        !amount.isEmpty &&
        !payee.trimmingCharacters(in: .whitespaces).isEmpty &&
        Double(amount) != nil &&
        (Double(amount) ?? 0) > 0
    }
    
    private var dateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter
    }
    
    private func saveRecurringPayment() {
        guard let paymentAmount = Double(amount) else { return }
        
        let newPayment = RecurringPayment(
            name: paymentName.trimmingCharacters(in: .whitespaces),
            amount: paymentAmount,
            category: selectedCategory,
            categoryIcon: selectedCategoryIcon,
            accountId: account.id,
            frequency: selectedFrequency,
            nextDueDate: startDate,
            payee: payee.trimmingCharacters(in: .whitespaces),
            type: selectedType,
            notes: notes.trimmingCharacters(in: .whitespaces).isEmpty ? nil : notes.trimmingCharacters(in: .whitespaces)
        )
        
        recurringStore.addRecurringPayment(newPayment)
        dismiss()
    }
}

#Preview {
    AddRecurringPaymentView(
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
}
