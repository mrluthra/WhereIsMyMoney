import SwiftUI

struct EditAccountView: View {
    let account: Account
    @ObservedObject var accountStore: AccountStore
    @Environment(\.dismiss) private var dismiss
    
    @State private var accountName: String
    @State private var selectedColor: String
    @State private var selectedIcon: String
    
    private let availableColors = ["Blue", "Green", "Purple", "Orange", "Red", "Yellow"]
    private let availableIcons = ["creditcard", "banknote", "wallet.pass", "building.columns", "dollarsign.circle", "chart.line.uptrend.xyaxis"]
    
    init(account: Account, accountStore: AccountStore) {
        self.account = account
        self.accountStore = accountStore
        self._accountName = State(initialValue: account.name)
        self._selectedColor = State(initialValue: account.color)
        self._selectedIcon = State(initialValue: account.icon)
    }
    
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
    
    private var previewAccount: Account {
        var updatedAccount = account
        updatedAccount.name = accountName
        updatedAccount.color = selectedColor
        updatedAccount.icon = selectedIcon
        return updatedAccount
    }
    
    var body: some View {
        NavigationView {
            Form {
                accountDetailsSection
                appearanceSection
                previewSection
            }
            .navigationTitle("Edit Account")
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
                    .disabled(!isFormValid)
                }
            }
        }
    }
    
    private var accountDetailsSection: some View {
        Section(header: Text("Account Details")) {
            TextField("Account Name", text: $accountName)
                .textInputAutocapitalization(.words)
            
            accountTypeRow
            balanceRow
        }
    }
    
    private var accountTypeRow: some View {
        HStack {
            Text("Account Type")
            Spacer()
            Text(account.accountType.rawValue)
                .foregroundColor(.secondary)
        }
    }
    
    private var balanceRow: some View {
        Group {
            if account.accountType == .credit {
                HStack {
                    Text("Starting Debt")
                    Spacer()
                    Text("$\(abs(account.startingBalance), specifier: "%.2f")")
                        .foregroundColor(.secondary)
                }
            } else {
                HStack {
                    Text("Starting Balance")
                    Spacer()
                    Text("$\(account.startingBalance, specifier: "%.2f")")
                        .foregroundColor(.secondary)
                }
            }
        }
    }
    
    private var appearanceSection: some View {
        Section(header: Text("Appearance")) {
            colorSelectionView
            iconSelectionView
        }
    }
    
    private var colorSelectionView: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Color")
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            colorGrid
        }
        .padding(.vertical, 8)
    }
    
    private var colorGrid: some View {
        LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 6), spacing: 12) {
            ForEach(availableColors, id: \.self) { color in
                colorButton(for: color)
            }
        }
    }
    
    private func colorButton(for color: String) -> some View {
        Button(action: { selectedColor = color }) {
            Circle()
                .fill(colorForName(color))
                .frame(width: 40, height: 40)
                .overlay(colorOverlay(for: color))
                .scaleEffect(selectedColor == color ? 1.1 : 1.0)
                .animation(.easeInOut(duration: 0.2), value: selectedColor)
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private func colorOverlay(for color: String) -> some View {
        Circle()
            .stroke(selectedColor == color ? Color.primary : Color.clear, lineWidth: 2)
    }
    
    private var iconSelectionView: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Icon")
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            iconGrid
        }
        .padding(.vertical, 8)
    }
    
    private var iconGrid: some View {
        LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 6), spacing: 12) {
            ForEach(availableIcons, id: \.self) { icon in
                iconButton(for: icon)
            }
        }
    }
    
    private func iconButton(for icon: String) -> some View {
        Button(action: { selectedIcon = icon }) {
            iconButtonContent(for: icon)
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private func iconButtonContent(for icon: String) -> some View {
        ZStack {
            iconBackground(for: icon)
            iconImage(for: icon)
        }
        .scaleEffect(selectedIcon == icon ? 1.1 : 1.0)
        .animation(.easeInOut(duration: 0.2), value: selectedIcon)
    }
    
    private func iconBackground(for icon: String) -> some View {
        Circle()
            .fill(selectedIcon == icon ? colorForName(selectedColor).opacity(0.2) : Color.secondary.opacity(0.1))
            .frame(width: 40, height: 40)
    }
    
    private func iconImage(for icon: String) -> some View {
        Image(systemName: icon)
            .font(.title3)
            .foregroundColor(selectedIcon == icon ? colorForName(selectedColor) : .secondary)
    }
    
    private var previewSection: some View {
        Section(header: Text("Preview")) {
            AccountCardView(account: previewAccount)
                .disabled(true)
        }
    }
    
    private var isFormValid: Bool {
        !accountName.trimmingCharacters(in: .whitespaces).isEmpty
    }
    
    private func saveChanges() {
        let updatedAccount = createUpdatedAccount()
        accountStore.updateAccount(updatedAccount)
        dismiss()
    }
    
    private func createUpdatedAccount() -> Account {
        var updatedAccount = account
        updatedAccount.name = accountName.trimmingCharacters(in: .whitespaces)
        updatedAccount.color = selectedColor
        updatedAccount.icon = selectedIcon
        return updatedAccount
    }
}

#Preview {
    EditAccountView(
        account: Account(
            name: "Chase Checking",
            startingBalance: 1500.00,
            icon: "creditcard",
            color: "Blue",
            accountType: .debit
        ),
        accountStore: AccountStore()
    )
}
