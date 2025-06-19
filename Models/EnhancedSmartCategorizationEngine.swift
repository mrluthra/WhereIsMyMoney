import Foundation
import SwiftUI

class EnhancedSmartCategorizationEngine: SmartCategorizationEngine {
    
    // MARK: - Enhanced Insight Model
    
    struct EnhancedInsight: Identifiable {
        let id = UUID()
        let type: InsightType
        let title: String
        let message: String
        let icon: String
        let priority: Int
        let actionable: Bool
        let recommendation: String?
        let savingsOpportunity: Double? // Monthly savings potential
        
        enum InsightType {
            case seasonalPattern
            case recurringPattern
            case cashFlowWarning
            case savingsOpportunity
            case trendAnalysis
            case subscriptionAnalysis
            case debtWarning
            case goalRecommendation
            case merchantPattern
            case predictionAlert
            
            var color: Color {
                switch self {
                case .seasonalPattern: return .blue
                case .recurringPattern: return .purple
                case .cashFlowWarning: return .red
                case .savingsOpportunity: return .green
                case .trendAnalysis: return .orange
                case .subscriptionAnalysis: return .yellow
                case .debtWarning: return .red
                case .goalRecommendation: return .blue
                case .merchantPattern: return .indigo
                case .predictionAlert: return .pink
                }
            }
            
            var displayName: String {
                switch self {
                case .seasonalPattern: return "Seasonal Analysis"
                case .recurringPattern: return "Pattern Detection"
                case .cashFlowWarning: return "Cash Flow Alert"
                case .savingsOpportunity: return "Savings Opportunity"
                case .trendAnalysis: return "Spending Trend"
                case .subscriptionAnalysis: return "Subscription Review"
                case .debtWarning: return "Debt Management"
                case .goalRecommendation: return "Financial Goal"
                case .merchantPattern: return "Merchant Analysis"
                case .predictionAlert: return "Prediction"
                }
            }
        }
    }
    
    // MARK: - Basic Spending Insights (Free - Limited)
    
    override func generateSpendingInsights(transactions: [Transaction]) -> [BasicSpendingInsight] {
        var insights: [BasicSpendingInsight] = []
        
        // Basic weekend vs weekday spending
        let weekendSpending = calculateWeekendSpending(transactions)
        if weekendSpending.weekendAverage > weekendSpending.weekdayAverage * 1.2 {
            insights.append(BasicSpendingInsight(
                type: .pattern,
                title: "Weekend Spending Alert",
                message: "You spend \(Int((weekendSpending.weekendAverage / weekendSpending.weekdayAverage - 1) * 100))% more on weekends",
                icon: "calendar.badge.exclamationmark"
            ))
        }
        
        // Top spending category
        let topCategory = findTopSpendingCategory(transactions)
        if let category = topCategory {
            insights.append(BasicSpendingInsight(
                type: .category,
                title: "Top Spending Category",
                message: "\(category.name): $\(String(format: "%.0f", category.amount)) this month",
                icon: "chart.pie.fill"
            ))
        }
        
        // Basic unusual spending detection
        let unusualTransactions = detectUnusualSpending(transactions)
        if !unusualTransactions.isEmpty {
            insights.append(BasicSpendingInsight(
                type: .anomaly,
                title: "Unusual Spending Detected",
                message: "\(unusualTransactions.count) transactions seem higher than usual",
                icon: "exclamationmark.triangle.fill"
            ))
        }
        
        return insights
    }
    
    // MARK: - ENHANCED AI INSIGHTS (PRO ONLY)
    
    func generateEnhancedInsights(transactions: [Transaction], accounts: [Account], isPro: Bool) -> [EnhancedInsight] {
        // Return empty array if not Pro user
        guard isPro else { return [] }
        
        var insights: [EnhancedInsight] = []
        
        // 1. Seasonal Spending Patterns
        insights.append(contentsOf: analyzeSeasonalPatterns(transactions))
        
        // 2. Recurring Payment Detection
        insights.append(contentsOf: detectRecurringPayments(transactions))
        
        // 3. Cash Flow Predictions
        insights.append(contentsOf: predictCashFlow(transactions, accounts: accounts))
        
        // 4. Subscription Analysis
        insights.append(contentsOf: analyzeSubscriptions(transactions))
        
        // 5. Savings Opportunities
        insights.append(contentsOf: findSavingsOpportunities(transactions))
        
        // 6. Debt Warning Analysis
        insights.append(contentsOf: analyzeDebtPatterns(transactions, accounts: accounts))
        
        // 7. Merchant Pattern Analysis
        insights.append(contentsOf: analyzeMerchantPatterns(transactions))
        
        // 8. Emergency Fund Goals
        insights.append(contentsOf: analyzeEmergencyFund(transactions, accounts: accounts))
        
        return insights.sorted { $0.priority > $1.priority }
    }
    
    // MARK: - Enhanced Analysis Methods
    
    private func analyzeSeasonalPatterns(_ transactions: [Transaction]) -> [EnhancedInsight] {
        var insights: [EnhancedInsight] = []
        
        // Group transactions by month
        let monthlySpending = Dictionary(grouping: transactions.filter { $0.type == .expense }) { transaction in
            Calendar.current.component(.month, from: transaction.date)
        }
        
        // Find months with significantly higher spending
        let monthlyTotals = monthlySpending.mapValues { $0.reduce(0) { $0 + $1.amount } }
        guard !monthlyTotals.isEmpty else { return insights }
        
        let averageSpending = monthlyTotals.values.reduce(0, +) / Double(monthlyTotals.count)
        let currentMonth = Calendar.current.component(.month, from: Date())
        
        if let currentMonthSpending = monthlyTotals[currentMonth],
           currentMonthSpending > averageSpending * 1.3 {
            
            let monthName = DateFormatter().monthSymbols[currentMonth - 1]
            let increase = ((currentMonthSpending / averageSpending) - 1) * 100
            
            insights.append(EnhancedInsight(
                type: .seasonalPattern,
                title: "Seasonal Spending Spike Detected",
                message: "Your \(monthName) spending is \(String(format: "%.0f", increase))% higher than your monthly average.",
                icon: "calendar.circle.fill",
                priority: 85,
                actionable: true,
                recommendation: "Consider setting a monthly budget cap to manage seasonal spending variations.",
                savingsOpportunity: (currentMonthSpending - averageSpending) * 0.3
            ))
        }
        
        return insights
    }
    
    private func detectRecurringPayments(_ transactions: [Transaction]) -> [EnhancedInsight] {
        var insights: [EnhancedInsight] = []
        
        // Group by payee and find potential recurring payments
        let payeeGroups = Dictionary(grouping: transactions.filter { $0.type == .expense }) { $0.payee }
        
        for (payee, payeeTransactions) in payeeGroups {
            guard payeeTransactions.count >= 3 else { continue }
            
            // Check for regular intervals (monthly patterns)
            let sortedTransactions = payeeTransactions.sorted { $0.date < $1.date }
            var intervals: [TimeInterval] = []
            
            for i in 1..<sortedTransactions.count {
                let interval = sortedTransactions[i].date.timeIntervalSince(sortedTransactions[i-1].date)
                intervals.append(interval)
            }
            
            // Check if intervals are roughly monthly (25-35 days)
            let averageInterval = intervals.reduce(0, +) / Double(intervals.count)
            let monthlySeconds: TimeInterval = 30 * 24 * 60 * 60 // ~30 days
            
            if abs(averageInterval - monthlySeconds) < (5 * 24 * 60 * 60) { // Within 5 days of monthly
                let averageAmount = payeeTransactions.reduce(0) { $0 + $1.amount } / Double(payeeTransactions.count)
                
                insights.append(EnhancedInsight(
                    type: .recurringPattern,
                    title: "Recurring Payment Detected",
                    message: "You have a recurring payment to \(payee) averaging $\(String(format: "%.0f", averageAmount))/month.",
                    icon: "repeat.circle.fill",
                    priority: 75,
                    actionable: true,
                    recommendation: "Set up automatic tracking or budgeting for this recurring expense.",
                    savingsOpportunity: nil
                ))
            }
        }
        
        return insights
    }
    
    private func predictCashFlow(_ transactions: [Transaction], accounts: [Account]) -> [EnhancedInsight] {
        var insights: [EnhancedInsight] = []
        
        // Calculate recent spending trend
        let recentTransactions = transactions.filter { $0.date > Calendar.current.date(byAdding: .day, value: -30, to: Date()) ?? Date() }
        let recentExpenses = recentTransactions.filter { $0.type == .expense }
        
        guard !recentExpenses.isEmpty else { return insights }
        
        let totalRecentExpenses = recentExpenses.reduce(0) { $0 + $1.amount }
        let dailyAverageExpense = totalRecentExpenses / 30.0
        
        // Calculate current total balance
        let totalBalance = accounts.reduce(0) { total, account in
            return total + (account.accountType == .credit ? -abs(account.currentBalance) : account.currentBalance)
        }
        
        // Predict when balance might become concerning
        let daysUntilLowBalance = (totalBalance - 500) / dailyAverageExpense // 500 as buffer
        
        if daysUntilLowBalance < 30 && daysUntilLowBalance > 0 {
            insights.append(EnhancedInsight(
                type: .cashFlowWarning,
                title: "Cash Flow Warning",
                message: "Based on current spending, you may reach a low balance in \(Int(daysUntilLowBalance)) days.",
                icon: "exclamationmark.triangle.fill",
                priority: 95,
                actionable: true,
                recommendation: "Consider reducing discretionary spending or increasing income sources.",
                savingsOpportunity: dailyAverageExpense * 0.2 * 30 // 20% spending reduction
            ))
        }
        
        return insights
    }
    
    private func analyzeSubscriptions(_ transactions: [Transaction]) -> [EnhancedInsight] {
        var insights: [EnhancedInsight] = []
        
        // Detect potential subscriptions (recurring small amounts)
        let subscriptionKeywords = ["netflix", "spotify", "apple", "google", "amazon prime", "hulu", "disney", "subscription"]
        let potentialSubscriptions = transactions.filter { transaction in
            subscriptionKeywords.contains { transaction.payee.lowercased().contains($0) }
        }
        
        if !potentialSubscriptions.isEmpty {
            let totalSubscriptionCost = potentialSubscriptions.reduce(0) { $0 + $1.amount }
            let monthlyEstimate = totalSubscriptionCost // Assuming monthly transactions
            
            insights.append(EnhancedInsight(
                type: .subscriptionAnalysis,
                title: "Subscription Services Review",
                message: "You're spending approximately $\(String(format: "%.0f", monthlyEstimate))/month on subscription services.",
                icon: "tv.circle.fill",
                priority: 70,
                actionable: true,
                recommendation: "Review active subscriptions and cancel unused services to save money.",
                savingsOpportunity: monthlyEstimate * 0.3 // Potential 30% savings
            ))
        }
        
        return insights
    }
    
    private func findSavingsOpportunities(_ transactions: [Transaction]) -> [EnhancedInsight] {
        var insights: [EnhancedInsight] = []
        
        // Find categories with highest spending for potential savings
        var categorySpending: [String: Double] = [:]
        
        for transaction in transactions.filter({ $0.type == .expense }) {
            let categoryName = extractCategoryName(from: transaction)
            categorySpending[categoryName, default: 0] += transaction.amount
        }
        
        // Find top spending category
        if let topCategory = categorySpending.max(by: { $0.value < $1.value }),
           topCategory.value > 200 { // Only suggest if significant spending
            
            let potentialSavings = topCategory.value * 0.15 // 15% reduction potential
            
            insights.append(EnhancedInsight(
                type: .savingsOpportunity,
                title: "Savings Opportunity Identified",
                message: "Your highest spending category is \(topCategory.key) at $\(String(format: "%.0f", topCategory.value)).",
                icon: "dollarsign.circle.fill",
                priority: 80,
                actionable: true,
                recommendation: "Setting a budget for \(topCategory.key) could save you $\(String(format: "%.0f", potentialSavings))/month.",
                savingsOpportunity: potentialSavings
            ))
        }
        
        return insights
    }
    
    private func analyzeDebtPatterns(_ transactions: [Transaction], accounts: [Account]) -> [EnhancedInsight] {
        var insights: [EnhancedInsight] = []
        
        // Find credit card accounts with high balances
        let creditAccounts = accounts.filter { $0.accountType == .credit }
        let highDebtAccounts = creditAccounts.filter { abs($0.currentBalance) > 1000 }
        
        if !highDebtAccounts.isEmpty {
            let totalDebt = highDebtAccounts.reduce(0) { total, account in
                total + abs(account.currentBalance)
            }
            
            let creditAccountIds = Set(creditAccounts.map { $0.id })
            let averageMonthlyPayment = transactions
                .filter { transaction in
                    creditAccountIds.contains(transaction.accountId) && transaction.type == .income
                }
                .reduce(0) { $0 + $1.amount } / 12 // Rough monthly average
            
            if averageMonthlyPayment > 0 {
                let monthsToPayOff = totalDebt / averageMonthlyPayment
                
                insights.append(EnhancedInsight(
                    type: .debtWarning,
                    title: "Debt Payoff Analysis",
                    message: "At your current payment rate, it will take \(String(format: "%.1f", monthsToPayOff)) months to pay off your debt.",
                    icon: "creditcard.circle.fill",
                    priority: 90,
                    actionable: true,
                    recommendation: "Consider increasing monthly payments to reduce interest costs and payoff time.",
                    savingsOpportunity: nil
                ))
            }
        }
        
        return insights
    }
    
    private func analyzeEmergencyFund(_ transactions: [Transaction], accounts: [Account]) -> [EnhancedInsight] {
        var insights: [EnhancedInsight] = []
        
        // Calculate monthly expenses
        let threeMonthsAgo = Calendar.current.date(byAdding: .month, value: -3, to: Date()) ?? Date()
        let monthlyExpenses = transactions
            .filter { $0.type == .expense && $0.date > threeMonthsAgo }
            .reduce(0) { $0 + $1.amount } / 3.0 // 3-month average
        
        // Calculate liquid savings (debit accounts with positive balances)
        var liquidSavingsAccounts: [Account] = []
        for account in accounts {
            if account.accountType == .debit {
                liquidSavingsAccounts.append(account)
            }
        }
        
        let liquidSavings = liquidSavingsAccounts.reduce(0) { total, account in
            total + max(0, account.currentBalance)
        }
        
        let emergencyFundGoal = monthlyExpenses * 6 // 6 months of expenses
        
        if liquidSavings < emergencyFundGoal {
            let shortfall = emergencyFundGoal - liquidSavings
            let monthsNeeded = 12 // Target timeframe
            let monthlyNeeded = shortfall / Double(monthsNeeded)
            
            insights.append(EnhancedInsight(
                type: .goalRecommendation,
                title: "Emergency Fund Goal",
                message: "Your emergency fund is $\(String(format: "%.0f", shortfall)) short of the recommended 6-month goal. Ideal emergency fund: $\(String(format: "%.0f", emergencyFundGoal)) (6 months expenses).",
                icon: "shield.circle.fill",
                priority: 83,
                actionable: true,
                recommendation: "Save $\(String(format: "%.0f", monthlyNeeded))/month to reach your emergency fund goal in 12 months.",
                savingsOpportunity: nil
            ))
        }
        
        return insights
    }
    
    private func analyzeMerchantPatterns(_ transactions: [Transaction]) -> [EnhancedInsight] {
        var insights: [EnhancedInsight] = []
        
        // Find most frequent merchants
        var merchantFrequency: [String: Int] = [:]
        var merchantSpending: [String: Double] = [:]
        
        let expenseTransactions = transactions.filter { $0.type == .expense }
        
        for transaction in expenseTransactions {
            merchantFrequency[transaction.payee, default: 0] += 1
            merchantSpending[transaction.payee, default: 0] += transaction.amount
        }
        
        // Find high-frequency, high-spending merchants
        let topMerchants = merchantFrequency.filter { merchantData in
            let (merchant, frequency) = merchantData
            return frequency >= 5 && merchantSpending[merchant, default: 0] > 100
        }
        
        if let topMerchant = topMerchants.max(by: { first, second in
            let firstSpending = merchantSpending[first.key, default: 0]
            let secondSpending = merchantSpending[second.key, default: 0]
            return firstSpending < secondSpending
        }) {
            let totalSpent = merchantSpending[topMerchant.key, default: 0]
            let frequency = topMerchant.value
            let avgPerVisit = totalSpent / Double(frequency)
            
            insights.append(EnhancedInsight(
                type: .merchantPattern,
                title: "Top Spending Merchant Identified",
                message: "You've spent $\(String(format: "%.0f", totalSpent)) at \(topMerchant.key) across \(frequency) visits ($\(String(format: "%.0f", avgPerVisit)) avg per visit).",
                icon: "building.2.circle.fill",
                priority: 60,
                actionable: true,
                recommendation: "Set a monthly budget limit for \(topMerchant.key) to better control spending.",
                savingsOpportunity: avgPerVisit * 0.2 * Double(frequency) / 4 // 20% reduction potential monthly
            ))
        }
        
        return insights
    }
    
    // MARK: - Helper Methods
    
    private func findBestMatch(for payee: String) -> String? {
        var bestMatch: String?
        var bestScore = 0
        
        let categoryPatterns: [String: [String]] = [
            "Food & Dining": ["mcdonald", "burger", "pizza", "starbucks", "coffee", "restaurant", "cafe", "food", "dining", "subway", "kfc", "taco", "wendy"],
            "Gas & Fuel": ["shell", "exxon", "bp", "chevron", "mobil", "gas", "fuel", "gasoline", "petrol"],
            "Groceries": ["walmart", "target", "kroger", "safeway", "whole foods", "trader joe", "costco", "grocery", "supermarket", "market"],
            "Shopping": ["amazon", "ebay", "mall", "store", "shopping", "retail", "online", "purchase"],
            "Bills & Utilities": ["electric", "power", "water", "sewer", "internet", "phone", "cable", "utility", "bill", "payment"],
            "Healthcare": ["doctor", "clinic", "hospital", "pharmacy", "medical", "health", "dental", "vision", "prescription"],
            "Entertainment": ["movie", "theater", "netflix", "spotify", "games", "entertainment", "concert", "show"],
            "Transportation": ["uber", "lyft", "taxi", "bus", "train", "parking", "toll", "transport"]
        ]
        
        for (category, patterns) in categoryPatterns {
            for pattern in patterns {
                let score = calculateSimilarity(payee, pattern)
                if score > bestScore && score > 70 { // 70% similarity threshold
                    bestScore = score
                    bestMatch = category
                }
            }
        }
        
        return bestMatch
    }
    
    private func calculateSimilarity(_ str1: String, _ str2: String) -> Int {
        // Simple Levenshtein distance-based similarity
        let distance = levenshteinDistance(str1, str2)
        let maxLength = max(str1.count, str2.count)
        
        guard maxLength > 0 else { return 0 }
        
        let similarity = (1.0 - Double(distance) / Double(maxLength)) * 100
        return Int(similarity)
    }
    
    private func levenshteinDistance(_ str1: String, _ str2: String) -> Int {
        let str1Array = Array(str1)
        let str2Array = Array(str2)
        let str1Count = str1Array.count
        let str2Count = str2Array.count
        
        if str1Count == 0 { return str2Count }
        if str2Count == 0 { return str1Count }
        
        var matrix = Array(repeating: Array(repeating: 0, count: str2Count + 1), count: str1Count + 1)
        
        for i in 0...str1Count {
            matrix[i][0] = i
        }
        
        for j in 0...str2Count {
            matrix[0][j] = j
        }
        
        for i in 1...str1Count {
            for j in 1...str2Count {
                let cost = str1Array[i-1] == str2Array[j-1] ? 0 : 1
                matrix[i][j] = Swift.min(
                    matrix[i-1][j] + 1,      // deletion
                    matrix[i][j-1] + 1,      // insertion
                    matrix[i-1][j-1] + cost  // substitution
                )
            }
        }
        
        return matrix[str1Count][str2Count]
    }
    
    private func calculateWeekendSpending(_ transactions: [Transaction]) -> (weekendAverage: Double, weekdayAverage: Double) {
        let calendar = Calendar.current
        var weekendTotal = 0.0
        var weekdayTotal = 0.0
        var weekendCount = 0
        var weekdayCount = 0
        
        for transaction in transactions.filter({ $0.type == .expense }) {
            let weekday = calendar.component(.weekday, from: transaction.date)
            if weekday == 1 || weekday == 7 { // Sunday or Saturday
                weekendTotal += transaction.amount
                weekendCount += 1
            } else {
                weekdayTotal += transaction.amount
                weekdayCount += 1
            }
        }
        
        let weekendAvg = weekendCount > 0 ? weekendTotal / Double(weekendCount) : 0
        let weekdayAvg = weekdayCount > 0 ? weekdayTotal / Double(weekdayCount) : 0
        
        return (weekendAvg, weekdayAvg)
    }
    
    private func findTopSpendingCategory(_ transactions: [Transaction]) -> (name: String, amount: Double)? {
        var categoryTotals: [String: Double] = [:]
        
        for transaction in transactions.filter({ $0.type == .expense }) {
            let categoryName = extractCategoryName(from: transaction)
            categoryTotals[categoryName, default: 0] += transaction.amount
        }
        
        return categoryTotals.max { $0.value < $1.value }.map { (name: $0.key, amount: $0.value) }
    }
    
    private func detectUnusualSpending(_ transactions: [Transaction]) -> [Transaction] {
        let expenses = transactions.filter { $0.type == .expense }
        guard expenses.count > 10 else { return [] }
        
        let amounts = expenses.map { $0.amount }
        let average = amounts.reduce(0, +) / Double(amounts.count)
        let threshold = average * 2.5 // 2.5x average is "unusual"
        
        return expenses.filter { $0.amount > threshold }
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
