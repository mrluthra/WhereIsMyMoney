import SwiftUI

struct AIInsightsView: View {
    @ObservedObject var accountStore: AccountStore
    @StateObject private var smartEngine = SmartCategorizationEngine()
    @Environment(\.dismiss) private var dismiss
    
    private var allTransactions: [Transaction] {
        accountStore.accounts.flatMap { $0.transactions }
    }
    
    private var insights: [BasicSpendingInsight] {
        smartEngine.generateSpendingInsights(transactions: allTransactions)
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // AI Header
                    VStack(spacing: 12) {
                        ZStack {
                            Circle()
                                .fill(LinearGradient(
                                    colors: [.blue, .purple],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ))
                                .frame(width: 80, height: 80)
                            
                            Image(systemName: "brain.head.profile")
                                .font(.system(size: 35))
                                .foregroundColor(.white)
                        }
                        
                        VStack(spacing: 4) {
                            HStack {
                                Text("AI Financial Insights")
                                    .font(.title2)
                                    .fontWeight(.bold)
                                
                                Image(systemName: "sparkles")
                                    .font(.title3)
                                    .foregroundColor(.blue)
                            }
                            
                            Text("Powered by machine learning")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                    }
                    .padding(.top)
                    
                    // Insights Section
                    if insights.isEmpty {
                        // Empty State
                        VStack(spacing: 16) {
                            Image(systemName: "chart.line.uptrend.xyaxis")
                                .font(.system(size: 60))
                                .foregroundColor(.blue.opacity(0.6))
                            
                            Text("Building Your Financial Profile")
                                .font(.headline)
                                .fontWeight(.semibold)
                            
                            Text("Add more transactions to unlock personalized AI insights and spending patterns.")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal)
                        }
                        .padding(.vertical, 40)
                    } else {
                        // Insights Cards
                        LazyVStack(spacing: 16) {
                            ForEach(insights) { insight in
                                AIInsightCard(insight: insight)
                            }
                        }
                        .padding(.horizontal)
                    }
                    
                    // AI Capabilities Section
                    VStack(alignment: .leading, spacing: 16) {
                        HStack {
                            Text("AI Capabilities")
                                .font(.headline)
                                .fontWeight(.semibold)
                            
                            Spacer()
                            
                            Image(systemName: "cpu")
                                .font(.title3)
                                .foregroundColor(.blue)
                        }
                        
                        VStack(spacing: 12) {
                            AIFeatureRow(
                                icon: "chart.pie.fill",
                                title: "Spending Pattern Analysis",
                                description: "Identifies trends in your spending behavior",
                                color: .blue
                            )
                            
                            AIFeatureRow(
                                icon: "exclamationmark.triangle.fill",
                                title: "Anomaly Detection",
                                description: "Alerts you to unusual transactions",
                                color: .orange
                            )
                            
                            AIFeatureRow(
                                icon: "target",
                                title: "Smart Categorization",
                                description: "Automatically suggests transaction categories",
                                color: .green
                            )
                            
                            AIFeatureRow(
                                icon: "crystal.ball.fill",
                                title: "Predictive Insights",
                                description: "Forecasts future spending patterns",
                                color: .purple
                            )
                        }
                    }
                    .padding()
                    .background(Color(.systemGroupedBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                    .padding(.horizontal)
                    
                    // Privacy Notice
                    VStack(spacing: 8) {
                        HStack {
                            Image(systemName: "lock.shield.fill")
                                .foregroundColor(.green)
                            Text("Privacy Protected")
                                .font(.subheadline)
                                .fontWeight(.semibold)
                        }
                        
                        Text("All AI analysis happens locally on your device. Your financial data never leaves your phone.")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding()
                    .background(Color.green.opacity(0.1))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .padding(.horizontal)
                    .padding(.bottom)
                }
            }
            .navigationTitle("AI Insights")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
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

// MARK: - AI Insight Card

struct AIInsightCard: View {
    let insight: BasicSpendingInsight
    
    private var cardColor: Color {
        switch insight.type {
        case .pattern: return .blue
        case .category: return .green
        case .anomaly: return .orange
        case .prediction: return .purple
        }
    }
    
    var body: some View {
        HStack(spacing: 16) {
            // Icon
            ZStack {
                Circle()
                    .fill(cardColor.opacity(0.2))
                    .frame(width: 50, height: 50)
                
                Image(systemName: insight.icon)
                    .font(.title2)
                    .foregroundColor(cardColor)
            }
            
            // Content
            VStack(alignment: .leading, spacing: 4) {
                Text(insight.title)
                    .font(.headline)
                    .foregroundColor(.primary)
                
                Text(insight.message)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            
            Spacer()
            
            // AI Badge
            VStack {
                Image(systemName: "sparkles")
                    .font(.caption)
                    .foregroundColor(cardColor)
                Spacer()
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(cardColor.opacity(0.2), lineWidth: 1)
        )
    }
}

// MARK: - AI Feature Row

struct AIFeatureRow: View {
    let icon: String
    let title: String
    let description: String
    let color: Color
    
    var body: some View {
        HStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(color.opacity(0.2))
                    .frame(width: 40, height: 40)
                
                Image(systemName: icon)
                    .font(.system(size: 18))
                    .foregroundColor(color)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
                
                Text(description)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            
            Spacer()
        }
    }
}

#Preview {
    AIInsightsView(accountStore: AccountStore())
}
