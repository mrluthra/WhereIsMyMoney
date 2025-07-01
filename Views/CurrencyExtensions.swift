import SwiftUI

// MARK: - Environment Key for Currency Manager

struct CurrencyManagerKey: EnvironmentKey {
    static let defaultValue = CurrencyManager()
}

extension EnvironmentValues {
    var currencyManager: CurrencyManager {
        get { self[CurrencyManagerKey.self] }
        set { self[CurrencyManagerKey.self] = newValue }
    }
}

// MARK: - View Extensions for Easy Currency Formatting

extension View {
    func currencyEnvironment(_ currencyManager: CurrencyManager) -> some View {
        self.environment(\.currencyManager, currencyManager)
    }
}

// MARK: - Double Extensions for Currency Formatting

extension Double {
    func formatAsCurrency(using currencyManager: CurrencyManager) -> String {
        return currencyManager.formatAmount(self)
    }
    
    func formatAsCurrencyWithoutDecimals(using currencyManager: CurrencyManager) -> String {
        return currencyManager.formatAmountWithoutDecimals(self)
    }
}

// MARK: - String Extensions for Currency Input

extension String {
    // Remove currency symbols and formatting for parsing
    func cleanedForCurrencyInput() -> String {
        let allowedCharacters = CharacterSet(charactersIn: "0123456789.")
        return self.components(separatedBy: allowedCharacters.inverted).joined()
    }
    
    // Convert cleaned string to Double
    var doubleValue: Double {
        return Double(self) ?? 0.0
    }
}
