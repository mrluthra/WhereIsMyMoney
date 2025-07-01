import SwiftUI

struct AddAccountView: View {
    @ObservedObject var accountStore: AccountStore
    @Environment(\.dismiss) private var dismiss
    
    @State private var accountName = ""
    @State private var startingBalance = ""
    @State private var selectedAccountType = Account.AccountType.debit
    @State private var selectedColor = "Blue"
    @State private var selectedIcon = "creditcard"
    @EnvironmentObject var currencyManager: CurrencyManager
    
    private let availableColors = ["Blue", "Green", "Purple", "Orange", "Red", "Yellow"]
    private let availableIcons = ["creditcard", "banknote", "wallet.pass", "building.columns", "dollarsign.circle", "chart.line.uptrend.xyaxis"]
    
    private func colorForName(_ colorName: String) -> Color {
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
                Section(header: Text("Account Details")) {
                    TextField("Account Name", text: $accountName)
                        .textInputAutocapitalization(.words)
                    
                    VStack(alignment: .leading, spacing: 8) {
                        if selectedAccountType == .credit {
                            Text("Starting Debt Amount")
                                .font(.subheadline)
                                .foregroundColor(.primary)
                            TextField("Amount you owe", text: $startingBalance)
                                .keyboardType(.decimalPad)
                            Text("This will be stored as debt (negative balance)")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        } else {
                            Text("Starting Balance")
                                .font(.subheadline)
                                .foregroundColor(.primary)
                            TextField("Current account balance", text: $startingBalance)
                                .keyboardType(.decimalPad)
                        }
                    }
                    
                    Picker("Account Type", selection: $selectedAccountType) {
                        ForEach(Account.AccountType.allCases, id: \.self) { type in
                            Label(type.rawValue, systemImage: type.systemImage)
                                .tag(type)
                        }
                    }
                    .pickerStyle(.segmented)
                }
                
                Section(header: Text("Appearance")) {
                    // Color Selection
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Color")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        
                        LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 6), spacing: 12) {
                            ForEach(availableColors, id: \.self) { color in
                                Button(action: { selectedColor = color }) {
                                    Circle()
                                        .fill(colorForName(color))
                                        .frame(width: 40, height: 40)
                                        .overlay(
                                            Circle()
                                                .stroke(selectedColor == color ? Color.primary : Color.clear, lineWidth: 2)
                                        )
                                        .scaleEffect(selectedColor == color ? 1.1 : 1.0)
                                        .animation(.easeInOut(duration: 0.2), value: selectedColor)
                                }
                                .buttonStyle(PlainButtonStyle())
                            }
                        }
                    }
                    .padding(.vertical, 8)
                    
                    // Icon Selection
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Icon")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        
                        LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 6), spacing: 12) {
                            ForEach(availableIcons, id: \.self) { icon in
                                Button(action: { selectedIcon = icon }) {
                                    ZStack {
                                        Circle()
                                            .fill(selectedIcon == icon ? colorForName(selectedColor).opacity(0.2) : Color.secondary.opacity(0.1))
                                            .frame(width: 40, height: 40)
                                        
                                        Image(systemName: icon)
                                            .font(.title3)
                                            .foregroundColor(selectedIcon == icon ? colorForName(selectedColor) : .secondary)
                                    }
                                    .scaleEffect(selectedIcon == icon ? 1.1 : 1.0)
                                    .animation(.easeInOut(duration: 0.2), value: selectedIcon)
                                }
                                .buttonStyle(PlainButtonStyle())
                            }
                        }
                    }
                    .padding(.vertical, 8)
                }
                
                Section(header: Text("Preview")) {
                    if !accountName.isEmpty {
                        let previewBalance = Double(startingBalance) ?? 0.0
                        
                        VStack(spacing: 12) {
                            AccountCardView(account: Account(
                                name: accountName,
                                startingBalance: previewBalance,
                                icon: selectedIcon,
                                color: selectedColor,
                                accountType: selectedAccountType
                            ))
                            .disabled(true)
                            
                            // Explanation for credit cards
                            if selectedAccountType == .credit && previewBalance > 0 {
                                VStack(spacing: 4) {
                                    Text("💳 Credit Card Explanation")
                                        .font(.caption)
                                        .fontWeight(.semibold)
                                        .foregroundColor(.orange)
                                    
                                    //Text("$\(previewBalance, specifier: "%.2f") debt will show as what you owe")
                                    Text("\(currencyManager.formatAmount(previewBalance)) debt will show as what you owe")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                        .multilineTextAlignment(.center)
                                }
                                .padding(8)
                                .background(Color.orange.opacity(0.1))
                                .clipShape(RoundedRectangle(cornerRadius: 8))
                            }
                        }
                    }
                }
            }
            .navigationTitle("Add Account")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        saveAccount()
                    }
                    .fontWeight(.semibold)
                    .disabled(!isFormValid)
                }
            }
        }
    }
    
    private var isFormValid: Bool {
        !accountName.trimmingCharacters(in: .whitespaces).isEmpty &&
        !startingBalance.isEmpty &&
        Double(startingBalance) != nil
    }
    
    private func saveAccount() {
        guard let balance = Double(startingBalance) else { return }
        
        let newAccount = Account(
            name: accountName.trimmingCharacters(in: .whitespaces),
            startingBalance: balance,
            icon: selectedIcon,
            color: selectedColor,
            accountType: selectedAccountType
        )
        
        accountStore.addAccount(newAccount)
        dismiss()
    }
}

#Preview {
    AddAccountView(accountStore: AccountStore())
}
