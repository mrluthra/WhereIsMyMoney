import Foundation
import StoreKit
import SwiftUI

class SubscriptionManager: NSObject, ObservableObject {
    @Published var isSubscribed = false
    @Published var subscriptionStatus: SubscriptionStatus = .free
    @Published var isLoading = false
    @Published var subscriptionProducts: [Product] = []
    @Published var showingPaywall = false
    
    // MARK: - Development Testing
    #if DEBUG
    @Published var isDevelopmentMode = true  // Set to true for testing
    @Published var mockProStatus = false     // Toggle this to test Pro features
    #else
    @Published var isDevelopmentMode = false
    @Published var mockProStatus = false
    #endif
    
    // Free tier limitations
    static let FREE_ACCOUNT_LIMIT = 2
    static let FREE_TRANSACTIONS_PER_ACCOUNT_PER_MONTH = 50
    
    // Product IDs
    private let monthlyProductID = "com.whereismymoney.premium.monthly"
    private let yearlyProductID = "com.whereismymoney.premium.yearly"
    
    enum SubscriptionStatus {
        case free
        case premium
        case loading
        case mockPremium  // For development
        
        var displayName: String {
            switch self {
            case .free: return "Free"
            case .premium: return "Money Insights Pro"
            case .loading: return "Loading..."
            case .mockPremium: return "Pro (Dev Mode)"
            }
        }
    }
    
    // MARK: - Computed Properties for Testing
    
    private var effectiveSubscriptionStatus: Bool {
        #if DEBUG
        return isDevelopmentMode ? mockProStatus : isSubscribed
        #else
        return isSubscribed
        #endif
    }
    
    override init() {
        super.init()
        loadSubscriptionStatus()
        
        #if DEBUG
        // Load development settings
        mockProStatus = UserDefaults.standard.bool(forKey: "dev_mock_pro_status")
        #endif
        
        Task {
            await loadProducts()
            await updateSubscriptionStatus()
        }
    }
    
    // MARK: - Development Methods
    
    #if DEBUG
    func toggleMockProStatus() {
        mockProStatus.toggle()
        UserDefaults.standard.set(mockProStatus, forKey: "dev_mock_pro_status")
        
        // Update subscription status
        if mockProStatus {
            subscriptionStatus = .mockPremium
        } else {
            subscriptionStatus = .free
        }
        
        print("🧪 Dev Mode: Mock Pro Status = \(mockProStatus)")
    }
    
    func setDevelopmentMode(_ enabled: Bool) {
        isDevelopmentMode = enabled
        if !enabled {
            mockProStatus = false
            subscriptionStatus = isSubscribed ? .premium : .free
        }
        print("🧪 Development Mode: \(enabled)")
    }
    #endif
    
    // MARK: - Feature Gating (Updated for Testing)
    
    func canAddAccount(currentAccountCount: Int) -> Bool {
        if effectiveSubscriptionStatus {
            return true
        }
        return currentAccountCount < Self.FREE_ACCOUNT_LIMIT
    }
    
    func canAddTransaction(to accountId: UUID, accountStore: AccountStore) -> Bool {
        if effectiveSubscriptionStatus {
            return true
        }
        
        guard let account = accountStore.getAccount(accountId) else { return false }
        
        let calendar = Calendar.current
        let now = Date()
        let startOfMonth = calendar.dateInterval(of: .month, for: now)?.start ?? now
        let endOfMonth = calendar.dateInterval(of: .month, for: now)?.end ?? now
        
        let transactionsThisMonth = account.transactions.filter { transaction in
            transaction.date >= startOfMonth && transaction.date <= endOfMonth
        }
        
        return transactionsThisMonth.count < Self.FREE_TRANSACTIONS_PER_ACCOUNT_PER_MONTH
    }
    
    func getRemainingTransactions(for accountId: UUID, accountStore: AccountStore) -> Int {
        if effectiveSubscriptionStatus {
            return Int.max
        }
        
        guard let account = accountStore.getAccount(accountId) else { return 0 }
        
        let calendar = Calendar.current
        let now = Date()
        let startOfMonth = calendar.dateInterval(of: .month, for: now)?.start ?? now
        let endOfMonth = calendar.dateInterval(of: .month, for: now)?.end ?? now
        
        let transactionsThisMonth = account.transactions.filter { transaction in
            transaction.date >= startOfMonth && transaction.date <= endOfMonth
        }
        
        return max(0, Self.FREE_TRANSACTIONS_PER_ACCOUNT_PER_MONTH - transactionsThisMonth.count)
    }
    
    func canAccessAIInsights() -> Bool {
        return effectiveSubscriptionStatus
    }
    
    func canAccessReceiptScanning() -> Bool {
        return effectiveSubscriptionStatus
    }
    
    func canAccessReceiptsList() -> Bool {
        return effectiveSubscriptionStatus
    }
    
    func canAccessAdvancedReports() -> Bool {
        return effectiveSubscriptionStatus
    }
    
    // MARK: - Product Loading
    
    @MainActor
    func loadProducts() async {
        isLoading = true
        do {
            let products = try await Product.products(for: [monthlyProductID, yearlyProductID])
            subscriptionProducts = products.sorted { $0.price < $1.price }
        } catch {
            print("Failed to load products: \(error)")
            
            #if DEBUG
            // Create mock products for testing
            print("🧪 Creating mock products for development")
            #endif
        }
        isLoading = false
    }
    
    // MARK: - Purchase Management
    
    func purchase(_ product: Product) async throws -> Bool {
        #if DEBUG
        if isDevelopmentMode {
            // Simulate purchase in development
            mockProStatus = true
            subscriptionStatus = .mockPremium
            UserDefaults.standard.set(true, forKey: "dev_mock_pro_status")
            print("🧪 Dev Mode: Simulated purchase successful")
            return true
        }
        #endif
        
        let result = try await product.purchase()
        
        switch result {
        case .success(let verification):
            switch verification {
            case .verified(let transaction):
                await transaction.finish()
                await updateSubscriptionStatus()
                return true
            case .unverified:
                return false
            }
        case .pending:
            return false
        case .userCancelled:
            return false
        @unknown default:
            return false
        }
    }
    
    func restorePurchases() async {
        #if DEBUG
        if isDevelopmentMode {
            print("🧪 Dev Mode: Restore purchases - keeping mock status")
            return
        }
        #endif
        
        do {
            try await AppStore.sync()
            await updateSubscriptionStatus()
        } catch {
            print("Failed to restore purchases: \(error)")
        }
    }
    
    @MainActor
    private func updateSubscriptionStatus() async {
        var isActive = false
        
        #if DEBUG
        if isDevelopmentMode {
            isActive = mockProStatus
            subscriptionStatus = isActive ? .mockPremium : .free
            return
        }
        #endif
        
        // Check current entitlements using StoreKit 2
        if #available(iOS 15.0, *) {
            for await result in StoreKit.Transaction.currentEntitlements {
                switch result {
                case .verified(let transaction):
                    if transaction.productID == monthlyProductID || transaction.productID == yearlyProductID {
                        isActive = true
                        break
                    }
                case .unverified:
                    break
                }
            }
        } else {
            isActive = UserDefaults.standard.bool(forKey: "isSubscribed")
        }
        
        subscriptionStatus = isActive ? .premium : .free
        isSubscribed = isActive
        saveSubscriptionStatus()
    }
    
    // MARK: - Paywall Triggers
    
    func showPaywallIfNeeded(for feature: PremiumFeature) {
        #if DEBUG
        if isDevelopmentMode && mockProStatus {
            print("🧪 Dev Mode: Skipping paywall - user has mock Pro")
            return
        }
        #endif
        
        switch feature {
        case .addAccount(let currentCount):
            if !canAddAccount(currentAccountCount: currentCount) {
                showingPaywall = true
            }
        case .addTransaction(let accountId, let accountStore):
            if !canAddTransaction(to: accountId, accountStore: accountStore) {
                showingPaywall = true
            }
        case .aiInsights, .receiptScanning, .receiptsList, .advancedReports:
            if !effectiveSubscriptionStatus {
                showingPaywall = true
            }
        }
    }
    
    enum PremiumFeature {
        case addAccount(currentCount: Int)
        case addTransaction(accountId: UUID, accountStore: AccountStore)
        case aiInsights
        case receiptScanning
        case receiptsList
        case advancedReports
    }
    
    // MARK: - Promotional Pricing
    
    func getIntroductoryOffer(for product: Product) -> Product.SubscriptionOffer? {
        return product.subscription?.introductoryOffer
    }
    
    func hasTrialAvailable(for product: Product) -> Bool {
        guard let intro = getIntroductoryOffer(for: product) else { return false }
        return intro.paymentMode == .freeTrial
    }
    
    // MARK: - Persistence
    
    private func saveSubscriptionStatus() {
        UserDefaults.standard.set(isSubscribed, forKey: "isSubscribed")
    }
    
    private func loadSubscriptionStatus() {
        isSubscribed = UserDefaults.standard.bool(forKey: "isSubscribed")
        subscriptionStatus = isSubscribed ? .premium : .free
    }
}

// MARK: - Ad Management (Updated for Testing)

class AdManager: ObservableObject {
    @Published var shouldShowAds = true
    @Published var adRevenue: Double = 0.0
    
    enum AdPlacement {
        case homeViewBanner
        case betweenTransactions
        case afterTransaction
        case reportsInterstitial
        case accountDetailBanner
    }
    
    func shouldShowAd(for placement: AdPlacement, subscriptionManager: SubscriptionManager) -> Bool {
        // No ads for premium subscribers (including mock premium)
        #if DEBUG
        if subscriptionManager.isDevelopmentMode && subscriptionManager.mockProStatus {
            return false
        }
        #endif
        
        if subscriptionManager.isSubscribed {
            return false
        }
        
        switch placement {
        case .homeViewBanner:
            return true
        case .betweenTransactions:
            return shouldShowTransactionAd()
        case .afterTransaction:
            return shouldShowAfterActionAd()
        case .reportsInterstitial:
            return true
        case .accountDetailBanner:
            return true
        }
    }
    
    private func shouldShowTransactionAd() -> Bool {
        let transactionCount = UserDefaults.standard.integer(forKey: "totalTransactionCount")
        return transactionCount > 0 && transactionCount % 5 == 0
    }
    
    private func shouldShowAfterActionAd() -> Bool {
        let actionCount = UserDefaults.standard.integer(forKey: "userActionCount")
        return actionCount > 0 && actionCount % 3 == 0
    }
    
    func incrementActionCount() {
        let current = UserDefaults.standard.integer(forKey: "userActionCount")
        UserDefaults.standard.set(current + 1, forKey: "userActionCount")
    }
    
    func recordAdRevenue(_ amount: Double) {
        adRevenue += amount
        UserDefaults.standard.set(adRevenue, forKey: "totalAdRevenue")
    }
}
