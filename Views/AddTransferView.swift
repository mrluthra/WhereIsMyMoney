import SwiftUI

struct AddTransferView: View {
    @ObservedObject var accountStore: AccountStore
    @EnvironmentObject var currencyManager: CurrencyManager  // ← Added this line
    @Environment(\.dismiss) private var dismiss
    
    @State private var amount = ""
    @State private var notes = ""
    @State private var selectedDate = Date()
    @State private var sourceAccountId: UUID?
    @State private var targetAccountId: UUID?
    
    private var availableSourceAccounts: [Account] {
        return accountStore.accounts
    }
    
    private var availableTargetAccounts: [Account] {
        return accountStore.accounts.filter { $0.id != sourceAccountId }
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
                transferDetailsSection
                sourceAccountSection
                targetAccountSection
                
                if isFormValid {
                    transferSummarySection
                }
            }
            .navigationTitle("Transfer Money")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Transfer") {
                        makeTransfer()
                    }
                    .fontWeight(.semibold)
                    .disabled(!isFormValid)
                }
            }
        }
        .onAppear {
            setupInitialAccount()
        }
    }
    
    // MARK: - Form Sections
    
    private var transferDetailsSection: some View {
        Section(header: Text("Transfer Details")) {
            TextField("Amount", text: $amount)
                .keyboardType(.decimalPad)
            
            DatePicker("Date", selection: $selectedDate, displayedComponents: .date)
            
            TextField("Notes (Optional)", text: $notes, axis: .vertical)
                .lineLimit(3)
        }
    }
    
    private var sourceAccountSection: some View {
        Section(header: Text("From Account")) {
            if availableSourceAccounts.isEmpty {
                Text("No accounts available")
                    .foregroundColor(.secondary)
            } else {
                ForEach(availableSourceAccounts) { account in
                    sourceAccountButton(for: account)
                }
            }
        }
    }
    
    private func sourceAccountButton(for account: Account) -> some View {
        Button(action: {
            sourceAccountId = account.id
            // Reset target if it's the same as source
            if targetAccountId == account.id {
                targetAccountId = nil
            }
        }) {
            AccountSelectionRow(
                account: account,
                isSelected: sourceAccountId == account.id,
                colorForAccount: colorForAccount,
                currencyManager: currencyManager
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private var targetAccountSection: some View {
        Section(header: Text("To Account")) {
            if sourceAccountId == nil {
                Text("Select source account first")
                    .foregroundColor(.secondary)
                    .italic()
            } else if availableTargetAccounts.isEmpty {
                Text("No other accounts available")
                    .foregroundColor(.secondary)
            } else {
                ForEach(availableTargetAccounts) { account in
                    targetAccountButton(for: account)
                }
            }
        }
    }
    
    private func targetAccountButton(for account: Account) -> some View {
        Button(action: { targetAccountId = account.id }) {
            AccountSelectionRow(
                account: account,
                isSelected: targetAccountId == account.id,
                colorForAccount: colorForAccount,
                currencyManager: currencyManager
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private var transferSummarySection: some View {
        Section(header: Text("Transfer Summary")) {
            VStack(spacing: 12) {
                transferVisualization
                Divider()
                transferAmountDisplay
            }
            .padding(.vertical, 8)
        }
    }
    
    private var transferVisualization: some View {
        HStack {
            sourceAccountDisplay
            
            Image(systemName: "arrow.right")
                .foregroundColor(.blue)
                .font(.title2)
            
            targetAccountDisplay
        }
        .frame(maxWidth: .infinity)
    }
    
    private var sourceAccountDisplay: some View {
        Group {
            if let sourceId = sourceAccountId,
               let sourceAccount = accountStore.getAccount(sourceId) {
                VStack {
                    Image(systemName: sourceAccount.icon)
                        .foregroundColor(colorForAccount(sourceAccount.color))
                    Text(sourceAccount.name)
                        .font(.caption)
                        .multilineTextAlignment(.center)
                }
            }
        }
    }
    
    private var targetAccountDisplay: some View {
        Group {
            if let targetId = targetAccountId,
               let targetAccount = accountStore.getAccount(targetId) {
                VStack {
                    Image(systemName: targetAccount.icon)
                        .foregroundColor(colorForAccount(targetAccount.color))
                    Text(targetAccount.name)
                        .font(.caption)
                        .multilineTextAlignment(.center)
                }
            }
        }
    }
    
    private var transferAmountDisplay: some View {
        HStack {
            Text("Transfer Amount:")
                .font(.headline)
            Spacer()
            Text(currencyManager.formatAmount(Double(amount) ?? 0))
                .font(.headline)
                .fontWeight(.semibold)
                .foregroundColor(.blue)
        }
    }
    
    // MARK: - Helper Methods
    
    private func setupInitialAccount() {
        // Set initial source account if only one account exists
        if availableSourceAccounts.count == 1 {
            sourceAccountId = availableSourceAccounts.first?.id
        }
    }
    
    private var isFormValid: Bool {
        !amount.isEmpty &&
        Double(amount) != nil &&
        (Double(amount) ?? 0) > 0 &&
        sourceAccountId != nil &&
        targetAccountId != nil &&
        sourceAccountId != targetAccountId
    }
    
    private func makeTransfer() {
        guard let transferAmount = Double(amount),
              let fromAccountId = sourceAccountId,
              let toAccountId = targetAccountId else { return }
        
        accountStore.addTransfer(
            amount: transferAmount,
            fromAccountId: fromAccountId,
            toAccountId: toAccountId,
            date: selectedDate,
            notes: notes.trimmingCharacters(in: .whitespaces).isEmpty ? nil : notes.trimmingCharacters(in: .whitespaces)
        )
        
        dismiss()
    }
}

// MARK: - Account Selection Row

struct AccountSelectionRow: View {
    let account: Account
    let isSelected: Bool
    let colorForAccount: (String) -> Color
    let currencyManager: CurrencyManager  // ← Added this parameter
    
    var body: some View {
        HStack(spacing: 16) {
            accountIcon
            accountInfo
            Spacer()
            selectionIndicator
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 4)
        .background(
            isSelected
            ? Color.blue.opacity(0.1)
            : Color.clear
        )
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
    
    private var accountIcon: some View {
        ZStack {
            Circle()
                .fill(colorForAccount(account.color).opacity(0.2))
                .frame(width: 40, height: 40)
            
            Image(systemName: account.icon)
                .font(.system(size: 18))
                .foregroundColor(colorForAccount(account.color))
        }
    }
    
    private var accountInfo: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(account.name)
                .font(.headline)
                .foregroundColor(.primary)
            
            accountDetails
        }
    }
    
    private var accountDetails: some View {
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
    
    private var selectionIndicator: some View {
        Group {
            if isSelected {
                Image(systemName: "checkmark.circle.fill")
                    .font(.title2)
                    .foregroundColor(.blue)
            } else {
                Image(systemName: "circle")
                    .font(.title2)
                    .foregroundColor(.secondary.opacity(0.3))
            }
        }
    }
}

#Preview {
    AddTransferView(accountStore: AccountStore())
        .environmentObject(CurrencyManager())  // ← Added this line
}
