import SwiftUI

struct AccountCardView: View {
    let account: Account
    
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
        HStack(spacing: 16) {
            // Icon
            ZStack {
                Circle()
                    .fill(colorForAccount(account.color).opacity(0.2))
                    .frame(width: 50, height: 50)
                
                Image(systemName: account.icon.isEmpty ? account.accountType.systemImage : account.icon)
                    .font(.title2)
                    .foregroundColor(colorForAccount(account.color))
            }
            
            // Account Info
            VStack(alignment: .leading, spacing: 4) {
                Text(account.name)
                    .font(.headline)
                    .foregroundColor(.primary)
                
                HStack(spacing: 8) {
                    Text(account.accountType.rawValue)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 2)
                        .background(Color.secondary.opacity(0.1))
                        .clipShape(Capsule())
                    
                    // Credit card specific indicator
                    if account.accountType == .credit && account.isInDebt {
                        Text("DEBT")
                            .font(.caption)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 1)
                            .background(Color.red)
                            .clipShape(Capsule())
                    }
                }
            }
            
            Spacer()
            
            // Balance
            VStack(alignment: .trailing, spacing: 4) {
                if account.accountType == .credit {
                    if account.currentBalance < 0 {
                        // Show debt amount
                        VStack(alignment: .trailing, spacing: 2) {
                            Text("$\(abs(account.currentBalance), specifier: "%.2f")")
                                .font(.headline)
                                .fontWeight(.semibold)
                                .foregroundColor(.red)
                            Text("debt")
                                .font(.caption)
                                .foregroundColor(.red)
                        }
                    } else {
                        // Show available credit
                        VStack(alignment: .trailing, spacing: 2) {
                            Text("$\(account.currentBalance, specifier: "%.2f")")
                                .font(.headline)
                                .fontWeight(.semibold)
                                .foregroundColor(.green)
                            Text("available")
                                .font(.caption)
                                .foregroundColor(.green)
                        }
                    }
                } else {
                    // Regular debit account
                    Text("$\(account.currentBalance, specifier: "%.2f")")
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(account.currentBalance >= 0 ? .green : .red)
                }
                
                if !account.transactions.isEmpty {
                    Text("\(account.transactions.count) transactions")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
    }
}

#Preview {
    VStack(spacing: 12) {
        // Debit account preview
        AccountCardView(account: Account(
            name: "Chase Checking",
            startingBalance: 1500.00,
            icon: "creditcard",
            color: "Blue",
            accountType: .debit
        ))
        
        // Credit card with debt preview
        AccountCardView(account: Account(
            name: "Chase Credit Card",
            startingBalance: 500.00, // This becomes -500 for credit cards
            icon: "creditcard.fill",
            color: "Red",
            accountType: .credit
        ))
    }
    .padding()
}
