import SwiftUI

struct EditTransactionView: View {
    let transaction: Transaction
    let accountId: UUID
    @ObservedObject var accountStore: AccountStore
    @StateObject private var categoryStore = CategoryStore()
    @Environment(\.dismiss) private var dismiss
    
    @State private var amount: String
    @State private var payee: String
    @State private var notes: String
    @State private var selectedType: Transaction.TransactionType
    @State private var selectedCategory: CustomCategory?
    @State private var selectedDate: Date
    
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
    }
    
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
                if selectedType == .transfer {
                    // Transfer editing not allowed
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
                        .padding(.vertical)
                        .frame(maxWidth: .infinity)
                    }
                } else {
                    Section(header: Text("Transaction Details")) {
                        TextField("Amount", text: $amount)
                            .keyboardType(.decimalPad)
                        
                        TextField("Payee", text: $payee)
                            .textInputAutocapitalization(.words)
                        
                        DatePicker("Date", selection: $selectedDate, displayedComponents: .date)
                        
                        TextField("Notes (Optional)", text: $notes, axis: .vertical)
                            .lineLimit(3)
                    }
                    
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
                                Button(action: { selectedCategory = category }) {
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
            .navigationTitle("Edit Transaction")
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
                    .fontWeight(.semibold)
                    .disabled(!isFormValid || selectedType == .transfer)
                }
            }
        }
        .onAppear {
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
              selectedType != .transfer else { return }
        
        var updatedTransaction = transaction
        updatedTransaction.amount = transactionAmount
        updatedTransaction.payee = payee.trimmingCharacters(in: .whitespaces)
        updatedTransaction.date = selectedDate
        updatedTransaction.type = selectedType
        updatedTransaction.notes = "Category: \(category.name)" + (notes.trimmingCharacters(in: .whitespaces).isEmpty ? "" : " | \(notes.trimmingCharacters(in: .whitespaces))")
        
        accountStore.updateTransaction(updatedTransaction, in: accountId)
        dismiss()
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
}
