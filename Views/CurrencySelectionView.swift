import SwiftUI

struct CurrencySelectionView: View {
    @ObservedObject var currencyManager: CurrencyManager
    @Environment(\.dismiss) private var dismiss
    
    @State private var searchText = ""
    @State private var showingCustomCurrency = false
    
    private var filteredCurrencies: [Currency] {
        if searchText.isEmpty {
            return CurrencyManager.supportedCurrencies
        } else {
            return CurrencyManager.supportedCurrencies.filter { currency in
                currency.name.localizedCaseInsensitiveContains(searchText) ||
                currency.code.localizedCaseInsensitiveContains(searchText) ||
                currency.symbol.localizedCaseInsensitiveContains(searchText)
            }
        }
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Search Bar
                searchBar
                
                // Currency List
                List {
                    // Current Selection
                    currentSelectionSection
                    
                    // Popular Currencies
                    popularCurrenciesSection
                    
                    // All Currencies
                    allCurrenciesSection
                    
                    // Custom Currency
                    customCurrencySection
                }
                .listStyle(InsetGroupedListStyle())
            }
            .navigationTitle("Select Currency")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarBackButtonHidden()
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .fontWeight(.semibold)
                }
            }
        }
        .sheet(isPresented: $showingCustomCurrency) {
            CustomCurrencyView(currencyManager: currencyManager)
        }
    }
    
    // MARK: - Search Bar
    
    private var searchBar: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.gray)
            
            TextField("Search currencies...", text: $searchText)
                .textFieldStyle(PlainTextFieldStyle())
            
            if !searchText.isEmpty {
                Button(action: {
                    searchText = ""
                }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.gray)
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .background(Color(.systemGray6))
        .cornerRadius(10)
        .padding()
    }
    
    // MARK: - Current Selection
    
    private var currentSelectionSection: some View {
        Section(header: Text("Current Selection")) {
            CurrencyRow(
                currency: currencyManager.selectedCurrency,
                isSelected: true,
                currencyManager: currencyManager
            )
        }
    }
    
    // MARK: - Popular Currencies
    
    private var popularCurrenciesSection: some View {
        Section(header: Text("Popular Currencies")) {
            let popularCodes = ["USD", "EUR", "GBP", "JPY", "CNY", "INR", "CAD", "AUD"]
            let popularCurrencies = CurrencyManager.supportedCurrencies.filter {
                popularCodes.contains($0.code) && $0.code != currencyManager.selectedCurrency.code
            }
            
            ForEach(popularCurrencies.filter { currency in
                searchText.isEmpty ||
                currency.name.localizedCaseInsensitiveContains(searchText) ||
                currency.code.localizedCaseInsensitiveContains(searchText)
            }) { currency in
                CurrencyRow(
                    currency: currency,
                    isSelected: false,
                    currencyManager: currencyManager
                )
            }
        }
    }
    
    // MARK: - All Currencies
    
    private var allCurrenciesSection: some View {
        Section(header: Text("All Currencies")) {
            let otherCurrencies = filteredCurrencies.filter { currency in
                currency.code != currencyManager.selectedCurrency.code &&
                currency.code != "CUSTOM" &&
                !["USD", "EUR", "GBP", "JPY", "CNY", "INR", "CAD", "AUD"].contains(currency.code)
            }
            
            ForEach(otherCurrencies) { currency in
                CurrencyRow(
                    currency: currency,
                    isSelected: false,
                    currencyManager: currencyManager
                )
            }
        }
    }
    
    // MARK: - Custom Currency
    
    private var customCurrencySection: some View {
        Section(header: Text("Custom"), footer: Text("Create your own currency symbol and format")) {
            Button(action: {
                showingCustomCurrency = true
            }) {
                HStack {
                    Text("🌍")
                        .font(.title2)
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Custom Currency")
                            .font(.headline)
                            .foregroundColor(.primary)
                        
                        Text("Set your own symbol and format")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    if currencyManager.selectedCurrency.code == "CUSTOM" {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.blue)
                    } else {
                        Image(systemName: "chevron.right")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
            .buttonStyle(PlainButtonStyle())
        }
    }
}

// MARK: - Currency Row

struct CurrencyRow: View {
    let currency: Currency
    let isSelected: Bool
    @ObservedObject var currencyManager: CurrencyManager
    
    var body: some View {
        Button(action: {
            currencyManager.updateCurrency(currency)
        }) {
            HStack {
                Text(currency.flag)
                    .font(.title2)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(currency.name)
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    HStack {
                        Text(currency.code)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        
                        Text("•")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        Text(currencyManager.formatAmount(1234.56))
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                }
                
                Spacer()
                
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.blue)
                }
            }
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Custom Currency View

struct CustomCurrencyView: View {
    @ObservedObject var currencyManager: CurrencyManager
    @Environment(\.dismiss) private var dismiss
    
    @State private var customSymbol: String
    @State private var symbolPosition: Currency.SymbolPosition
    
    init(currencyManager: CurrencyManager) {
        self.currencyManager = currencyManager
        
        if currencyManager.selectedCurrency.code == "CUSTOM" {
            self._customSymbol = State(initialValue: currencyManager.selectedCurrency.symbol)
            self._symbolPosition = State(initialValue: currencyManager.selectedCurrency.position)
        } else {
            self._customSymbol = State(initialValue: "$")
            self._symbolPosition = State(initialValue: .before)
        }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Custom Header
            HStack {
                Button("Cancel") {
                    dismiss()
                }
                
                Spacer()
                
                Text("Custom Currency")
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Spacer()
                
                Button("Save") {
                    saveCustomCurrency()
                }
                .fontWeight(.semibold)
                .disabled(customSymbol.trimmingCharacters(in: .whitespaces).isEmpty)
            }
            .padding()
            .background(Color(.systemGray6))
            
            // Form Content
            Form {
                Section(header: Text("Currency Symbol"), footer: Text("Enter the symbol for your currency (e.g., $, €, ₹, ¥)")) {
                    TextField("Currency Symbol", text: $customSymbol)
                        .font(.title2)
                        .multilineTextAlignment(.center)
                }
                
                Section(header: Text("Symbol Position")) {
                    ForEach(Currency.SymbolPosition.allCases, id: \.self) { position in
                        Button(action: {
                            symbolPosition = position
                        }) {
                            HStack {
                                Text(position.displayName)
                                    .foregroundColor(.primary)
                                
                                Spacer()
                                
                                if symbolPosition == position {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundColor(.blue)
                                }
                            }
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                }
                
                Section(header: Text("Preview")) {
                    VStack(spacing: 8) {
                        Text("Example amounts:")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        
                        HStack {
                            Text("Small:")
                            Spacer()
                            Text(formatPreviewAmount(12.50))
                                .fontWeight(.medium)
                        }
                        
                        HStack {
                            Text("Medium:")
                            Spacer()
                            Text(formatPreviewAmount(1234.56))
                                .fontWeight(.medium)
                        }
                        
                        HStack {
                            Text("Large:")
                            Spacer()
                            Text(formatPreviewAmount(123456.78))
                                .fontWeight(.medium)
                        }
                    }
                }
            }
        }
    }
    
    private func formatPreviewAmount(_ amount: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.minimumFractionDigits = 2
        formatter.maximumFractionDigits = 2
        
        guard let formattedNumber = formatter.string(from: NSNumber(value: amount)) else {
            return "\(customSymbol)0.00"
        }
        
        switch symbolPosition {
        case .before:
            return "\(customSymbol)\(formattedNumber)"
        case .after:
            return "\(formattedNumber) \(customSymbol)"
        }
    }
    
    private func saveCustomCurrency() {
        let customCurrency = Currency(
            code: "CUSTOM",
            symbol: customSymbol.trimmingCharacters(in: .whitespaces),
            name: "Custom Currency",
            position: symbolPosition
        )
        
        currencyManager.updateCurrency(customCurrency)
        dismiss()
    }
}

#Preview {
    CurrencySelectionView(currencyManager: CurrencyManager())
}
