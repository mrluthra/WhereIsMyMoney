import Foundation
import SwiftUI

class PayeeSuggestionEngine: ObservableObject {
    
    // MARK: - Payee Data Structure
    
    struct PayeeSuggestion: Identifiable, Hashable {
        let id = UUID()
        let name: String
        let frequency: Int
        let lastUsed: Date
        let averageAmount: Double
        let mostCommonCategory: String
        let mostCommonCategoryIcon: String
        
        var displayText: String {
            if averageAmount > 0 {
                return "\(name) • Avg: $\(String(format: "%.0f", averageAmount))"
            } else {
                return name
            }
        }
    }
    
    // MARK: - Smart Payee Suggestions
    
    func getPayeeSuggestions(
        for query: String,
        from accounts: [Account],
        categories: [CustomCategory],
        limit: Int = 5
    ) -> [PayeeSuggestion] {
        
        guard query.count >= 2 else { return [] }
        
        // Get all unique payees from transactions
        let payeeData = extractPayeeData(from: accounts, categories: categories)
        
        // Filter and rank suggestions
        let filteredSuggestions = payeeData
            .filter { payee in
                payee.name.localizedCaseInsensitiveContains(query)
            }
            .sorted { first, second in
                // Ranking algorithm
                let firstScore = calculateRelevanceScore(payee: first, query: query)
                let secondScore = calculateRelevanceScore(payee: second, query: query)
                return firstScore > secondScore
            }
            .prefix(limit)
        
        return Array(filteredSuggestions)
    }
    
    private func extractPayeeData(from accounts: [Account], categories: [CustomCategory]) -> [PayeeSuggestion] {
        var payeeStats: [String: PayeeStats] = [:]
        
        // Collect statistics for each payee
        for account in accounts {
            for transaction in account.transactions {
                let payeeName = transaction.payee.trimmingCharacters(in: .whitespaces)
                guard !payeeName.isEmpty && !payeeName.lowercased().contains("transfer") else { continue }
                
                if payeeStats[payeeName] == nil {
                    payeeStats[payeeName] = PayeeStats()
                }
                
                payeeStats[payeeName]?.addTransaction(
                    amount: transaction.amount,
                    date: transaction.date,
                    categoryName: extractCategoryName(from: transaction),
                    categoryIcon: findCategoryIcon(for: transaction, categories: categories)
                )
            }
        }
        
        // Convert to suggestions
        return payeeStats.compactMap { (payeeName, stats) in
            guard stats.transactionCount >= 1 else { return nil }
            
            return PayeeSuggestion(
                name: payeeName,
                frequency: stats.transactionCount,
                lastUsed: stats.lastUsed,
                averageAmount: stats.averageAmount,
                mostCommonCategory: stats.mostCommonCategory,
                mostCommonCategoryIcon: stats.mostCommonCategoryIcon
            )
        }
    }
    
    private func calculateRelevanceScore(payee: PayeeSuggestion, query: String) -> Double {
        var score = 0.0
        
        // Exact match bonus
        if payee.name.lowercased() == query.lowercased() {
            score += 100
        }
        
        // Starts with bonus
        if payee.name.lowercased().hasPrefix(query.lowercased()) {
            score += 50
        }
        
        // Frequency score (more frequently used = higher score)
        score += Double(payee.frequency) * 5
        
        // Recency score (more recent = higher score)
        let daysSinceLastUsed = Calendar.current.dateComponents([.day], from: payee.lastUsed, to: Date()).day ?? 0
        score += max(0, 30 - Double(daysSinceLastUsed)) // Recent usage bonus
        
        // String similarity score
        score += stringSimilarity(payee.name.lowercased(), query.lowercased()) * 20
        
        return score
    }
    
    private func stringSimilarity(_ str1: String, _ str2: String) -> Double {
        let longer = str1.count > str2.count ? str1 : str2
        let shorter = str1.count > str2.count ? str2 : str1
        
        if longer.isEmpty { return 1.0 }
        
        let editDistance = levenshteinDistance(shorter, longer)
        return (Double(longer.count) - Double(editDistance)) / Double(longer.count)
    }
    
    private func levenshteinDistance(_ str1: String, _ str2: String) -> Int {
        let str1Array = Array(str1)
        let str2Array = Array(str2)
        let str1Count = str1Array.count
        let str2Count = str2Array.count
        
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
    
    private func extractCategoryName(from transaction: Transaction) -> String {
        if let notes = transaction.notes,
           notes.hasPrefix("Category: ") {
            let categoryPart = notes.components(separatedBy: " | ").first ?? notes
            return String(categoryPart.dropFirst("Category: ".count))
        }
        return transaction.category.rawValue
    }
    
    private func findCategoryIcon(for transaction: Transaction, categories: [CustomCategory]) -> String {
        let categoryName = extractCategoryName(from: transaction)
        
        // Find matching custom category
        if let customCategory = categories.first(where: { $0.name.lowercased() == categoryName.lowercased() }) {
            return customCategory.icon
        }
        
        // Fallback to default icon
        return transaction.category.systemImage
    }
    
    // MARK: - Helper Classes
    
    private class PayeeStats {
        var transactionCount = 0
        var totalAmount = 0.0
        var lastUsed = Date.distantPast
        var categoryFrequency: [String: Int] = [:]
        var categoryIcons: [String: String] = [:]
        
        var averageAmount: Double {
            return transactionCount > 0 ? totalAmount / Double(transactionCount) : 0
        }
        
        var mostCommonCategory: String {
            return categoryFrequency.max { $0.value < $1.value }?.key ?? "Other"
        }
        
        var mostCommonCategoryIcon: String {
            return categoryIcons[mostCommonCategory] ?? "questionmark.circle"
        }
        
        func addTransaction(amount: Double, date: Date, categoryName: String, categoryIcon: String) {
            transactionCount += 1
            totalAmount += amount
            lastUsed = max(lastUsed, date)
            categoryFrequency[categoryName, default: 0] += 1
            categoryIcons[categoryName] = categoryIcon
        }
    }
}

// MARK: - Payee Suggestion View Component

struct PayeeSuggestionView: View {
    let suggestions: [PayeeSuggestionEngine.PayeeSuggestion]
    let onSelect: (PayeeSuggestionEngine.PayeeSuggestion) -> Void
    
    private func colorForCategoryColor(_ colorName: String) -> Color {
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
        if !suggestions.isEmpty {
            VStack(spacing: 0) {
                ForEach(suggestions) { suggestion in
                    Button(action: { onSelect(suggestion) }) {
                        HStack(spacing: 12) {
                            // Category icon
                            Image(systemName: suggestion.mostCommonCategoryIcon)
                                .font(.system(size: 16))
                                .foregroundColor(.blue)
                                .frame(width: 24)
                            
                            // Payee info
                            VStack(alignment: .leading, spacing: 2) {
                                Text(suggestion.name)
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                                    .foregroundColor(.primary)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                
                                HStack {
                                    Text(suggestion.mostCommonCategory)
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                    
                                    Spacer()
                                    
                                    if suggestion.averageAmount > 0 {
                                        Text("Avg: $\(String(format: "%.0f", suggestion.averageAmount))")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }
                                }
                            }
                            
                            // Frequency indicator
                            if suggestion.frequency > 1 {
                                Text("\(suggestion.frequency)")
                                    .font(.caption)
                                    .fontWeight(.semibold)
                                    .foregroundColor(.white)
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 2)
                                    .background(Color.blue)
                                    .clipShape(Capsule())
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)
                        .background(Color(.systemBackground))
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(PlainButtonStyle())
                    
                    if suggestion.id != suggestions.last?.id {
                        Divider()
                            .padding(.horizontal, 16)
                    }
                }
            }
            .background(Color(.systemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)
        }
    }
}
