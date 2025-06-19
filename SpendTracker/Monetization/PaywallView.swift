import SwiftUI
import StoreKit

struct PaywallView: View {
    @ObservedObject var subscriptionManager: SubscriptionManager
    @Environment(\.dismiss) private var dismiss
    @State private var selectedProduct: Product?
    @State private var isPurchasing = false
    @State private var showingSuccess = false
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Header
                    headerSection
                    
                    // Feature Comparison
                    featureComparisonSection
                    
                    // Pricing Plans
                    pricingSection
                    
                    // Social Proof
                    socialProofSection
                    
                    // Purchase Button
                    purchaseSection
                    
                    // Legal Text
                    legalSection
                }
                .padding()
            }
            .background(
                LinearGradient(
                    colors: [Color.blue.opacity(0.1), Color.purple.opacity(0.1)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
            )
            .navigationTitle("Upgrade to Pro")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Close") {
                        dismiss()
                    }
                }
            }
        }
        .onAppear {
            selectedProduct = subscriptionManager.subscriptionProducts.first
        }
        .alert("Welcome to Pro!", isPresented: $showingSuccess) {
            Button("Get Started") {
                dismiss()
            }
        } message: {
            Text("You now have access to all premium features including unlimited accounts, AI insights, and receipt scanning!")
        }
    }
    
    private var headerSection: some View {
        VStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(LinearGradient(
                        colors: [.blue, .purple],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ))
                    .frame(width: 100, height: 100)
                
                Image(systemName: "brain.head.profile")
                    .font(.system(size: 45))
                    .foregroundColor(.white)
            }
            
            VStack(spacing: 8) {
                HStack {
                    Text("Money Insights Pro")
                        .font(.title)
                        .fontWeight(.bold)
                    
                    Image(systemName: "sparkles")
                        .font(.title2)
                        .foregroundColor(.orange)
                }
                
                Text("Unlock AI-powered financial intelligence")
                    .font(.headline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
        }
    }
    
    private var featureComparisonSection: some View {
        VStack(spacing: 16) {
            Text("What's Included")
                .font(.title2)
                .fontWeight(.semibold)
            
            VStack(spacing: 12) {
                FeatureRow(
                    icon: "infinity",
                    title: "Unlimited Accounts",
                    description: "Add as many bank accounts and credit cards as you need",
                    isPro: true
                )
                
                FeatureRow(
                    icon: "infinity",
                    title: "Unlimited Transactions",
                    description: "No monthly limits on transaction entries",
                    isPro: true
                )
                
                FeatureRow(
                    icon: "brain.head.profile",
                    title: "Advanced AI Financial Intelligence",
                    description: "Seasonal pattern detection, cash flow predictions, smart savings identification, and debt optimization strategies",
                    isPro: true
                )
                
                FeatureRow(
                    icon: "doc.text.viewfinder",
                    title: "Receipt Scanning",
                    description: "OCR receipt scanning with auto-categorization",
                    isPro: true
                )
                
                FeatureRow(
                    icon: "chart.bar.fill",
                    title: "Advanced Reports",
                    description: "Detailed analytics and custom date range reports",
                    isPro: true
                )
                
                FeatureRow(
                    icon: "bell.slash.fill",
                    title: "Ad-Free Experience",
                    description: "No interruptions while managing your finances",
                    isPro: true
                )
            }
        }
    }
    
    private var pricingSection: some View {
        VStack(spacing: 16) {
            Text("Choose Your Plan")
                .font(.title2)
                .fontWeight(.semibold)
            
            VStack(spacing: 12) {
                // FIXED: Monthly Plan - $1.99/month
                PricingCard(
                    title: "Monthly",
                    price: "$1.99",
                    period: "month",
                    billedAs: "Billed monthly",
                    isSelected: selectedProduct?.id.contains("monthly") ?? true,
                    savings: nil,
                    hasFreeTrial: true
                ) {
                    // Select monthly plan
                    selectedProduct = subscriptionManager.subscriptionProducts.first { $0.id.contains("monthly") }
                }
                
                // FIXED: Annual Plan - $20/year (saves 17%)
                PricingCard(
                    title: "Annual",
                    price: "$1.67",
                    period: "month",
                    billedAs: "Billed annually at $20",
                    isSelected: selectedProduct?.id.contains("yearly") ?? false,
                    savings: "Save 17%",
                    hasFreeTrial: true
                ) {
                    // Select yearly plan
                    selectedProduct = subscriptionManager.subscriptionProducts.first { $0.id.contains("yearly") }
                }
            }
        }
    }
    
    private var socialProofSection: some View {
        VStack(spacing: 12) {
            HStack {
                ForEach(0..<5) { _ in
                    Image(systemName: "star.fill")
                        .foregroundColor(.yellow)
                }
                
                Text("4.9")
                    .fontWeight(.semibold)
                
                Text("(2,847 reviews)")
                    .foregroundColor(.secondary)
            }
            .font(.subheadline)
            
            Text("\"The AI insights helped me save $200 per month!\"")
                .font(.caption)
                .italic()
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding()
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .shadow(color: .black.opacity(0.05), radius: 4)
    }
    
    private var purchaseSection: some View {
        VStack(spacing: 12) {
            Button(action: {
                Task {
                    if let product = selectedProduct {
                        await purchaseProduct(product)
                    } else {
                        // Create mock purchase for development
                        #if DEBUG
                        if subscriptionManager.isDevelopmentMode {
                            subscriptionManager.toggleMockProStatus()
                            showingSuccess = true
                        }
                        #endif
                    }
                }
            }) {
                HStack {
                    if isPurchasing {
                        ProgressView()
                            .scaleEffect(0.8)
                            .foregroundColor(.white)
                    } else {
                        Image(systemName: "crown.fill")
                    }
                    
                    Text(isPurchasing ? "Processing..." : "Start Free Trial")
                }
                .font(.headline)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding()
                .background(
                    LinearGradient(
                        colors: [.blue, .purple],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            .disabled(isPurchasing)
            
            Text("7-day free trial, then pricing as selected above")
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            
            Button("Restore Purchases") {
                Task {
                    await subscriptionManager.restorePurchases()
                }
            }
            .font(.subheadline)
            .foregroundColor(.blue)
        }
    }
    
    private var legalSection: some View {
        VStack(spacing: 8) {
            Text("Subscription automatically renews unless cancelled at least 24 hours before the end of the current period.")
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            
            HStack {
                Link("Terms of Service", destination: URL(string: "https://example.com/terms")!)
                Text("•")
                    .foregroundColor(.secondary)
                Link("Privacy Policy", destination: URL(string: "https://example.com/privacy")!)
            }
            .font(.caption)
            .foregroundColor(.blue)
        }
    }
    
    private func purchaseProduct(_ product: Product) async {
        isPurchasing = true
        
        do {
            let success = try await subscriptionManager.purchase(product)
            if success {
                showingSuccess = true
            }
        } catch {
            print("Purchase failed: \(error)")
        }
        
        isPurchasing = false
    }
}

struct FeatureRow: View {
    let icon: String
    let title: String
    let description: String
    let isPro: Bool
    
    var body: some View {
        HStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(isPro ? Color.blue.opacity(0.2) : Color.gray.opacity(0.2))
                    .frame(width: 40, height: 40)
                
                Image(systemName: icon)
                    .font(.system(size: 18))
                    .foregroundColor(isPro ? .blue : .gray)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                    .foregroundColor(.primary)
                
                Text(description)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            
            Spacer()
            
            if isPro {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(.green)
                    .font(.title3)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .shadow(color: .black.opacity(0.05), radius: 4)
    }
}

// FIXED: Simplified Pricing Card with correct pricing
struct PricingCard: View {
    let title: String
    let price: String
    let period: String
    let billedAs: String
    let isSelected: Bool
    let savings: String?
    let hasFreeTrial: Bool
    let onSelect: () -> Void
    
    var body: some View {
        Button(action: onSelect) {
            VStack(spacing: 12) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Text(title)
                                .font(.headline)
                                .fontWeight(.semibold)
                            
                            if let savings = savings {
                                Text(savings)
                                    .font(.caption)
                                    .fontWeight(.bold)
                                    .foregroundColor(.white)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 2)
                                    .background(Color.orange)
                                    .clipShape(Capsule())
                            }
                        }
                        
                        Text("\(price)/\(period)")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(.blue)
                        
                        Text(billedAs)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    if isSelected {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.title2)
                            .foregroundColor(.blue)
                    } else {
                        Image(systemName: "circle")
                            .font(.title2)
                            .foregroundColor(.gray)
                    }
                }
                
                if hasFreeTrial {
                    HStack {
                        Image(systemName: "gift.fill")
                            .foregroundColor(.green)
                        Text("7-day free trial")
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundColor(.green)
                        Spacer()
                    }
                }
            }
            .padding()
            .background(
                isSelected
                    ? Color.blue.opacity(0.1)
                    : Color(.systemBackground)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(
                        isSelected ? Color.blue : Color.gray.opacity(0.3),
                        lineWidth: isSelected ? 2 : 1
                    )
            )
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
        .buttonStyle(PlainButtonStyle())
    }
}

#Preview {
    PaywallView(subscriptionManager: SubscriptionManager())
}
