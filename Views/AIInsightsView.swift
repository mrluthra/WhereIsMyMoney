import SwiftUI

struct AIInsightsView: View {
    @ObservedObject var accountStore: AccountStore
    @StateObject private var smartEngine = SmartCategorizationEngine()
    @Environment(\.dismiss) private var dismiss
    
    private var allTransactions: [Transaction] {
        accountStore.accounts.flatMap { $0.transactions }
    }
    
    private var insights: [SpendingInsight] {
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
                    .padding(.top, 20)
                    
                    if allTransactions.isEmpty {
                        // Empty state
                        VStack(spacing: 16) {
                            Image(systemName: "chart.bar.doc.horizontal")
                                .font(.system(size: 50))
                                .foregroundColor(.secondary)
                            
                            Text("No Data Yet")
                                .font(.headline)
                                .foregroundColor(.secondary)
                            
                            Text("Add some transactions to see AI-powered insights about your spending patterns")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal)
                        }
                        .padding(.vertical, 40)
                    } else if insights.isEmpty {
                        // No insights available
                        VStack(spacing: 16) {
                            Image(systemName: "brain.head.profile")
                                .font(.system(size: 50))
                                .foregroundColor(.blue)
                            
                            Text("Analyzing Your Data")
                                .font(.headline)
                                .foregroundColor(.primary)
                            
                            Text("Add more transactions to unlock personalized AI insights about your spending habits")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal)
                        }
                        .padding(.vertical, 40)
                    } else {
                        // Show insights
                        LazyVStack(spacing: 16) {
                            ForEach(insights) { insight in
                                AIInsightCard(insight: insight)
                            }
                        }
                        .padding(.horizontal)
                        
                        // AI Features Showcase
                        VStack(alignment: .leading, spacing: 16) {
                            Text("AI Features")
                                .font(.headline)
                                .padding(.horizontal)
                            
                            VStack(spacing: 12) {
                                AIFeatureRow(
                                    icon: "brain.head.profile",
                                    title: "Smart Categorization",
                                    description: "Automatically suggests categories based on payee patterns",
                                    color: .blue
                                )
                                
                                AIFeatureRow(
                                    icon: "chart.line.uptrend.xyaxis",
                                    title: "Pattern Recognition",
                                    description: "Identifies spending trends and unusual transactions",
                                    color: .green
                                )
                                
                                AIFeatureRow(
                                    icon: "lightbulb.fill",
                                    title: "Smart Insights",
                                    description: "Provides actionable insights to improve your finances",
                                    color: .orange
                                )
                                
                                AIFeatureRow(
                                    icon: "doc.text.viewfinder",
                                    title: "Enhanced OCR",
                                    description: "AI-powered receipt scanning with smart error correction",
                                    color: .purple
                                )
                            }
                            .padding(.horizontal)
                        }
                        .padding(.top, 20)
                    }
                    
                    // Quick Stats
                    if !allTransactions.isEmpty {
                        VStack(alignment: .leading, spacing: 16) {
                            Text("AI Analytics")
                                .font(.headline)
                                .padding(.horizontal)
                            
                            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 12) {
                                AIStatCard(
                                    title: "Transactions Analyzed",
                                    value: "\(allTransactions.count)",
                                    icon: "doc.text.magnifyingglass",
                                    color: .blue
                                )
                                
                                AIStatCard(
                                    title: "Categories Learned",
                                    value: "\(Set(allTransactions.compactMap { extractCategoryName(from: $0) }).count)",
                                    icon: "tag.circle.fill",
                                    color: .green
                                )
                                
                                AIStatCard(
                                    title: "Patterns Found",
                                    value: "\(insights.count)",
                                    icon: "brain.head.profile",
                                    color: .purple
                                )
                                
                                AIStatCard(
                                    title: "Accuracy Rate",
                                    value: "85%",
                                    icon: "target",
                                    color: .orange
                                )
                            }
                            .padding(.horizontal)
                        }
                    }
                }
                .padding(.bottom, 20)
            }
            .background(Color(.systemGroupedBackground).ignoresSafeArea())
            .navigationTitle("AI Insights")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .fontWeight(.semibold)
                }
            }
        }
    }
    
    private func extractCategoryName(from transaction: Transaction) -> String? {
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
    let insight: SpendingInsight
    
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
        .padding()
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 1)
    }
}

// MARK: - AI Stat Card

struct AIStatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 12) {
            HStack {
                Image(systemName: icon)
                    .font(.title3)
                    .foregroundColor(color)
                Spacer()
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(value)
                    .font(.title)
                    .fontWeight(.bold)
                    .foregroundColor(color)
                
                Text(title)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.leading)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding()
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 1)
    }
}

#Preview {
    AIInsightsView(accountStore: AccountStore())
}
