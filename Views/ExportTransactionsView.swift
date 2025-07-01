import SwiftUI
import UniformTypeIdentifiers

struct ExportTransactionsView: View {
    let accountStore: AccountStore
    let preselectedAccount: Account?
    
    @Environment(\.dismiss) private var dismiss
    @State private var selectedAccountId: UUID?
    @State private var startDate = Date()
    @State private var endDate = Date()
    @State private var exportAllAccounts = false
    //@State private var showingActivityView = false
    //@State private var csvData: Data?
    @State private var fileName = ""
    @State private var showingError = false
    @State private var errorMessage = ""
    
    // Simple computed property
    private var accounts: [Account] {
        accountStore.accounts.filter { !$0.transactions.isEmpty }
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                // Account Selection
                GroupBox("Account Selection") {
                    VStack(spacing: 12) {
                        if let preselected = preselectedAccount {
                            HStack {
                                Text("Account: \(preselected.name)")
                                Spacer()
                            }
                            
                            Toggle("Include All Accounts", isOn: $exportAllAccounts)
                        } else {
                            Toggle("Export All Accounts", isOn: $exportAllAccounts)
                        }
                        
                        if !exportAllAccounts && preselectedAccount == nil {
                            Picker("Select Account", selection: $selectedAccountId) {
                                Text("Choose Account").tag(nil as UUID?)
                                ForEach(accounts, id: \.id) { account in
                                    Text(account.name).tag(account.id as UUID?)
                                }
                            }
                            .pickerStyle(.menu)
                        }
                    }
                }
                
                // Date Range
                GroupBox("Date Range") {
                    VStack(spacing: 12) {
                        DatePicker("Start Date", selection: $startDate, displayedComponents: .date)
                        DatePicker("End Date", selection: $endDate, displayedComponents: .date)
                        
                        HStack {
                            Button("This Month") { setThisMonth() }
                            Button("Last Month") { setLastMonth() }
                            Button("All Time") { setAllTime() }
                        }
                        .buttonStyle(.bordered)
                    }
                }
                
                // Preview
                GroupBox("Export Preview") {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("File: \(getFileName())")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        Text("Transactions: \(getTransactionCount())")
                            .font(.subheadline)
                    }
                }
                
                Spacer()
                
                // Export Button
                Button("Export CSV") {
                    exportTransactions()
                }
                .buttonStyle(.borderedProminent)
                .disabled(getTransactionCount() == 0)
            }
            .padding()
            .navigationTitle("Export Transactions")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
        .onAppear {
            initializeDates()
            updateSelection()
        }
//        .sheet(isPresented: $showingActivityView) {
//            if let data = csvData {
//                ActivityViewController(
//                    activityItems: [CSVFileProvider(data: data, fileName: getFileName())],
//                    applicationActivities: nil
//                )
//            }
//        }
        .alert("Export Error", isPresented: $showingError) {
            Button("OK") { }
        } message: {
            Text(errorMessage)
        }
    }
    
    // MARK: - Helper Methods
    
    private func initializeDates() {
        let calendar = Calendar.current
        let now = Date()
        let components = calendar.dateComponents([.year, .month], from: now)
        startDate = calendar.date(from: components) ?? now
        endDate = now
    }
    
    private func updateSelection() {
        if preselectedAccount == nil && !exportAllAccounts && selectedAccountId == nil && !accounts.isEmpty {
            selectedAccountId = accounts.first?.id
        } else if let preselected = preselectedAccount {
            selectedAccountId = preselected.id
        }
    }
    
    private func setThisMonth() {
        let calendar = Calendar.current
        let now = Date()
        let components = calendar.dateComponents([.year, .month], from: now)
        startDate = calendar.date(from: components) ?? now
        endDate = now
    }
    
    private func setLastMonth() {
        let calendar = Calendar.current
        let now = Date()
        let lastMonth = calendar.date(byAdding: .month, value: -1, to: now) ?? now
        let components = calendar.dateComponents([.year, .month], from: lastMonth)
        startDate = calendar.date(from: components) ?? now
        endDate = calendar.date(byAdding: DateComponents(month: 1, day: -1), to: startDate) ?? now
    }
    
    private func setAllTime() {
        let allTransactions = accountStore.accounts.flatMap { $0.transactions }
        if let earliest = allTransactions.map({ $0.date }).min() {
            startDate = earliest
        }
        endDate = Date()
    }
    
    private func getFileName() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        let start = formatter.string(from: startDate)
        let end = formatter.string(from: endDate)
        
        if exportAllAccounts {
            return "AllAccounts_\(start)_\(end).csv"
        } else {
            let selectedAccount = getSelectedAccount()
            if let account = selectedAccount {
                let name = account.name.replacingOccurrences(of: " ", with: "_")
                return "\(name)_\(start)_\(end).csv"
            }
        }
        return "Export_\(start)_\(end).csv"
    }
    
    private func getSelectedAccount() -> Account? {
        if let preselected = preselectedAccount {
            return preselected
        } else if let id = selectedAccountId {
            return accountStore.accounts.first { $0.id == id }
        }
        return nil
    }
    
    private func getTransactionCount() -> Int {
        let targetAccounts = exportAllAccounts ? accountStore.accounts : [getSelectedAccount()].compactMap { $0 }
        
        return targetAccounts.flatMap { account in
            account.transactions.filter { transaction in
                transaction.date >= startDate && transaction.date <= endDate
            }
        }.count
    }
    
//    private func exportTransactions() {
//        do {
//            let csv = try generateCSV()
//            csvData = csv
//            showingActivityView = true
//        } catch {
//            errorMessage = error.localizedDescription
//            showingError = true
//        }
//    }
    
    private func exportTransactions() {
        do {
            let csv = try generateCSV()
            let fileName = getFileName()
            
            // Create temporary file
            let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent(fileName)
            try csv.write(to: tempURL)
            
            // Present share sheet directly
            let activityVC = UIActivityViewController(activityItems: [tempURL], applicationActivities: nil)
            
            // Configure for iPad
            if let popover = activityVC.popoverPresentationController {
                popover.sourceView = UIApplication.shared.connectedScenes
                    .compactMap { $0 as? UIWindowScene }
                    .flatMap { $0.windows }
                    .first { $0.isKeyWindow }
                popover.sourceRect = CGRect(x: UIScreen.main.bounds.midX, y: UIScreen.main.bounds.midY, width: 0, height: 0)
                popover.permittedArrowDirections = []
            }
            
            // Present the activity view controller
            if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
               let window = windowScene.windows.first,
               let rootViewController = window.rootViewController {
                
                var topViewController = rootViewController
                while let presentedViewController = topViewController.presentedViewController {
                    topViewController = presentedViewController
                }
                
                topViewController.present(activityVC, animated: true)
            }
            
        } catch {
            errorMessage = error.localizedDescription
            showingError = true
        }
    }
    
    private func generateCSV() throws -> Data {
        var csv = "AccountName,TransactionType,Payee,Category,Date,Amount\n"
        
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        
        let targetAccounts = exportAllAccounts ? accountStore.accounts : [getSelectedAccount()].compactMap { $0 }
        
        for account in targetAccounts {
            let transactions = account.transactions.filter { transaction in
                transaction.date >= startDate && transaction.date <= endDate
            }.sorted { $0.date > $1.date }
            
            for transaction in transactions {
                let accountName = escapeCSVField(account.name)
                let type = transaction.type.rawValue
                let payee = escapeCSVField(transaction.payee)
                let category = escapeCSVField(getCategoryName(for: transaction))
                let date = formatter.string(from: transaction.date)
                let amount = String(format: "%.2f", transaction.amount)
                
                csv += "\(accountName),\(type),\(payee),\(category),\(date),\(amount)\n"
            }
        }
        
        guard let data = csv.data(using: .utf8) else {
            throw ExportError.dataConversionFailed
        }
        
        return data
    }
    
    private func getCategoryName(for transaction: Transaction) -> String {
        if let notes = transaction.notes, notes.hasPrefix("Category: ") {
            let categoryPart = notes.components(separatedBy: " | ").first ?? notes
            return String(categoryPart.dropFirst("Category: ".count))
        }
        return transaction.category.rawValue
    }
    
    private func escapeCSVField(_ field: String) -> String {
        if field.contains(",") || field.contains("\"") || field.contains("\n") {
            let escaped = field.replacingOccurrences(of: "\"", with: "\"\"")
            return "\"\(escaped)\""
        }
        return field
    }
}

// MARK: - Supporting Types

enum ExportError: LocalizedError {
    case dataConversionFailed
    
    var errorDescription: String? {
        switch self {
        case .dataConversionFailed:
            return "Failed to convert data to CSV format"
        }
    }
}

// MARK: - CSV File Provider

//class CSVFileProvider: NSObject, UIActivityItemSource {
//    private let data: Data
//    private let fileName: String
//    
//    init(data: Data, fileName: String) {
//        self.data = data
//        self.fileName = fileName
//        super.init()
//    }
//    
//    func activityViewControllerPlaceholderItem(_ activityViewController: UIActivityViewController) -> Any {
//        return fileName
//    }
//    
//    func activityViewController(_ activityViewController: UIActivityViewController, itemForActivityType activityType: UIActivity.ActivityType?) -> Any? {
//        let tempDirectory = FileManager.default.temporaryDirectory
//        let fileURL = tempDirectory.appendingPathComponent(fileName)
//        
//        do {
//            try data.write(to: fileURL)
//            return fileURL
//        } catch {
//            print("Failed to write CSV file: \(error)")
//            return nil
//        }
//    }
//    
//    func activityViewController(_ activityViewController: UIActivityViewController, subjectForActivityType activityType: UIActivity.ActivityType?) -> String {
//        return "Transaction Export: \(fileName)"
//    }
//    
//    func activityViewController(_ activityViewController: UIActivityViewController, dataTypeIdentifierForActivityType activityType: UIActivity.ActivityType?) -> String {
//        return UTType.commaSeparatedText.identifier
//    }
//}

// MARK: - Activity View Controller

//struct ActivityViewController: UIViewControllerRepresentable {
//    let activityItems: [Any]
//    let applicationActivities: [UIActivity]?
//    
//    func makeUIViewController(context: Context) -> UIActivityViewController {
//        let controller = UIActivityViewController(
//            activityItems: activityItems,
//            applicationActivities: applicationActivities
//        )
//        
//        controller.excludedActivityTypes = [
//            .postToFacebook,
//            .postToTwitter,
//            .postToWeibo,
//            .postToVimeo,
//            .postToTencentWeibo,
//            .postToFlickr,
//            .assignToContact,
//            .saveToCameraRoll
//        ]
//        
//        return controller
//    }
//    
//    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {
//        // No updates needed
//    }
//}

#Preview {
    ExportTransactionsView(accountStore: AccountStore(), preselectedAccount: nil)
}
