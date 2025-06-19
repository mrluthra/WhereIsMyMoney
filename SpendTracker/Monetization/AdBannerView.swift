import SwiftUI
import UIKit

// MARK: - Ad Banner View
struct AdBannerView: View {
    @ObservedObject var subscriptionManager: SubscriptionManager
    @ObservedObject var adManager: AdManager
    let placement: AdManager.AdPlacement
    
    @State private var adHeight: CGFloat = 50
    @State private var showingUpgradePrompt = false
    
    var body: some View {
        Group {
            if adManager.shouldShowAd(for: placement, subscriptionManager: subscriptionManager) {
                VStack(spacing: 0) {
                    // Mock Ad Content (Replace with actual ad SDK)
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("💰 Track Your Spending Better")
                                .font(.caption)
                                .fontWeight(.semibold)
                            Text("Get personalized insights with AI Pro")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                        
                        Button("Upgrade") {
                            subscriptionManager.showingPaywall = true
                        }
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(.white)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Color.blue)
                        .clipShape(Capsule())
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(Color(.systemGray6))
                    .overlay(
                        Rectangle()
                            .fill(Color.gray.opacity(0.3))
                            .frame(height: 0.5),
                        alignment: .bottom
                    )
                    
                    // Small "Ad" indicator
                    HStack {
                        Spacer()
                        Text("Ad")
                            .font(.system(size: 8))
                            .foregroundColor(.secondary)
                            .padding(.horizontal, 4)
                            .padding(.vertical, 1)
                            .background(Color(.systemGray5))
                            .clipShape(RoundedRectangle(cornerRadius: 2))
                        Spacer()
                    }
                    .padding(.bottom, 2)
                    .background(Color(.systemGray6))
                }
                .frame(height: adHeight)
                .onTapGesture {
                    // Record ad interaction
                    adManager.recordAdRevenue(0.02) // $0.02 per click
                    subscriptionManager.showingPaywall = true
                }
            }
        }
        .sheet(isPresented: $subscriptionManager.showingPaywall) {
            PaywallView(subscriptionManager: subscriptionManager)
        }
    }
}

// MARK: - Interstitial Ad View
struct InterstitialAdView: View {
    @ObservedObject var subscriptionManager: SubscriptionManager
    @ObservedObject var adManager: AdManager
    @Environment(\.dismiss) private var dismiss
    
    @State private var countdown = 5
    @State private var canSkip = false
    
    var body: some View {
        ZStack {
            Color.black.opacity(0.8)
                .ignoresSafeArea()
            
            VStack(spacing: 20) {
                // Ad Content
                VStack(spacing: 16) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 16)
                            .fill(
                                LinearGradient(
                                    colors: [.blue, .purple],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 280, height: 200)
                        
                        VStack(spacing: 12) {
                            Image(systemName: "brain.head.profile")
                                .font(.system(size: 40))
                                .foregroundColor(.white)
                            
                            Text("Unlock AI Insights")
                                .font(.title2)
                                .fontWeight(.bold)
                                .foregroundColor(.white)
                            
                            Text("See exactly where your money goes with smart categorization and spending patterns")
                                .font(.subheadline)
                                .foregroundColor(.white.opacity(0.9))
                                .multilineTextAlignment(.center)
                                .padding(.horizontal)
                            
                            Button("Try Free for 7 Days") {
                                subscriptionManager.showingPaywall = true
                                dismiss()
                            }
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundColor(.blue)
                            .padding(.horizontal, 20)
                            .padding(.vertical, 8)
                            .background(Color.white)
                            .clipShape(Capsule())
                        }
                    }
                    
                    Text("Advertisement")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.7))
                }
                
                // Skip button (appears after countdown)
                if canSkip {
                    Button("Skip Ad") {
                        dismiss()
                    }
                    .font(.headline)
                    .foregroundColor(.white)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 12)
                    .background(Color.white.opacity(0.2))
                    .clipShape(Capsule())
                } else {
                    Text("Ad closes in \(countdown)s")
                        .font(.subheadline)
                        .foregroundColor(.white.opacity(0.7))
                }
            }
        }
        .onAppear {
            startCountdown()
            // Record ad impression
            adManager.recordAdRevenue(0.01) // $0.01 per impression
        }
        .sheet(isPresented: $subscriptionManager.showingPaywall) {
            PaywallView(subscriptionManager: subscriptionManager)
        }
    }
    
    private func startCountdown() {
        Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { timer in
            countdown -= 1
            if countdown <= 0 {
                timer.invalidate()
                canSkip = true
            }
        }
    }
}

// MARK: - Native Ad Card
struct NativeAdCard: View {
    @ObservedObject var subscriptionManager: SubscriptionManager
    @ObservedObject var adManager: AdManager
    
    var body: some View {
        Button(action: {
            subscriptionManager.showingPaywall = true
            adManager.recordAdRevenue(0.03) // $0.03 per click
        }) {
            HStack(spacing: 16) {
                ZStack {
                    Circle()
                        .fill(LinearGradient(
                            colors: [.orange, .red],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ))
                        .frame(width: 50, height: 50)
                    
                    Image(systemName: "chart.line.uptrend.xyaxis")
                        .font(.title2)
                        .foregroundColor(.white)
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text("Boost Your Savings")
                            .font(.headline)
                            .foregroundColor(.primary)
                        
                        Spacer()
                        
                        Text("Sponsored")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color(.systemGray5))
                            .clipShape(Capsule())
                    }
                    
                    Text("AI-powered insights help users save an average of $200/month")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
                
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding()
            .background(Color(.systemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 1)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.blue.opacity(0.3), lineWidth: 1)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Free Tier Limitation Views

struct AccountLimitView: View {
    @ObservedObject var subscriptionManager: SubscriptionManager
    let currentAccountCount: Int
    
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "lock.circle.fill")
                .font(.system(size: 60))
                .foregroundColor(.orange)
            
            VStack(spacing: 8) {
                Text("Account Limit Reached")
                    .font(.title2)
                    .fontWeight(.bold)
                
                Text("You've reached the limit of \(SubscriptionManager.FREE_ACCOUNT_LIMIT) accounts on the free plan")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            
            VStack(spacing: 12) {
                Button("Upgrade to Pro") {
                    subscriptionManager.showingPaywall = true
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
                
                Text("Get unlimited accounts + AI insights")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)
    }
}

struct TransactionLimitView: View {
    @ObservedObject var subscriptionManager: SubscriptionManager
    let accountName: String
    let remainingTransactions: Int
    
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 60))
                .foregroundColor(.orange)
            
            VStack(spacing: 8) {
                Text("Transaction Limit Reached")
                    .font(.title2)
                    .fontWeight(.bold)
                
                if remainingTransactions > 0 {
                    Text("You have \(remainingTransactions) transactions left this month for \(accountName)")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                } else {
                    Text("You've reached the limit of \(SubscriptionManager.FREE_TRANSACTIONS_PER_ACCOUNT_PER_MONTH) transactions per month for \(accountName)")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
            }
            
            VStack(spacing: 12) {
                Button("Upgrade for Unlimited") {
                    subscriptionManager.showingPaywall = true
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
                
                if remainingTransactions <= 0 {
                    Text("Limit resets next month")
                        .font(.caption)
                        .foregroundColor(.secondary)
                } else {
                    Text("Get unlimited transactions + all Pro features")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)
    }
}

struct ReceiptScanLockedView: View {
    @ObservedObject var subscriptionManager: SubscriptionManager
    
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "doc.text.viewfinder")
                .font(.system(size: 60))
                .foregroundColor(.orange)
            
            VStack(spacing: 8) {
                Text("Receipt Scanning Locked")
                    .font(.title2)
                    .fontWeight(.bold)
                
                Text("Unlock AI-powered receipt scanning with OCR and smart categorization")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            
            VStack(spacing: 12) {
                Button("Unlock Receipt Scanning") {
                    subscriptionManager.showingPaywall = true
                }
                .font(.headline)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding()
                .background(
                    LinearGradient(
                        colors: [.orange, .red],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .clipShape(RoundedRectangle(cornerRadius: 12))
                
                Text("Includes unlimited scanning + AI categorization")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)
    }
}

struct FeatureLockedView: View {
    @ObservedObject var subscriptionManager: SubscriptionManager
    let featureName: String
    let featureDescription: String
    let featureIcon: String
    
    var body: some View {
        VStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(LinearGradient(
                        colors: [.blue, .purple],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ))
                    .frame(width: 80, height: 80)
                
                Image(systemName: featureIcon)
                    .font(.system(size: 35))
                    .foregroundColor(.white)
                
                // Lock overlay
                Image(systemName: "lock.fill")
                    .font(.system(size: 16))
                    .foregroundColor(.white)
                    .background(
                        Circle()
                            .fill(Color.orange)
                            .frame(width: 24, height: 24)
                    )
                    .offset(x: 20, y: 20)
            }
            
            VStack(spacing: 8) {
                HStack {
                    Text(featureName)
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    Image(systemName: "crown.fill")
                        .font(.title3)
                        .foregroundColor(.orange)
                }
                
                Text(featureDescription)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            
            Button("Unlock with Pro") {
                subscriptionManager.showingPaywall = true
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
        .padding()
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)
    }
}

// MARK: - Promotional Banner View

struct PromotionalBannerView: View {
    @ObservedObject var subscriptionManager: SubscriptionManager
    @State private var currentPromoIndex = 0
    
    private let promotions = [
        ("💰", "Save $200/month", "Join 10,000+ users using AI insights"),
        ("🎯", "Smart Budgeting", "Track spending patterns automatically"),
        ("📊", "Rich Analytics", "See where every dollar goes"),
        ("🔒", "Secure & Private", "Bank-level encryption for your data")
    ]
    
    var body: some View {
        Button(action: {
            subscriptionManager.showingPaywall = true
        }) {
            HStack(spacing: 12) {
                Text(promotions[currentPromoIndex].0)
                    .font(.title2)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(promotions[currentPromoIndex].1)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(.primary)
                    
                    Text(promotions[currentPromoIndex].2)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                VStack(spacing: 4) {
                    Text("Try Free")
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(.blue)
                    
                    Image(systemName: "arrow.right.circle.fill")
                        .font(.title3)
                        .foregroundColor(.blue)
                }
            }
            .padding()
            .background(
                LinearGradient(
                    colors: [Color.blue.opacity(0.1), Color.purple.opacity(0.1)],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.blue.opacity(0.3), lineWidth: 1)
            )
        }
        .buttonStyle(PlainButtonStyle())
        .onAppear {
            startPromoRotation()
        }
    }
    
    private func startPromoRotation() {
        Timer.scheduledTimer(withTimeInterval: 3.0, repeats: true) { _ in
            withAnimation(.easeInOut(duration: 0.5)) {
                currentPromoIndex = (currentPromoIndex + 1) % promotions.count
            }
        }
    }
}
