import SwiftUI

struct ReportsView: View {
    @ObservedObject var accountStore: AccountStore
    @StateObject private var categoryStore = CategoryStore()
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var currencyManager: CurrencyManager
    
    @State private var selectedStartDate = Calendar.current.startOfMonth(for: Date()) ?? Date()
    @State private var selectedEndDate = Date()
    @State private var selectedReportType = ReportType.category
    @State private var showingTransactionDetail = false
    @State private var selectedReportItem: ReportItemData?
    @State private var showingExportSheet = false
    
    enum ReportType: String, CaseIterable {
        case category = "By Category"
        case payee = "By Payee"
        
        var systemImage: String {
            switch self {
            case .category: return "tag.circle"
            case .payee: return "person.circle"
            }
        }
    }
    
    // Simple data structure to avoid memory issues
    struct ReportItemData: Identifiable {
        let id = UUID()
        let name: String
        let amount: Double
        let icon: String
        let transactionCount: Int
        let percentage: Double
        let relatedTransactions: [TransactionData]
    }
    
    struct TransactionData: Identifiable {
        let id: UUID
        let amount: Double
        let payee: String
        let date: Date
        let type: Transaction.TransactionType
        let accountName: String
        let notes: String?
    }
    
    private var filteredTransactions: [Transaction] {
        let startOfDay = Calendar.current.startOfDay(for: selectedStartDate)
        let endOfDay = Calendar.current.endOfDay(for: selectedEndDate)
        
        return accountStore.accounts.flatMap { account in
            account.transactions.filter { transaction in
                transaction.date >= startOfDay && transaction.date <= endOfDay
            }
        }
    }
    
    private var reportData: [ReportItemData] {
        switch selectedReportType {
        case .category:
            return buildCategoryReportData()
        case .payee:
            return buildPayeeReportData()
        }
    }
    
    private var totalAmount: Double {
        reportData.reduce(0) { $0 + abs($1.amount) }
    }
    
    private var dateRangeText: String {
        let formatter = DateFormatter()
        
        if Calendar.current.isDate(selectedStartDate, inSameDayAs: selectedEndDate) {
            formatter.dateStyle = .medium
            return formatter.string(from: selectedStartDate)
        } else if Calendar.current.isDate(selectedStartDate, equalTo: selectedEndDate, toGranularity: .month) {
            formatter.dateFormat = "MMMM yyyy"
            return formatter.string(from: selectedStartDate)
        } else {
            formatter.dateStyle = .short
            let start = formatter.string(from: selectedStartDate)
            let end = formatter.string(from: selectedEndDate)
            return "\(start) - \(end)"
        }
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Header Section
                headerSection
                
                Divider()
                
                // Content
                if filteredTransactions.isEmpty {
                    emptyStateView
                } else if reportData.isEmpty {
                    noDataView
                } else {
                    reportContentView
                }
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Reports")
            .navigationBarTitleDisplayMode(.inline)
        }
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button("Close") {
                    dismiss()
                }
            }
            
            ToolbarItem(placement: .navigationBarTrailing) {
                Menu {
                    Button(action: { showingExportSheet = true }) {
                        Label("Export as CSV", systemImage: "doc.text")
                    }
                    Button(action: { /* Share functionality */ }) {
                        Label("Share Report", systemImage: "square.and.arrow.up")
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                }
            }
        }
        .sheet(isPresented: $showingTransactionDetail) {
            if let item = selectedReportItem {
                TransactionDetailModalView(
                    reportItem: item,
                    dateRange: dateRangeText,
                    currencyManager: currencyManager,
                    onDismiss: {
                        showingTransactionDetail = false
                        selectedReportItem = nil
                    }
                )
            }
        }
        .sheet(isPresented: $showingExportSheet) {
            ExportTransactionsView(accountStore: accountStore, preselectedAccount: nil)
        }
        .onAppear {
            setupInitialDates()
        }
    }
    
    // MARK: - View Components
    
    private var headerSection: some View {
        VStack(spacing: 16) {
            // Title and Stats
            VStack(spacing: 8) {
                Text("Financial Report")
                    .font(.headline)
                    .foregroundColor(.secondary)
                
                Text(dateRangeText)
                    .font(.title2)
                    .fontWeight(.semibold)
                
                if !filteredTransactions.isEmpty {
                    Text("\(filteredTransactions.count) transactions")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
            }
            
            // Date Pickers
            HStack(spacing: 16) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("From")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    DatePicker("Start Date", selection: $selectedStartDate, displayedComponents: .date)
                        .labelsHidden()
                        .datePickerStyle(.compact)
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("To")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    DatePicker("End Date", selection: $selectedEndDate, displayedComponents: .date)
                        .labelsHidden()
                        .datePickerStyle(.compact)
                }
            }
            
            // Quick Date Buttons
            quickDateButtonsView
            
            // Report Type Picker
            Picker("Report Type", selection: $selectedReportType) {
                ForEach(ReportType.allCases, id: \.self) { type in
                    Label(type.rawValue, systemImage: type.systemImage)
                        .tag(type)
                }
            }
            .pickerStyle(.segmented)
        }
        .padding()
        .background(Color(.systemBackground))
    }
    
    private var quickDateButtonsView: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                QuickDateButton(
                    title: "Today",
                    isSelected: isDateRangeSelected(
                        start: Calendar.current.startOfDay(for: Date()),
                        end: Date()
                    )
                ) {
                    selectedStartDate = Calendar.current.startOfDay(for: Date())
                    selectedEndDate = Date()
                }
                
                QuickDateButton(
                    title: "This Week",
                    isSelected: isDateRangeSelected(
                        start: Calendar.current.startOfWeek(for: Date()) ?? Date(),
                        end: Date()
                    )
                ) {
                    selectedStartDate = Calendar.current.startOfWeek(for: Date()) ?? Date()
                    selectedEndDate = Date()
                }
                
                QuickDateButton(
                    title: "This Month",
                    isSelected: isDateRangeSelected(
                        start: Calendar.current.startOfMonth(for: Date()) ?? Date(),
                        end: Date()
                    )
                ) {
                    selectedStartDate = Calendar.current.startOfMonth(for: Date()) ?? Date()
                    selectedEndDate = Date()
                }
                
                QuickDateButton(
                    title: "Last Month",
                    isSelected: isDateRangeSelected(
                        start: Calendar.current.startOfLastMonth(for: Date()) ?? Date(),
                        end: Calendar.current.endOfLastMonth(for: Date()) ?? Date()
                    )
                ) {
                    selectedStartDate = Calendar.current.startOfLastMonth(for: Date()) ?? Date()
                    selectedEndDate = Calendar.current.endOfLastMonth(for: Date()) ?? Date()
                }
            }
            .padding(.horizontal)
        }
    }
    
    private var emptyStateView: some View {
        VStack(spacing: 16) {
            Image(systemName: "chart.bar.doc.horizontal")
                .font(.system(size: 50))
                .foregroundColor(.secondary)
            
            Text("No Transactions")
                .font(.headline)
                .foregroundColor(.secondary)
            
            Text("No transactions found for the selected date range")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    private var noDataView: some View {
        VStack(spacing: 16) {
            Image(systemName: "chart.bar.xaxis")
                .font(.system(size: 50))
                .foregroundColor(.secondary)
            
            Text("No Data to Display")
                .font(.headline)
                .foregroundColor(.secondary)
            
            Text("All transactions in this period have zero amounts")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    private var reportContentView: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Summary Card
                summaryCardView
                
                // Report List
                reportListView
            }
            .padding()
        }
    }
    
    private var summaryCardView: some View {
        VStack(spacing: 12) {
            HStack {
                Text("Total \(selectedReportType == .category ? "Categories" : "Payees")")
                    .font(.headline)
                    .foregroundColor(.secondary)
                Spacer()
                Text("\(reportData.count)")
                    .font(.headline)
                    .fontWeight(.semibold)
            }
            
            HStack {
                Text("Total Amount")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                Spacer()
                Text(currencyManager.formatAmount(totalAmount))
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.blue)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 1)
    }
    
    private var reportListView: some View {
        LazyVStack(spacing: 12) {
            ForEach(Array(reportData.enumerated()), id: \.element.id) { index, item in
                ReportRowButton(
                    item: item,
                    rank: index + 1,
                    totalAmount: totalAmount,
                    currencyManager: currencyManager
                ) {
                    selectedReportItem = item
                    showingTransactionDetail = true
                }
            }
        }
    }
    
    // MARK: - Helper Methods
    
    private func setupInitialDates() {
        selectedStartDate = Calendar.current.startOfMonth(for: Date()) ?? Date()
        selectedEndDate = Date()
    }
    
    private func isDateRangeSelected(start: Date, end: Date) -> Bool {
        Calendar.current.isDate(selectedStartDate, inSameDayAs: start) &&
        Calendar.current.isDate(selectedEndDate, inSameDayAs: end)
    }
    
    private func buildCategoryReportData() -> [ReportItemData] {
        var categoryGroups: [String: [Transaction]] = [:]
        let allCategories = categoryStore.categoriesForType(.expense) + categoryStore.categoriesForType(.income)
        
        // Group transactions by category
        for transaction in filteredTransactions {
            let categoryName = extractCategoryName(from: transaction)
            
            if categoryGroups[categoryName] == nil {
                categoryGroups[categoryName] = []
            }
            categoryGroups[categoryName]?.append(transaction)
        }
        
        // Convert to report items
        let items = categoryGroups.compactMap { (categoryName, transactions) -> ReportItemData? in
            let totalAmount = transactions.reduce(0) { $0 + $1.amount }
            
            let icon: String
            if let customCategory = allCategories.first(where: { $0.name == categoryName }) {
                icon = customCategory.icon
            } else {
                icon = transactions.first?.category.systemImage ?? "questionmark.circle"
            }
            
            let transactionData = transactions.map { transaction in
                TransactionData(
                    id: transaction.id,
                    amount: transaction.amount,
                    payee: transaction.payee,
                    date: transaction.date,
                    type: transaction.type,
                    accountName: accountStore.getAccount(transaction.accountId)?.name ?? "Unknown",
                    notes: transaction.notes
                )
            }
            
            return ReportItemData(
                name: categoryName,
                amount: totalAmount,
                icon: icon,
                transactionCount: transactions.count,
                percentage: 0, // Will be calculated below
                relatedTransactions: transactionData
            )
        }
        
        // Sort and calculate percentages
        let sortedItems = items.sorted { abs($0.amount) > abs($1.amount) }
        let total = sortedItems.reduce(0) { $0 + abs($1.amount) }
        
        return sortedItems.map { item in
            ReportItemData(
                name: item.name,
                amount: item.amount,
                icon: item.icon,
                transactionCount: item.transactionCount,
                percentage: total == 0 ? 0 : (abs(item.amount) / total) * 100,
                relatedTransactions: item.relatedTransactions
            )
        }
    }
    
    private func buildPayeeReportData() -> [ReportItemData] {
        var payeeGroups: [String: [Transaction]] = [:]
        
        // Group transactions by payee
        for transaction in filteredTransactions {
            let payeeName = transaction.payee
            
            if payeeGroups[payeeName] == nil {
                payeeGroups[payeeName] = []
            }
            payeeGroups[payeeName]?.append(transaction)
        }
        
        // Convert to report items
        let items = payeeGroups.compactMap { (payeeName, transactions) -> ReportItemData? in
            let totalAmount = transactions.reduce(0) { $0 + $1.amount }
            
            let transactionData = transactions.map { transaction in
                TransactionData(
                    id: transaction.id,
                    amount: transaction.amount,
                    payee: transaction.payee,
                    date: transaction.date,
                    type: transaction.type,
                    accountName: accountStore.getAccount(transaction.accountId)?.name ?? "Unknown",
                    notes: transaction.notes
                )
            }
            
            return ReportItemData(
                name: payeeName,
                amount: totalAmount,
                icon: "person.circle",
                transactionCount: transactions.count,
                percentage: 0, // Will be calculated below
                relatedTransactions: transactionData
            )
        }
        
        // Sort and calculate percentages
        let sortedItems = items.sorted { abs($0.amount) > abs($1.amount) }
        let total = sortedItems.reduce(0) { $0 + abs($1.amount) }
        
        return sortedItems.map { item in
            ReportItemData(
                name: item.name,
                amount: item.amount,
                icon: item.icon,
                transactionCount: item.transactionCount,
                percentage: total == 0 ? 0 : (abs(item.amount) / total) * 100,
                relatedTransactions: item.relatedTransactions
            )
        }
    }
    
    private func extractCategoryName(from transaction: Transaction) -> String {
        if let notes = transaction.notes,
           notes.hasPrefix("Category: ") {
            let categoryPart = notes.components(separatedBy: " | ").first ?? notes
            return String(categoryPart.dropFirst("Category: ".count))
        }
        return transaction.category.rawValue
    }
}

// MARK: - Supporting Views

struct QuickDateButton: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(isSelected ? .white : .blue)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(isSelected ? Color.blue : Color.blue.opacity(0.1))
                .clipShape(Capsule())
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct ReportRowButton: View {
    let item: ReportsView.ReportItemData
    let rank: Int
    let totalAmount: Double
    let currencyManager: CurrencyManager
    let action: () -> Void
    
    private func colorForAmount(_ amount: Double) -> Color {
        return amount >= 0 ? .green : .red
    }
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 16) {
                // Rank
                Text("\(rank)")
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundColor(.secondary)
                    .frame(width: 20)
                
                // Icon
                Image(systemName: item.icon)
                    .font(.title3)
                    .foregroundColor(colorForAmount(item.amount))
                    .frame(width: 24)
                
                // Content
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text(item.name)
                            .font(.headline)
                            .lineLimit(1)
                            .foregroundColor(.primary)
                        
                        Spacer()
                        
                        Text("\(item.transactionCount)")
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundColor(.white)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.blue)
                            .clipShape(Capsule())
                    }
                    
                    // Progress bar
                    GeometryReader { geometry in
                        ZStack(alignment: .leading) {
                            Rectangle()
                                .fill(Color.secondary.opacity(0.2))
                                .frame(height: 4)
                            
                            Rectangle()
                                .fill(colorForAmount(item.amount))
                                .frame(width: geometry.size.width * (item.percentage / 100), height: 4)
                        }
                    }
                    .frame(height: 4)
                    
                    HStack {
                        Text("\(item.percentage, specifier: "%.1f")%")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        Spacer()
                        
                        Text("Tap for details")
                            .font(.caption)
                            .foregroundColor(.blue)
                    }
                }
                
                // Amount and Arrow
                VStack(alignment: .trailing, spacing: 2) {
                    Text(currencyManager.formatAmount(abs(item.amount)))
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(colorForAmount(item.amount))
                    
                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .padding()
            .background(Color(.systemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 1)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct TransactionDetailModalView: View {
    let reportItem: ReportsView.ReportItemData
    let dateRange: String
    let currencyManager: CurrencyManager
    let onDismiss: () -> Void
    
    private var sortedTransactions: [ReportsView.TransactionData] {
        reportItem.relatedTransactions.sorted { $0.date > $1.date }
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
            VStack(spacing: 0) {
                // Header
                VStack(spacing: 16) {
                    HStack {
                        Image(systemName: reportItem.icon)
                            .font(.title)
                            .foregroundColor(.blue)
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text(reportItem.name)
                                .font(.title2)
                                .fontWeight(.semibold)
                            
                            Text(dateRange)
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                    }
                    
                    // Summary Stats
                    HStack(spacing: 20) {
                        VStack(spacing: 4) {
                            Text("\(reportItem.transactionCount)")
                                .font(.title)
                                .fontWeight(.bold)
                                .foregroundColor(.blue)
                            Text("Transactions")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        VStack(spacing: 4) {
                            Text(currencyManager.formatAmount(abs(reportItem.amount)))
                                .font(.title)
                                .fontWeight(.bold)
                                .foregroundColor(reportItem.amount >= 0 ? .green : .red)
                            Text("Total")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        VStack(spacing: 4) {
                            Text(currencyManager.formatAmount(abs(reportItem.amount) / Double(reportItem.transactionCount)))
                                .font(.title)
                                .fontWeight(.bold)
                                .foregroundColor(.orange)
                            Text("Average")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }
                .padding()
                .background(Color(.systemBackground))
                
                Divider()
                
                // Transactions List
                List {
                    ForEach(sortedTransactions) { transaction in
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(transaction.payee)
                                        .font(.headline)
                                    
                                    Text(transaction.accountName)
                                        .font(.caption)
                                        .foregroundColor(.blue)
                                }
                                
                                Spacer()
                                
                                VStack(alignment: .trailing, spacing: 2) {
                                    Text("\(transaction.type == .expense ? "-" : "+")\(currencyManager.formatAmount(transaction.amount))")
                                        .font(.headline)
                                        .fontWeight(.semibold)
                                        .foregroundColor(colorForTransactionType(transaction.type))
                                    
                                    Text(transaction.date.formatted(date: .abbreviated, time: .omitted))
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                            }
                            
                            if let notes = transaction.notes, !notes.isEmpty {
                                Text(notes)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                    .lineLimit(2)
                            }
                        }
                        .padding(.vertical, 4)
                    }
                }
                .listStyle(PlainListStyle())
            }
            .navigationTitle("Transaction Details")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        onDismiss()
                    }
                    .fontWeight(.semibold)
                }
            }
        }
    }
}

// MARK: - Calendar Extensions

extension Calendar {
    func startOfMonth(for date: Date) -> Date? {
        let components = dateComponents([.year, .month], from: date)
        return self.date(from: components)
    }
    
    func endOfDay(for date: Date) -> Date {
        var components = DateComponents()
        components.day = 1
        components.second = -1
        return self.date(byAdding: components, to: startOfDay(for: date)) ?? date
    }
    
    func startOfWeek(for date: Date) -> Date? {
        let components = dateComponents([.yearForWeekOfYear, .weekOfYear], from: date)
        return self.date(from: components)
    }
    
    func startOfLastMonth(for date: Date) -> Date? {
        guard let startOfThisMonth = startOfMonth(for: date) else { return nil }
        return self.date(byAdding: .month, value: -1, to: startOfThisMonth)
    }
    
    func endOfLastMonth(for date: Date) -> Date? {
        guard let startOfThisMonth = startOfMonth(for: date) else { return nil }
        return self.date(byAdding: .day, value: -1, to: startOfThisMonth)
    }
    
    func startOfYear(for date: Date) -> Date? {
        let components = dateComponents([.year], from: date)
        return self.date(from: components)
    }
}

#Preview {
    ReportsView(accountStore: AccountStore())
        .environmentObject(CurrencyManager())
}
