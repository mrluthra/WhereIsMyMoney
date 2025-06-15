import SwiftUI

struct AddRecurringPaymentView: View {
    let account: Account
    @ObservedObject var recurringStore: RecurringPaymentStore
    @ObservedObject var accountStore: AccountStore
    @StateObject private var categoryStore = CategoryStore()
    @Environment(\.dismiss) private var dismiss
    
    @State private var paymentName = ""
    @State private var amount = ""
    @State private var payee = ""
    @State private var notes = ""
    @State private var selectedType = Transaction.TransactionType.expense
    @State private var selectedCategory = "Bills & Utilities"
    @State private var selectedCategoryIcon = "doc.text.fill"
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
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Category & Schedule")) {
                    // Category Selection
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Category")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        
                        LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 12) {
                            ForEach(availableCategories, id: \.id) { category in
                                Button(action: {
                                    selectedCategory = category.name
                                    selectedCategoryIcon = category.icon
                                }) {
                                    VStack(spacing: 8) {
                                        Image(systemName: category.icon)
                                            .font(.title3)
                                            .foregroundColor(selectedCategory == category.name ? .white : colorForTransactionType(selectedType))
                                        
                                        Text(category.name)
                                            .font(.caption)
                                            .fontWeight(.medium)
                                            .foregroundColor(selectedCategory == category.name ? .white : .primary)
                                            .multilineTextAlignment(.center)
                                            .lineLimit(2)
                                    }
                                    .frame(height: 60)
                                    .frame(maxWidth: .infinity)
                                    .background(
                                        selectedCategory == category.name
                                        ? colorForTransactionType(selectedType)
                                        : colorForTransactionType(selectedType).opacity(0.1)
                                    )
                                    .clipShape(RoundedRectangle(cornerRadius: 12))
                                }
                                .buttonStyle(PlainButtonStyle())
                            }
                        }
                    }
                    .padding(.vertical, 8)
                    
                    // Frequency Selection
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
                
                if isFormValid {
                    Section(header: Text("Preview")) {
                        VStack(spacing: 12) {
                            HStack(spacing: 12) {
                                Image(systemName: selectedCategoryIcon)
                                    .foregroundColor(colorForTransactionType(selectedType))
                                
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(paymentName)
                                        .font(.headline)
                                    Text("\(payee) • \(selectedFrequency.rawValue)")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                                
                                Spacer()
                                
                                Text("\(selectedType == .expense ? "-" : "+")$\(Double(amount) ?? 0, specifier: "%.2f")")
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
            // Set initial category
            if let firstCategory = availableCategories.first {
                selectedCategory = firstCategory.name
                selectedCategoryIcon = firstCategory.icon
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
