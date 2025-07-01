import Foundation
import SwiftUI

class SmartCategorizationEngine: ObservableObject {
    
    // MARK: - Pattern Matching Database (Simple AI)
    
    private let categoryPatterns: [String: [String]] = [
        "Food & Dining": ["mcdonald", "burger", "pizza", "starbucks", "coffee", "restaurant", "cafe", "food", "dining", "subway", "kfc", "taco", "wendy"],
        "Gas & Fuel": ["shell", "exxon", "bp", "chevron", "mobil", "gas", "fuel", "gasoline", "petrol"],
        "Groceries": ["walmart", "target", "kroger", "safeway", "whole foods", "trader joe", "costco", "grocery", "supermarket", "market"],
        "Shopping": ["amazon", "ebay", "mall", "store", "shopping", "retail", "online", "purchase"],
        "Bills & Utilities": ["electric", "power", "water", "sewer", "internet", "phone", "cable", "utility", "bill", "payment"],
        "Healthcare": ["doctor", "clinic", "hospital", "pharmacy", "medical", "health", "dental", "vision", "prescription"],
        "Entertainment": ["movie", "theater", "netflix", "spotify", "games", "entertainment", "concert", "show"],
        "Transportation": ["uber", "lyft", "taxi", "bus", "train", "parking", "toll", "transport"]
    ]
    
    // MARK: - Category Suggestion (Core AI Feature)
    
    func suggestCategory(for payee: String, amount: Double, existingCategories: [CustomCategory]) -> CustomCategory? {
        let cleanPayee = payee.lowercased().trimmingCharacters(in: .whitespaces)
        
        // Pattern matching (rule-based AI)
        let suggestedCategoryName = findBestMatch(for: cleanPayee)
        
        if let categoryName = suggestedCategoryName {
            return existingCategories.first { $0.name.lowercased().contains(categoryName.lowercased()) }
        }
        
        // Amount-based suggestions
        return suggestByAmount(amount, categories: existingCategories)
    }
    
    private func findBestMatch(for payee: String) -> String? {
        var bestMatch: String?
        var bestScore = 0
        
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
    
    private func suggestByAmount(_ amount: Double, categories: [CustomCategory]) -> CustomCategory? {
        // Amount-based heuristics (simple AI logic)
        if amount > 100 {
            return categories.first { $0.name.lowercased().contains("shopping") }
        } else if amount < 10 {
            return categories.first { $0.name.lowercased().contains("food") }
        } else if amount > 500 {
            return categories.first { $0.name.lowercased().contains("bills") }
        }
        
        return nil
    }
    
    // MARK: - Spending Insights (AI Analytics)
    
    func generateSpendingInsights(transactions: [Transaction]) -> [BasicSpendingInsight] {
        var insights: [BasicSpendingInsight] = []
        
        // 1. Weekend vs Weekday spending
        let weekendSpending = calculateWeekendSpending(transactions)
        if weekendSpending.weekendAverage > 0 && weekendSpending.weekdayAverage > 0 && weekendSpending.weekendAverage > weekendSpending.weekdayAverage * 1.2 {
            let percentage = Int(((weekendSpending.weekendAverage / weekendSpending.weekdayAverage) - 1) * 100)
            insights.append(BasicSpendingInsight(
                type: .pattern,
                title: "Weekend Spending Alert",
                message: "You spend \(percentage)% more on weekends",
                icon: "calendar.badge.exclamationmark"
            ))
        }
        
        // 2. Top spending category
        let topCategory = findTopSpendingCategory(transactions)
        if let category = topCategory {
            insights.append(BasicSpendingInsight(
                type: .category,
                title: "Top Spending Category",
                message: "\(category.name): $\(String(format: "%.0f", category.amount)) this month",
                icon: "chart.pie.fill"
            ))
        }
        
        // 3. Unusual spending detection
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

// MARK: - Data Models

struct BasicSpendingInsight: Identifiable {
    let id = UUID()
    let type: InsightType
    let title: String
    let message: String
    let icon: String
    
    enum InsightType {
        case pattern, category, anomaly, prediction
    }
}
