import SwiftUI

struct EnhancedAIInsightsView: View {
    @ObservedObject var accountStore: AccountStore
    @ObservedObject var subscriptionManager: SubscriptionManager
    @StateObject private var enhancedEngine = EnhancedSmartCategorizationEngine()
    @Environment(\.dismiss) private var dismiss
    
    // Mock Pro subscription check - replace with actual subscription logic
    @State private var selectedCategory: String = "All Categories"
    @State private var isAnalyzing = false
    @State private var currentAnalysisStep = "Initializing..."
    
    private var allTransactions: [Transaction] {
        accountStore.accounts.flatMap { $0.transactions }
    }
    
    private var filteredTransactions: [Transaction] {
        if selectedCategory == "All Categories" {
            return allTransactions
        } else {
            return allTransactions.filter { transaction in
                extractCategoryName(from: transaction) == selectedCategory
            }
        }
    }
    
    private var isProUser: Bool {
        #if DEBUG
        return subscriptionManager.isSubscribed || (subscriptionManager.isDevelopmentMode && subscriptionManager.mockProStatus)
        #else
        return subscriptionManager.isSubscribed
        #endif
    }
    
    private var basicInsights: [BasicSpendingInsight] {
        enhancedEngine.generateSpendingInsights(transactions: filteredTransactions)
    }
    
    private var enhancedInsights: [EnhancedSmartCategorizationEngine.EnhancedInsight] {
        enhancedEngine.generateEnhancedInsights(
            transactions: filteredTransactions,
            accounts: accountStore.accounts,
            isPro: isProUser
        )
    }
    
    private var availableCategories: [String] {
        var categories = Set<String>()
        for transaction in allTransactions {
            categories.insert(extractCategoryName(from: transaction))
        }
        return ["All Categories"] + Array(categories).sorted()
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // Enhanced AI Header
                    enhancedHeaderView
                    
                    if isProUser {
                        // Category Filter
                        categoryFilterView
                        
                        // Analysis Progress (when analyzing)
                        if isAnalyzing {
                            analysisProgressView
                        } else {
                            // Enhanced Insights
                            enhancedInsightsView
                            
                            // Basic Insights (fallback)
                            if !basicInsights.isEmpty {
                                basicInsightsView
                            }
                        }
                        
                        // Pro Features showcase
                        proFeaturesView
                    } else {
                        // Free tier limitations
                        freeVersionView
                    }
                    
                    // AI Technology Section
                    aiTechnologyView
                }
            }
            .navigationTitle("Enhanced AI Insights")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Analyze") {
                        performAdvancedAIAnalysis()
                    }
                    .disabled(isAnalyzing || !isProUser)
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
    
    // MARK: - View Components
    
    private var enhancedHeaderView: some View {
        VStack(spacing: 16) {
            // Gradient AI Icon
            ZStack {
                Circle()
                    .fill(LinearGradient(
                        colors: [.purple, .blue, .cyan],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ))
                    .frame(width: 100, height: 100)
                    .shadow(color: .blue.opacity(0.3), radius: 10, x: 0, y: 5)
                
                Image(systemName: "brain.filled.head.profile")
                    .font(.system(size: 45))
                    .foregroundColor(.white)
            }
            
            VStack(spacing: 8) {
                HStack {
                    Text("Enhanced AI Insights")
                        .font(.title)
                        .fontWeight(.bold)
                    
                    if isProUser {
                        Text("PRO")
                            .font(.caption)
                            .fontWeight(.bold)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(LinearGradient(colors: [.orange, .red], startPoint: .leading, endPoint: .trailing))
                            .foregroundColor(.white)
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                    }
                }
                
                Text("Advanced machine learning analysis of your financial patterns")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
        }
        .padding(.top)
    }
    
    private var categoryFilterView: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Focus Analysis")
                .font(.headline)
                .fontWeight(.semibold)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(availableCategories, id: \.self) { category in
                        Button(action: {
                            selectedCategory = category
                        }) {
                            Text(category)
                                .font(.subheadline)
                                .fontWeight(.medium)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 8)
                                .background(
                                    selectedCategory == category
                                    ? LinearGradient(colors: [.blue, .purple], startPoint: .leading, endPoint: .trailing)
                                    : LinearGradient(colors: [.gray.opacity(0.2)], startPoint: .leading, endPoint: .trailing)
                                )
                                .foregroundColor(selectedCategory == category ? .white : .primary)
                                .clipShape(RoundedRectangle(cornerRadius: 20))
                        }
                    }
                }
                .padding(.horizontal)
            }
        }
        .padding(.horizontal)
    }
    
    private var analysisProgressView: some View {
        VStack(spacing: 20) {
            // AI Analysis Animation
            VStack(spacing: 16) {
                ZStack {
                    ForEach(0..<3, id: \.self) { index in
                        Circle()
                            .stroke(LinearGradient(colors: [.blue, .purple], startPoint: .leading, endPoint: .trailing), lineWidth: 2)
                            .frame(width: 60 + CGFloat(index * 20), height: 60 + CGFloat(index * 20))
                            .opacity(0.3 - Double(index) * 0.1)
                            .scaleEffect(isAnalyzing ? 1.2 : 1.0)
                            .animation(
                                Animation.easeInOut(duration: 1.5)
                                    .repeatForever(autoreverses: true)
                                    .delay(Double(index) * 0.2),
                                value: isAnalyzing
                            )
                    }
                    
                    Image(systemName: "brain.filled.head.profile")
                        .font(.system(size: 30))
                        .foregroundColor(.blue)
                }
                
                Text("AI Analysis in Progress")
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Text(currentAnalysisStep)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .animation(.easeInOut, value: currentAnalysisStep)
            }
            .padding()
            .background(Color(.systemGroupedBackground))
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .padding(.horizontal)
        }
    }
    
    private var enhancedInsightsView: some View {
        VStack(alignment: .leading, spacing: 16) {
            if !enhancedInsights.isEmpty {
                HStack {
                    Text("Advanced Insights")
                        .font(.headline)
                        .fontWeight(.semibold)
                    
                    Spacer()
                    
                    Text("\(enhancedInsights.count)")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 4)
                        .background(.blue.opacity(0.2))
                        .foregroundColor(.blue)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                }
                .padding(.horizontal)
                
                LazyVStack(spacing: 16) {
                    ForEach(enhancedInsights) { insight in
                        EnhancedInsightCard(insight: insight)
                    }
                }
                .padding(.horizontal)
            } else {
                noInsightsView
            }
        }
    }
    
    private var basicInsightsView: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Quick Insights")
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Spacer()
                
                Text("BASIC")
                    .font(.caption)
                    .fontWeight(.bold)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(.gray.opacity(0.2))
                    .foregroundColor(.secondary)
                    .clipShape(RoundedRectangle(cornerRadius: 6))
            }
            .padding(.horizontal)
            
            LazyVStack(spacing: 12) {
                ForEach(basicInsights) { insight in
                    BasicInsightCard(insight: insight)
                }
            }
            .padding(.horizontal)
        }
    }
    
    private var freeVersionView: some View {
        VStack(spacing: 20) {
            // Upgrade Prompt
            VStack(spacing: 16) {
                Image(systemName: "crown.fill")
                    .font(.system(size: 50))
                    .foregroundColor(.orange)
                
                Text("Unlock Enhanced AI Insights")
                    .font(.title2)
                    .fontWeight(.bold)
                
                Text("Get advanced spending analysis, predictions, and personalized recommendations.")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                
                Button(action: {
                    // Handle upgrade action
                }) {
                    Text("Upgrade to Pro")
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(LinearGradient(colors: [.orange, .red], startPoint: .leading, endPoint: .trailing))
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }
            }
            .padding()
            .background(Color(.systemGroupedBackground))
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .padding(.horizontal)
            
            // Limited basic insights
            if !basicInsights.isEmpty {
                basicInsightsView
            }
        }
    }
    
    private var proFeaturesView: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Pro AI Features")
                .font(.headline)
                .fontWeight(.semibold)
                .padding(.horizontal)
            
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 16) {
                ProFeatureCard(
                    icon: "calendar.circle.fill",
                    title: "Seasonal Analysis",
                    description: "Detect spending patterns across seasons",
                    color: .blue
                )
                
                ProFeatureCard(
                    icon: "arrow.clockwise.circle.fill",
                    title: "Recurring Detection",
                    description: "Identify subscription and recurring payments",
                    color: .purple
                )
                
                ProFeatureCard(
                    icon: "chart.line.uptrend.xyaxis.circle.fill",
                    title: "Cash Flow Prediction",
                    description: "Forecast future financial health",
                    color: .green
                )
                
                ProFeatureCard(
                    icon: "dollarsign.circle.fill",
                    title: "Savings Opportunities",
                    description: "AI-powered cost reduction suggestions",
                    color: .orange
                )
            }
            .padding(.horizontal)
        }
    }
    
    private var aiTechnologyView: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("AI Technology")
                .font(.headline)
                .fontWeight(.semibold)
                .padding(.horizontal)
            
            VStack(spacing: 12) {
                AITechRow(
                    icon: "network",
                    title: "Machine Learning Models",
                    description: "Advanced algorithms analyze your spending patterns"
                )
                
                AITechRow(
                    icon: "chart.bar.xaxis",
                    title: "Pattern Recognition",
                    description: "Identifies trends invisible to traditional analysis"
                )
                
                AITechRow(
                    icon: "shield.lefthalf.filled",
                    title: "Privacy-First Design",
                    description: "All processing happens locally on your device"
                )
            }
            .padding()
            .background(Color(.systemGroupedBackground))
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .padding(.horizontal)
        }
    }
    
    private var noInsightsView: some View {
        VStack(spacing: 16) {
            Image(systemName: "magnifyingglass.circle")
                .font(.system(size: 50))
                .foregroundColor(.blue.opacity(0.6))
            
            Text("No Significant Patterns Detected")
                .font(.headline)
                .foregroundColor(.primary)
            
            Text("No significant patterns or issues detected in your selected category. Your finances look stable.")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding(.vertical, 30)
        .padding(.horizontal)
    }
    
    // MARK: - Helper Methods
    
    private func performAdvancedAIAnalysis() {
        guard isProUser else { return }
        
        isAnalyzing = true
        
        let analysisSteps = [
            "Initializing AI engine...",
            "Analyzing transaction patterns...",
            "Detecting seasonal trends...",
            "Identifying savings opportunities...",
            "Generating predictions...",
            "Finalizing insights..."
        ]
        
        for (index, step) in analysisSteps.enumerated() {
            DispatchQueue.main.asyncAfter(deadline: .now() + Double(index) * 0.5) {
                currentAnalysisStep = step
                
                if index == analysisSteps.count - 1 {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        isAnalyzing = false
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

// MARK: - Supporting Views

struct BasicInsightCard: View {
    let insight: BasicSpendingInsight
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: insight.icon)
                .font(.title2)
                .foregroundColor(.blue)
                .frame(width: 30)
            
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
            
            Text("Basic")
                .font(.caption)
                .fontWeight(.medium)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(.gray.opacity(0.2))
                .foregroundColor(.secondary)
                .clipShape(RoundedRectangle(cornerRadius: 6))       .fontWeight(.medium)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(.gray.opacity(0.2))
                .foregroundColor(.secondary)
                .clipShape(RoundedRectangle(cornerRadius: 6))
        }
        .padding()
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 1)
    }
}

struct EnhancedInsightCard: View {
    let insight: EnhancedSmartCategorizationEngine.EnhancedInsight
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header
            HStack {
                ZStack {
                    Circle()
                        .fill(insight.type.color.opacity(0.2))
                        .frame(width: 50, height: 50)
                    
                    Image(systemName: insight.icon)
                        .font(.title2)
                        .foregroundColor(insight.type.color)
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text(insight.title)
                            .font(.headline)
                            .foregroundColor(.primary)
                        
                        Spacer()
                        
                        Text("PRO")
                            .font(.caption2)
                            .fontWeight(.bold)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(insight.type.color)
                            .foregroundColor(.white)
                            .clipShape(RoundedRectangle(cornerRadius: 4))
                    }
                    
                    Text(insight.type.displayName)
                        .font(.caption)
                        .foregroundColor(insight.type.color)
                        .fontWeight(.medium)
                }
            }
            
            // Message
            Text(insight.message)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .fixedSize(horizontal: false, vertical: true)
            
            // Recommendation and Savings
            if insight.actionable {
                VStack(alignment: .leading, spacing: 8) {
                    if let recommendation = insight.recommendation {
                        HStack(alignment: .top, spacing: 8) {
                            Image(systemName: "lightbulb.fill")
                                .font(.caption)
                                .foregroundColor(.orange)
                            
                            Text(recommendation)
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                        .padding(.top, 4)
                    }
                    
                    if let savings = insight.savingsOpportunity, savings > 0 {
                        HStack {
                            Image(systemName: "dollarsign.circle.fill")
                                .font(.caption)
                                .foregroundColor(.green)
                            
                            Text("Potential monthly savings: $\(String(format: "%.0f", savings))")
                                .font(.caption)
                                .fontWeight(.medium)
                                .foregroundColor(.green)
                        }
                    }
                }
                .padding(.top, 4)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(insight.type.color.opacity(0.3), lineWidth: 1)
        )
    }
}

struct ProFeatureCard: View {
    let icon: String
    let title: String
    let description: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(color.opacity(0.2))
                    .frame(width: 50, height: 50)
                
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundColor(color)
            }
            
            VStack(spacing: 4) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .multilineTextAlignment(.center)
                
                Text(description)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .lineLimit(3)
            }
        }
        .padding()
        .frame(height: 120)
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 1)
    }
}

struct AITechRow: View {
    let icon: String
    let title: String
    let description: String
    
    var body: some View {
        HStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(.blue.opacity(0.2))
                    .frame(width: 40, height: 40)
                
                Image(systemName: icon)
                    .font(.system(size: 16))
                    .foregroundColor(.blue)
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
    EnhancedAIInsightsView(
        accountStore: AccountStore(),
        subscriptionManager: SubscriptionManager()
    )
}
            
