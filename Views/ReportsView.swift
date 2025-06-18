import SwiftUI
import Charts

struct ReportsView: View {
    @ObservedObject var accountStore: AccountStore
    @StateObject private var categoryStore = CategoryStore()
    @Environment(\.dismiss) private var dismiss
    
    @State private var selectedStartDate = Calendar.current.startOfMonth(for: Date()) ?? Date()
    @State private var selectedEndDate = Date()
    @State private var selectedReportType = ReportType.category
    
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
    
    private var filteredTransactions: [Transaction] {
        let startOfDay = Calendar.current.startOfDay(for: selectedStartDate)
        let endOfDay = Calendar.current.endOfDay(for: selectedEndDate)
        
        return accountStore.accounts.flatMap { account in
            account.transactions.filter { transaction in
                transaction.date >= startOfDay && transaction.date <= endOfDay
            }
        }
    }
    
    private var reportData: [(String, Double, String)] {
        switch selectedReportType {
        case .category:
            return categoryReportData()
        case .payee:
            return payeeReportData()
        }
    }
    
    private var totalAmount: Double {
        reportData.reduce(0) { $0 + $1.1 }
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
                // Date Range Header
                VStack(spacing: 16) {
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
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 12) {
                            quickDateButton(title: "Today", startDate: Calendar.current.startOfDay(for: Date()), endDate: Date())
                            quickDateButton(title: "This Week", startDate: Calendar.current.startOfWeek(for: Date()) ?? Date(), endDate: Date())
                            quickDateButton(title: "This Month", startDate: Calendar.current.startOfMonth(for: Date()) ?? Date(), endDate: Date())
                            quickDateButton(title: "Last Month", startDate: Calendar.current.startOfLastMonth(for: Date()) ?? Date(), endDate: Calendar.current.endOfLastMonth(for: Date()) ?? Date())
                            quickDateButton(title: "This Year", startDate: Calendar.current.startOfYear(for: Date()) ?? Date(), endDate: Date())
                        }
                        .padding(.horizontal)
                    }
                    
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
                
                Divider()
                
                // Report Content
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
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Close") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Menu {
                        Button(action: { /* Export as CSV */ }) {
                            Label("Export as CSV", systemImage: "doc.text")
                        }
                        Button(action: { /* Export as PDF */ }) {
                            Label("Export as PDF", systemImage: "doc.richtext")
                        }
                        Button(action: { /* Share Report */ }) {
                            Label("Share Report", systemImage: "square.and.arrow.up")
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                    }
                }
            }
        }
        .onAppear {
            // Set default to current month
            selectedStartDate = Calendar.current.startOfMonth(for: Date()) ?? Date()
            selectedEndDate = Date()
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
                summaryCard
                
                // Report List
                reportList
            }
            .padding()
        }
    }
    
    private var summaryCard: some View {
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
                Text("$\(abs(totalAmount), specifier: "%.2f")")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(totalAmount >= 0 ? .green : .red)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 1)
    }
    
    private var reportList: some View {
        LazyVStack(spacing: 12) {
            ForEach(Array(reportData.enumerated()), id: \.offset) { index, item in
                ReportRowView(
                    title: item.0,
                    amount: item.1,
                    icon: item.2,
                    rank: index + 1,
                    percentage: totalAmount == 0 ? 0 : (abs(item.1) / abs(totalAmount)) * 100
                )
            }
        }
    }
    
    private func quickDateButton(title: String, startDate: Date, endDate: Date) -> some View {
        Button(action: {
            selectedStartDate = startDate
            selectedEndDate = endDate
        }) {
            Text(title)
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(isDateRangeSelected(start: startDate, end: endDate) ? .white : .blue)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(isDateRangeSelected(start: startDate, end: endDate) ? Color.blue : Color.blue.opacity(0.1))
                .clipShape(Capsule())
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private func isDateRangeSelected(start: Date, end: Date) -> Bool {
        Calendar.current.isDate(selectedStartDate, inSameDayAs: start) &&
        Calendar.current.isDate(selectedEndDate, inSameDayAs: end)
    }
    
    // MARK: - Report Data Methods
    
    private func categoryReportData() -> [(String, Double, String)] {
        var categoryTotals: [String: Double] = [:]
        var categoryIcons: [String: String] = [:]
        
        // Get all custom categories for icon mapping
        let allCategories = categoryStore.categoriesForType(.expense) + categoryStore.categoriesForType(.income)
        
        for transaction in filteredTransactions {
            let categoryName = extractCategoryName(from: transaction)
            let amount = transaction.type == .expense ? -transaction.amount : transaction.amount
            
            categoryTotals[categoryName, default: 0] += amount
            
            // Try to find icon from custom categories
            if categoryIcons[categoryName] == nil {
                if let customCategory = allCategories.first(where: { $0.name == categoryName }) {
                    categoryIcons[categoryName] = customCategory.icon
                } else {
                    categoryIcons[categoryName] = transaction.category.systemImage
                }
            }
        }
        
        return categoryTotals
            .map { (key, value) in (key, value, categoryIcons[key] ?? "questionmark.circle") }
            .sorted { abs($0.1) > abs($1.1) }
    }
    
    private func payeeReportData() -> [(String, Double, String)] {
        var payeeTotals: [String: Double] = [:]
        
        for transaction in filteredTransactions {
            let amount = transaction.type == .expense ? -transaction.amount : transaction.amount
            payeeTotals[transaction.payee, default: 0] += amount
        }
        
        return payeeTotals
            .map { (key, value) in (key, value, "person.circle") }
            .sorted { abs($0.1) > abs($1.1) }
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

struct ReportRowView: View {
    let title: String
    let amount: Double
    let icon: String
    let rank: Int
    let percentage: Double
    
    var body: some View {
        HStack(spacing: 16) {
            // Rank
            Text("\(rank)")
                .font(.caption)
                .fontWeight(.bold)
                .foregroundColor(.secondary)
                .frame(width: 20)
            
            // Icon
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(amount >= 0 ? .green : .red)
                .frame(width: 24)
            
            // Title and Progress Bar
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                    .lineLimit(1)
                
                // Progress bar
                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        Rectangle()
                            .fill(Color.secondary.opacity(0.2))
                            .frame(height: 4)
                        
                        Rectangle()
                            .fill(amount >= 0 ? Color.green : Color.red)
                            .frame(width: geometry.size.width * (percentage / 100), height: 4)
                    }
                }
                .frame(height: 4)
                
                Text("\(percentage, specifier: "%.1f")%")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            // Amount
            VStack(alignment: .trailing, spacing: 2) {
                Text("\(amount >= 0 ? "+" : "-")$\(abs(amount), specifier: "%.2f")")
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(amount >= 0 ? .green : .red)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 1)
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
}
