import Foundation
import SwiftUI

class CurrencyManager: ObservableObject {
    @Published var selectedCurrency: Currency
    
    private let userDefaults = UserDefaults.standard
    private let currencyKey = "SelectedCurrency"
    
    // Predefined currencies
    static let supportedCurrencies: [Currency] = [
        // Major World Currencies
        Currency(code: "USD", symbol: "$", name: "US Dollar", position: .before),
        Currency(code: "EUR", symbol: "€", name: "Euro", position: .before),
        Currency(code: "GBP", symbol: "£", name: "British Pound", position: .before),
        Currency(code: "JPY", symbol: "¥", name: "Japanese Yen", position: .before),
        Currency(code: "CNY", symbol: "¥", name: "Chinese Yuan", position: .before),
        Currency(code: "INR", symbol: "₹", name: "Indian Rupee", position: .before),
        Currency(code: "CAD", symbol: "C$", name: "Canadian Dollar", position: .before),
        Currency(code: "AUD", symbol: "A$", name: "Australian Dollar", position: .before),
        Currency(code: "CHF", symbol: "Fr", name: "Swiss Franc", position: .before),
        Currency(code: "SEK", symbol: "kr", name: "Swedish Krona", position: .after),
        Currency(code: "NOK", symbol: "kr", name: "Norwegian Krone", position: .after),
        Currency(code: "DKK", symbol: "kr", name: "Danish Krone", position: .after),
        Currency(code: "PLN", symbol: "zł", name: "Polish Zloty", position: .after),
        Currency(code: "CZK", symbol: "Kč", name: "Czech Koruna", position: .after),
        Currency(code: "HUF", symbol: "Ft", name: "Hungarian Forint", position: .after),
        
        // Americas
        Currency(code: "BRL", symbol: "R$", name: "Brazilian Real", position: .before),
        Currency(code: "MXN", symbol: "$", name: "Mexican Peso", position: .before),
        Currency(code: "ARS", symbol: "$", name: "Argentine Peso", position: .before),
        Currency(code: "CLP", symbol: "$", name: "Chilean Peso", position: .before),
        Currency(code: "COP", symbol: "$", name: "Colombian Peso", position: .before),
        
        // Asia Pacific
        Currency(code: "KRW", symbol: "₩", name: "South Korean Won", position: .before),
        Currency(code: "SGD", symbol: "S$", name: "Singapore Dollar", position: .before),
        Currency(code: "HKD", symbol: "HK$", name: "Hong Kong Dollar", position: .before),
        Currency(code: "THB", symbol: "฿", name: "Thai Baht", position: .before),
        Currency(code: "MYR", symbol: "RM", name: "Malaysian Ringgit", position: .before),
        Currency(code: "IDR", symbol: "Rp", name: "Indonesian Rupiah", position: .before),
        Currency(code: "PHP", symbol: "₱", name: "Philippine Peso", position: .before),
        Currency(code: "VND", symbol: "₫", name: "Vietnamese Dong", position: .after),
        
        // Middle East & Africa
        Currency(code: "AED", symbol: "د.إ", name: "UAE Dirham", position: .before),
        Currency(code: "SAR", symbol: "﷼", name: "Saudi Riyal", position: .before),
        Currency(code: "ILS", symbol: "₪", name: "Israeli Shekel", position: .before),
        Currency(code: "TRY", symbol: "₺", name: "Turkish Lira", position: .before),
        Currency(code: "ZAR", symbol: "R", name: "South African Rand", position: .before),
        Currency(code: "EGP", symbol: "£", name: "Egyptian Pound", position: .before),
        
        // Eastern Europe
        Currency(code: "RUB", symbol: "₽", name: "Russian Ruble", position: .after),
        Currency(code: "UAH", symbol: "₴", name: "Ukrainian Hryvnia", position: .after),
        
        // Others
        Currency(code: "NZD", symbol: "NZ$", name: "New Zealand Dollar", position: .before),
        Currency(code: "RON", symbol: "lei", name: "Romanian Leu", position: .after),
        Currency(code: "BGN", symbol: "лв", name: "Bulgarian Lev", position: .after),
        Currency(code: "HRK", symbol: "kn", name: "Croatian Kuna", position: .after),
        
        // Custom option
        Currency(code: "CUSTOM", symbol: "$", name: "Custom Currency", position: .before)
    ]
    
    init() {
        // Load saved currency or default to USD
        if let savedCurrencyData = userDefaults.data(forKey: currencyKey),
           let savedCurrency = try? JSONDecoder().decode(Currency.self, from: savedCurrencyData) {
            self.selectedCurrency = savedCurrency
        } else {
            self.selectedCurrency = CurrencyManager.supportedCurrencies.first { $0.code == "USD" } ?? CurrencyManager.supportedCurrencies[0]
        }
    }
    
    func updateCurrency(_ currency: Currency) {
        selectedCurrency = currency
        saveCurrency()
    }
    
    func updateCustomCurrency(symbol: String, position: Currency.SymbolPosition) {
        if selectedCurrency.code == "CUSTOM" {
            selectedCurrency = Currency(
                code: "CUSTOM",
                symbol: symbol,
                name: "Custom Currency",
                position: position
            )
            saveCurrency()
        }
    }
    
    private func saveCurrency() {
        if let encoded = try? JSONEncoder().encode(selectedCurrency) {
            userDefaults.set(encoded, forKey: currencyKey)
        }
    }
    
    // MARK: - Formatting Methods
    
    func formatAmount(_ amount: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.minimumFractionDigits = 2
        formatter.maximumFractionDigits = 2
        
        guard let formattedNumber = formatter.string(from: NSNumber(value: amount)) else {
            return "\(selectedCurrency.symbol)0.00"
        }
        
        switch selectedCurrency.position {
        case .before:
            return "\(selectedCurrency.symbol)\(formattedNumber)"
        case .after:
            return "\(formattedNumber) \(selectedCurrency.symbol)"
        }
    }
    
    func formatAmountWithoutDecimals(_ amount: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.minimumFractionDigits = 0
        formatter.maximumFractionDigits = 0
        
        guard let formattedNumber = formatter.string(from: NSNumber(value: amount)) else {
            return "\(selectedCurrency.symbol)0"
        }
        
        switch selectedCurrency.position {
        case .before:
            return "\(selectedCurrency.symbol)\(formattedNumber)"
        case .after:
            return "\(formattedNumber) \(selectedCurrency.symbol)"
        }
    }
    
    // For text fields and user input
    var currencySymbol: String {
        return selectedCurrency.symbol
    }
    
    var currencyName: String {
        return selectedCurrency.name
    }
    
    var currencyCode: String {
        return selectedCurrency.code
    }
}

// MARK: - Currency Model

struct Currency: Codable, Identifiable, Hashable {
    let id = UUID()
    let code: String
    let symbol: String
    let name: String
    let position: SymbolPosition
    
    enum SymbolPosition: String, Codable, CaseIterable {
        case before = "before"
        case after = "after"
        
        var displayName: String {
            switch self {
            case .before: return "Before amount (e.g., $100)"
            case .after: return "After amount (e.g., 100 kr)"
            }
        }
    }
    
    private enum CodingKeys: String, CodingKey {
        case code, symbol, name, position
    }
}

// MARK: - Currency Extensions

extension Currency {
    var flag: String {
        switch code {
        case "USD": return "🇺🇸"
        case "EUR": return "🇪🇺"
        case "GBP": return "🇬🇧"
        case "JPY": return "🇯🇵"
        case "CNY": return "🇨🇳"
        case "INR": return "🇮🇳"
        case "CAD": return "🇨🇦"
        case "AUD": return "🇦🇺"
        case "CHF": return "🇨🇭"
        case "SEK": return "🇸🇪"
        case "NOK": return "🇳🇴"
        case "DKK": return "🇩🇰"
        case "PLN": return "🇵🇱"
        case "CZK": return "🇨🇿"
        case "HUF": return "🇭🇺"
        case "BRL": return "🇧🇷"
        case "MXN": return "🇲🇽"
        case "ARS": return "🇦🇷"
        case "CLP": return "🇨🇱"
        case "COP": return "🇨🇴"
        case "KRW": return "🇰🇷"
        case "SGD": return "🇸🇬"
        case "HKD": return "🇭🇰"
        case "THB": return "🇹🇭"
        case "MYR": return "🇲🇾"
        case "IDR": return "🇮🇩"
        case "PHP": return "🇵🇭"
        case "VND": return "🇻🇳"
        case "AED": return "🇦🇪"
        case "SAR": return "🇸🇦"
        case "ILS": return "🇮🇱"
        case "TRY": return "🇹🇷"
        case "ZAR": return "🇿🇦"
        case "EGP": return "🇪🇬"
        case "RUB": return "🇷🇺"
        case "UAH": return "🇺🇦"
        case "NZD": return "🇳🇿"
        case "RON": return "🇷🇴"
        case "BGN": return "🇧🇬"
        case "HRK": return "🇭🇷"
        case "CUSTOM": return "🌍"
        default: return "💱"
        }
    }
}
