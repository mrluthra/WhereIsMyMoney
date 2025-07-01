import SwiftUI

struct HomeView: View {
    @StateObject private var accountStore = AccountStore()
    @StateObject private var recurringStore = RecurringPaymentStore()
    @StateObject private var authManager = AuthenticationManager()
    @StateObject private var receiptManager = ReceiptManager()
    // MARK: - Use EnvironmentObject instead of StateObject
    @EnvironmentObject var currencyManager: CurrencyManager
    
    // MARK: - Monetization Objects
    @StateObject private var subscriptionManager = SubscriptionManager()
    @StateObject private var adManager = AdManager()
    @StateObject private var usageAnalytics = UsageAnalytics.shared
    
    // MARK: - NEW: Viral Features
    @StateObject private var viralManager = ViralContentManager()
    @State private var showingViralHub = false
    @State private var showingQuickMeme = false
    @State private var showingShareWin = false
    
    @State private var showingAddAccount = false
    @State private var showingManageCategories = false
    @State private var showingDuePayments = false
    @State private var showingAddTransfer = false
    @State private var showingSettings = false
    @State private var showingQuickAddTransaction = false
    @State private var showingScanReceipt = false
    @State private var showingReceiptsList = false
    @State private var showingAIInsights = false
    @State private var showingInterstitialAd = false
    
    // Account management states
    @State private var showingEditAccount = false
    @State private var accountToEdit: Account?
    @State private var showingDeleteAlert = false
    @State private var accountToDelete: Account?
    @State private var showingReports = false
    
    private var duePayments: [RecurringPayment] {
        recurringStore.getDuePayments()
    }
    
    // FIXED: Check if user has Pro subscription (including mock)
    private var isProUser: Bool {
        #if DEBUG
        return subscriptionManager.isSubscribed || (subscriptionManager.isDevelopmentMode && subscriptionManager.mockProStatus)
        #else
        return subscriptionManager.isSubscribed
        #endif
    }
    
    var body: some View {
        ZStack {
            if authManager.shouldShowAuthentication() {
                // Show authentication screen
                if authManager.showingPasscodeEntry {
                    PasscodeEntryView(authManager: authManager)
                        .transition(.opacity)
                } else {
                    // Trigger authentication on appear
                    Color.black
                        .ignoresSafeArea()
                        .onAppear {
                            authManager.authenticateUser()
                        }
                }
            } else {
                // Show main app content
                mainContent
            }
        }
        .animation(.easeInOut(duration: 0.3), value: authManager.isAuthenticated)
        .onAppear {
            // Check authentication when app appears
            if authManager.authenticationMethod != .none && !authManager.isAuthenticated {
                authManager.authenticateUser()
            }
            
            // Configure the scheduler with store instances
            RecurringPaymentScheduler.shared.configure(
                recurringStore: recurringStore,
                accountStore: accountStore
            )
            
            // Process any due payments when app launches
//            let processedTransactions = recurringStore.checkAndProcessDuePayments()
            _ = RecurringPaymentScheduler.shared.checkAndProcessDuePayments()
            
            // Add processed transactions to their respective accounts
//            for transaction in processedTransactions {
//                accountStore.addTransaction(transaction, to: transaction.accountId)
//            }
            RecurringPaymentScheduler.shared.scheduleUpcomingPaymentNotifications()
            
            // Track app open
            usageAnalytics.trackAppOpen()
        }
//        .onReceive(NotificationCenter.default.publisher(for: UIApplication.willEnterForegroundNotification)) { _ in
//            // Re-authenticate when app comes to foreground
//            if authManager.authenticationMethod != .none {
//                authManager.lockApp()
//                authManager.authenticateUser()
//            }
//        }
        .onReceive(NotificationCenter.default.publisher(for: UIApplication.willEnterForegroundNotification)) { _ in
            // Re-authenticate when app comes to foreground
            if authManager.authenticationMethod != .none {
                authManager.lockApp()
                authManager.authenticateUser()
            }
            
            // Check for new due payments when returning to foreground
            RecurringPaymentScheduler.shared.applicationWillEnterForeground()
        }
    }
    
    private var mainContent: some View {
        NavigationView {
            ScrollView {
                LazyVStack(spacing: 20) {
                    // Header with financial overview + NEW: Viral Commentary
                    financialOverviewSection
                    
                    // NEW: Viral Commentary Box (only show if user has interesting data)
//                    if shouldShowViralCommentary {
//                        viralCommentarySection
//                    }
                    
                    // FIXED: Subscription status banner ONLY for free users
                    if !isProUser {
                        PromotionalBannerView(subscriptionManager: subscriptionManager)
                            .padding(.horizontal)
                    }
                    
                    // Due Payments Alert
                    if !duePayments.isEmpty {
                        duePaymentsAlert
                    }
                    
                    // FIXED: Quick Actions (Monetized) - NOW WITH VIRAL ACTIONS
                    monetizedQuickActionsSection
                    
                    // FIXED: Ad Banner ONLY for free users
                    if !isProUser {
                        AdBannerView(
                            subscriptionManager: subscriptionManager,
                            adManager: adManager,
                            placement: .homeViewBanner
                        )
                    }
                    
                    // Accounts Section
                    accountsSection
                }
            }
            .background(Color(.systemGroupedBackground).ignoresSafeArea())
            .navigationTitle("CashPotato")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    // FIXED: Subscription status indicator - only show crown for actual Pro users
                    HStack {
                        if isProUser {
                            Image(systemName: "crown.fill")
                                .foregroundColor(.orange)
                                .font(.caption)
                        }
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    HStack(spacing: 12) {
                        // NEW: Viral Icons
//                        Button(action: {
//                            showingQuickMeme = true
//                            usageAnalytics.trackFeatureUsage("quick_meme")
//                        }) {
//                            ZStack {
//                                Circle()
//                                    .fill(
//                                        LinearGradient(
//                                            colors: [.purple, .blue],
//                                            startPoint: .topLeading,
//                                            endPoint: .bottomTrailing
//                                        )
//                                    )
//                                    .frame(width: 28, height: 28)
//
//                                Text("🎭")
//                                    .font(.system(size: 12))
//                            }
//                            .shadow(color: .black.opacity(0.2), radius: 2, x: 0, y: 1)
//                        }
//                        .buttonStyle(PlainButtonStyle())
                        
//                        Button(action: {
//                            showingViralHub = true
//                            usageAnalytics.trackFeatureUsage("viral_hub")
//                        }) {
//                            ZStack {
//                                Circle()
//                                    .fill(
//                                        LinearGradient(
//                                            colors: [.orange, .red],
//                                            startPoint: .topLeading,
//                                            endPoint: .bottomTrailing
//                                        )
//                                    )
//                                    .frame(width: 28, height: 28)
//
//                                Image(systemName: "flame.fill")
//                                    .foregroundColor(.white)
//                                    .font(.system(size: 12, weight: .bold))
//                            }
//                            .shadow(color: .black.opacity(0.2), radius: 2, x: 0, y: 1)
//                        }
//                        .buttonStyle(PlainButtonStyle())
                        
                        // Existing icons (slightly spaced out)
                        HStack(spacing: 12) {
                            // FIXED: AI Insights button - always show lock for non-Pro users
                            Button(action: {
                                if subscriptionManager.canAccessAIInsights() {
                                    showingAIInsights = true
                                } else {
                                    subscriptionManager.showPaywallIfNeeded(for: .aiInsights)
                                }
                                usageAnalytics.trackFeatureUsage("ai_insights_tap")
                            }) {
                                Image(systemName: isProUser ? "brain.head.profile" : "lock.fill")
                                    .font(.title3)
                                    .foregroundColor(isProUser ? .purple : .gray)
                            }
                            
                            // FIXED: Receipts button - always show lock for non-Pro users
                            Button(action: {
                                if subscriptionManager.canAccessReceiptsList() {
                                    showingReceiptsList = true
                                } else {
                                    subscriptionManager.showPaywallIfNeeded(for: .receiptsList)
                                }
                                usageAnalytics.trackFeatureUsage("receipts_tap")
                            }) {
                                Image(systemName: isProUser ? "doc.text.image" : "lock.fill")
                                    .font(.title3)
                                    .foregroundColor(isProUser ? .indigo : .gray)
                            }
                            
                            // Manage Categories button
                            Button(action: {
                                showingManageCategories = true
                                usageAnalytics.trackFeatureUsage("categories_tap")
                            }) {
                                Image(systemName: "tag.circle")
                                    .font(.title3)
                                    .foregroundColor(.orange)
                            }
                            
                            // Settings button
                            Button(action: { showingSettings = true }) {
                                Image(systemName: "gear")
                                    .font(.title3)
                                    .foregroundColor(.blue)
                            }
                        }
                    }
                }
            }
        }
        // Existing sheets...
        .sheet(isPresented: $showingAddAccount) {
            if subscriptionManager.canAddAccount(currentAccountCount: accountStore.accounts.count) {
                AddAccountView(accountStore: accountStore)
            } else {
                AccountLimitView(
                    subscriptionManager: subscriptionManager,
                    currentAccountCount: accountStore.accounts.count
                )
            }
        }
        .sheet(isPresented: $showingManageCategories) {
            ManageCategoriesView()
        }
        .sheet(isPresented: $showingDuePayments) {
            DuePaymentsView(
                duePayments: duePayments,
                recurringStore: recurringStore,
                accountStore: accountStore
            )
        }
        .sheet(isPresented: $showingAddTransfer) {
            AddTransferView(accountStore: accountStore)
        }
        .sheet(isPresented: $showingEditAccount) {
            if let account = accountToEdit {
                EditAccountView(account: account, accountStore: accountStore)
            }
        }
        .sheet(isPresented: $showingReports) {
            if subscriptionManager.canAccessAdvancedReports() {
                ReportsView(accountStore: accountStore)
            } else {
                FeatureLockedView(
                    subscriptionManager: subscriptionManager,
                    featureName: "Advanced Reports",
                    featureDescription: "Get detailed analytics, custom date ranges, and export capabilities",
                    featureIcon: "chart.bar.fill"
                )
            }
        }
        .sheet(isPresented: $showingSettings) {
            SettingsView(authManager: authManager, subscriptionManager: subscriptionManager)
        }
        .sheet(isPresented: $showingQuickAddTransaction) {
            QuickAddTransactionView(accountStore: accountStore)
                .onDisappear {
                    adManager.incrementActionCount()
                }
        }
        .sheet(isPresented: $showingScanReceipt) {
            if subscriptionManager.canAccessReceiptScanning() {
                ReceiptScannerView(accountStore: accountStore, receiptManager: receiptManager)
            } else {
                ReceiptScanLockedView(subscriptionManager: subscriptionManager)
            }
        }
        .sheet(isPresented: $showingReceiptsList) {
            if subscriptionManager.canAccessReceiptsList() {
                ReceiptsListView(receiptManager: receiptManager, accountStore: accountStore)
            } else {
                FeatureLockedView(
                    subscriptionManager: subscriptionManager,
                    featureName: "Receipt Management",
                    featureDescription: "Access unlimited receipt storage and smart organization",
                    featureIcon: "doc.text.image"
                )
            }
        }
        .sheet(isPresented: $showingAIInsights) {
            if subscriptionManager.canAccessAIInsights() {
                EnhancedAIInsightsView(
                        accountStore: accountStore,
                        subscriptionManager: subscriptionManager
                    )
            } else {
                FeatureLockedView(
                    subscriptionManager: subscriptionManager,
                    featureName: "AI Insights",
                    featureDescription: "Get personalized spending analysis and smart recommendations",
                    featureIcon: "brain.head.profile"
                )
            }
        }
        .sheet(isPresented: $subscriptionManager.showingPaywall) {
            PaywallView(subscriptionManager: subscriptionManager)
                .onAppear {
                    usageAnalytics.trackPaywallShow(trigger: "various")
                }
        }
        .fullScreenCover(isPresented: $showingInterstitialAd) {
            InterstitialAdView(
                subscriptionManager: subscriptionManager,
                adManager: adManager
            )
        }
        // NEW: Viral Sheets
        .sheet(isPresented: $showingViralHub) {
            ViralHubView()
                .environmentObject(viralManager)
        }
        .sheet(isPresented: $showingQuickMeme) {
            QuickMemeGeneratorView(
                netWorth: accountStore.netWorth(),
                totalDebt: accountStore.totalDebt(),
                totalAssets: accountStore.totalAssets()
            )
        }
        .sheet(isPresented: $showingShareWin) {
            ShareWinView(
                accountStore: accountStore,
                viralManager: viralManager
            )
        }
        .alert("Delete Account", isPresented: $showingDeleteAlert) {
            Button("Cancel", role: .cancel) {
                accountToDelete = nil
            }
            Button("Delete", role: .destructive) {
                if let account = accountToDelete {
                    accountStore.deleteAccount(account)
                    accountToDelete = nil
                    adManager.incrementActionCount()
                }
            }
        } message: {
            if let account = accountToDelete {
                Text("Are you sure you want to delete '\(account.name)'? This will delete all \(account.transactions.count) transactions in this account. This action cannot be undone.")
            }
        }
    }
    
    // MARK: - NEW: Viral Features
    
    private var shouldShowViralCommentary: Bool {
        // Show viral commentary if user has debt, very low assets, or interesting financial situation
        return accountStore.netWorth() < 0 ||
               accountStore.totalAssets() < 1000 ||
               accountStore.totalDebt() > 5000 ||
               accountStore.accounts.count >= 2
    }
    
    private var viralCommentarySection: some View {
        VStack(spacing: 8) {
            HStack(alignment: .top, spacing: 8) {
                // Potato mascot
                Text("🥔")
                    .font(.title3)
                
                // Comment bubble
                VStack(alignment: .leading, spacing: 6) {
                    Text(generateViralComment())
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.leading)
                    
                    // Action buttons
//                    HStack(spacing: 8) {
//                        Button("Create Meme") {
//                            showingQuickMeme = true
//                        }
//                        .font(.caption)
//                        .buttonStyle(.bordered)
//
//                        Button("Share Journey") {
//                            showingShareWin = true
//                        }
//                        .font(.caption)
//                        .buttonStyle(.borderedProminent)
//
//                        Spacer()
//
//                        Button("More Viral") {
//                            showingViralHub = true
//                        }
//                        .font(.caption)
//                        .foregroundColor(.orange)
//                    }
                }
                
                Spacer()
            }
            .padding(12)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(.secondarySystemBackground))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.orange.opacity(0.3), lineWidth: 1)
                    )
            )
        }
        .padding(.horizontal)
    }
    
    private func generateViralComment() -> String {
        let netWorth = accountStore.netWorth()
        let debt = accountStore.totalDebt()
        let assets = accountStore.totalAssets()
        
        if netWorth < -10000 {
            return "This debt era is about to become the most epic comeback story 🥔✨"
        } else if netWorth < 0 {
            return "POV: You're about to have the best financial glow-up of 2025 💪"
        } else if assets < 500 {
            return "Small steps, big dreams! Your financial journey is just getting started 🌱"
        } else if debt > 5000 {
            return "Not me documenting this entire debt-free journey for TikTok 📱"
        } else {
            return "Your financial transformation arc is about to be ICONIC 👑"
        }
    }
    
    // MARK: - UPDATED: Quick Actions with Viral Features
    
    private var monetizedQuickActionsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Quick Actions")
                    .font(.headline)
                
                Spacer()
                
                // FIXED: Only show "Upgrade for More" for free users
                if !isProUser {
                    Button("Upgrade for More") {
                        subscriptionManager.showingPaywall = true
                    }
                    .font(.caption)
                    .foregroundColor(.blue)
                }
            }
            .padding(.horizontal)
            
            VStack(spacing: 12) {
                HStack(spacing: 12) {
                    MonetizedQuickActionButton(
                        title: "Add Transaction",
                        icon: "plus.square.fill",
                        color: .green,
                        isLocked: false,
                        action: {
                            showingQuickAddTransaction = true
                            usageAnalytics.trackFeatureUsage("add_transaction")
                        }
                    )
                    
                    // FIXED: Always show lock icon for non-Pro users
                    MonetizedQuickActionButton(
                        title: "Scan Receipt",
                        icon: isProUser ? "camera.viewfinder" : "lock.fill",
                        color: isProUser ? .orange : .gray,
                        isLocked: !isProUser,
                        action: {
                            if subscriptionManager.canAccessReceiptScanning() {
                                showingScanReceipt = true
                            } else {
                                subscriptionManager.showPaywallIfNeeded(for: .receiptScanning)
                            }
                            usageAnalytics.trackFeatureUsage("scan_receipt")
                        }
                    )
                }
                
                HStack(spacing: 12) {
                    MonetizedQuickActionButton(
                        title: "Add Account",
                        icon: subscriptionManager.canAddAccount(currentAccountCount: accountStore.accounts.count) ? "plus.circle.fill" : "lock.fill",
                        color: subscriptionManager.canAddAccount(currentAccountCount: accountStore.accounts.count) ? .blue : .gray,
                        isLocked: !subscriptionManager.canAddAccount(currentAccountCount: accountStore.accounts.count),
                        action: {
                            if subscriptionManager.canAddAccount(currentAccountCount: accountStore.accounts.count) {
                                showingAddAccount = true
                            } else {
                                subscriptionManager.showPaywallIfNeeded(for: .addAccount(currentCount: accountStore.accounts.count))
                            }
                            usageAnalytics.trackFeatureUsage("add_account")
                        }
                    )
                    
                    MonetizedQuickActionButton(
                        title: "Transfer Money",
                        icon: "arrow.left.arrow.right.circle.fill",
                        color: .purple,
                        isLocked: false,
                        action: {
                            showingAddTransfer = true
                            usageAnalytics.trackFeatureUsage("transfer_money")
                        }
                    )
                }
                
                HStack(spacing: 12) {
                    // FIXED: Always show lock icon for non-Pro users
                    MonetizedQuickActionButton(
                        title: "AI Insights",
                        icon: isProUser ? "brain.head.profile" : "lock.fill",
                        color: isProUser ? .purple : .gray,
                        isLocked: !isProUser,
                        action: {
                            if subscriptionManager.canAccessAIInsights() {
                                showingAIInsights = true
                            } else {
                                subscriptionManager.showPaywallIfNeeded(for: .aiInsights)
                            }
                            usageAnalytics.trackFeatureUsage("ai_insights")
                        }
                    )
                    
                    MonetizedQuickActionButton(
                        title: "View Reports",
                        icon: isProUser ? "chart.bar.fill" : "lock.fill",
                        color: isProUser ? .cyan : .gray,
                        isLocked: !isProUser,
                        action: {
                            showingReports = true
                            usageAnalytics.trackFeatureUsage("view_reports")
                            
                            // Show interstitial ad for free users
                            if !isProUser {
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                                    showingInterstitialAd = true
                                }
                            }
                        }
                    )
                }
                
                // NEW: Viral Actions Row
//                HStack(spacing: 12) {
//                    MonetizedQuickActionButton(
//                        title: "Create Meme",
//                        icon: "🎭",
//                        color: .purple,
//                        isLocked: false,
//                        action: {
//                            showingQuickMeme = true
//                            usageAnalytics.trackFeatureUsage("create_meme")
//                        }
//                    )
//
//                    MonetizedQuickActionButton(
//                        title: "Share Win",
//                        icon: "🔥",
//                        color: .orange,
//                        isLocked: false,
//                        action: {
//                            showingShareWin = true
//                            usageAnalytics.trackFeatureUsage("share_win")
//                        }
//                    )
//                }
            }
            .padding(.horizontal)
        }
    }
    
    // MARK: - Existing sections (unchanged)
    // ... [All your existing code for financialOverviewSection, duePaymentsAlert, accountsSection, etc.]
    
    // MARK: - Financial Overview Section
    
    private var financialOverviewSection: some View {
        VStack(spacing: 12) {
            VStack(spacing: 8) {
                HStack {
                    Text("Net Worth")
                        .font(.headline)
                        .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    if isProUser {
                        HStack {
                            Image(systemName: "crown.fill")
                                .foregroundColor(.orange)
                                .font(.caption)
                            Text("Pro")
                                .font(.caption)
                                .fontWeight(.medium)
                                .foregroundColor(.orange)
                        }
                        .padding(.horizontal, 8)
                        .padding(.vertical, 2)
                        .background(Color.orange.opacity(0.1))
                        .clipShape(Capsule())
                    }
                }
                
                Text(currencyManager.formatAmount(accountStore.netWorth()))
                    .font(.system(size: 32, weight: .bold, design: .rounded))
                    .foregroundColor(accountStore.netWorth() >= 0 ? .green : .red)
            }
            
            // Show financial breakdown if there's debt
            if accountStore.hasDebt() || accountStore.hasAssets() {
                financialBreakdownView
            }
            
            // Financial health indicator
            if accountStore.hasAssets() || accountStore.hasDebt() {
                financialHealthView
            }
        }
        .padding(.top, 20)
    }
    
    // MARK: - Helper Views (Same as before)
    
    private var duePaymentsAlert: some View {
        VStack(spacing: 12) {
            HStack {
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundColor(.orange)
                Text("You have \(duePayments.count) payment(s) due")
                    .font(.headline)
                    .foregroundColor(.primary)
                Spacer()
            }
            
            Button(action: { showingDuePayments = true }) {
                Text("Review Due Payments")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.orange)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            }
        }
        .padding()
        .background(Color.orange.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .padding(.horizontal)
    }
    
    private var accountsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Accounts")
                    .font(.title2)
                    .fontWeight(.semibold)
                
                Spacer()
                
                Button(action: {
                    if subscriptionManager.canAddAccount(currentAccountCount: accountStore.accounts.count) {
                        showingAddAccount = true
                    } else {
                        subscriptionManager.showPaywallIfNeeded(for: .addAccount(currentCount: accountStore.accounts.count))
                    }
                }) {
                    HStack {
                        Image(systemName: subscriptionManager.canAddAccount(currentAccountCount: accountStore.accounts.count) ? "plus.circle.fill" : "lock.fill")
                            .font(.title2)
                        Text("Add")
                    }
                    .foregroundColor(subscriptionManager.canAddAccount(currentAccountCount: accountStore.accounts.count) ? .blue : .gray)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background((subscriptionManager.canAddAccount(currentAccountCount: accountStore.accounts.count) ? Color.blue : Color.gray).opacity(0.1))
                    .clipShape(Capsule())
                }
            }
            .padding(.horizontal)
            
            if accountStore.accounts.isEmpty {
                // Empty state
                VStack(spacing: 12) {
                    Image(systemName: "creditcard")
                        .font(.system(size: 50))
                        .foregroundColor(.secondary)
                    
                    Text("No Accounts Yet")
                        .font(.headline)
                        .foregroundColor(.secondary)
                    
                    Text("Tap the 'Add' button to add your first account")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 40)
            } else {
                // Account cards with ads between them ONLY for free users
                VStack(alignment: .leading, spacing: 12) {
                    // Debit accounts (Assets)
                    let debitAccounts = accountStore.accounts.filter { $0.accountType == .debit }
                    if !debitAccounts.isEmpty {
                        assetsSection(debitAccounts)
                    }
                    
                    // FIXED: Native ad between account sections ONLY for free users
                    if !isProUser && !debitAccounts.isEmpty {
                        NativeAdCard(
                            subscriptionManager: subscriptionManager,
                            adManager: adManager
                        )
                        .padding(.horizontal)
                    }
                    
                    // Credit accounts (Liabilities)
                    let creditAccounts = accountStore.accounts.filter { $0.accountType == .credit }
                    if !creditAccounts.isEmpty {
                        creditCardsSection(creditAccounts)
                    }
                }
            }
        }
    }
    
    private func assetsSection(_ debitAccounts: [Account]) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Assets")
                    .font(.headline)
                    .foregroundColor(.green)
                Spacer()
                Text(currencyManager.formatAmount(accountStore.totalAssets()))
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(.green)
            }
            .padding(.horizontal)
            
            LazyVStack(spacing: 8) {
                ForEach(debitAccounts) { account in
                    NavigationLink(destination: AccountDetailView(account: account, accountStore: accountStore)) {
                        AccountCardView(account: account)
                            .contextMenu {
                                Button(action: { editAccount(account) }) {
                                    Label("Edit Account", systemImage: "pencil")
                                }
                                Button(action: { deleteAccount(account) }) {
                                    Label("Delete Account", systemImage: "trash")
                                }
                            }
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
            .padding(.horizontal)
        }
    }
    
    private func creditCardsSection(_ creditAccounts: [Account]) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Credit Cards")
                    .font(.headline)
                    .foregroundColor(.orange)
                Spacer()
                if accountStore.totalDebt() > 0 {
                    Text("\(currencyManager.formatAmount(accountStore.totalDebt())) debt")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(.red)
                } else {
                    Text("\(currencyManager.formatAmount(accountStore.totalAvailableCredit())) available")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(.green)
                }
            }
            .padding(.horizontal)
            
            LazyVStack(spacing: 8) {
                ForEach(creditAccounts) { account in
                    NavigationLink(destination: AccountDetailView(account: account, accountStore: accountStore)) {
                        AccountCardView(account: account)
                            .contextMenu {
                                Button(action: { editAccount(account) }) {
                                    Label("Edit Account", systemImage: "pencil")
                                }
                                Button(action: { deleteAccount(account) }) {
                                    Label("Delete Account", systemImage: "trash")
                                }
                            }
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
            .padding(.horizontal)
        }
    }
    
    private var financialBreakdownView: some View {
        HStack(spacing: 20) {
            if accountStore.hasAssets() {
                VStack(spacing: 4) {
                    Text("Assets")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text(currencyManager.formatAmount(accountStore.totalAssets()))
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(.green)
                }
            }
            
            if accountStore.hasDebt() {
                VStack(spacing: 4) {
                    Text("Debt")
                        .font(.caption)
                        .foregroundColor(.secondary)
                      Text(currencyManager.formatAmount(accountStore.totalDebt()))
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(.red)
                }
            }
            
            if accountStore.totalAvailableCredit() > 0 {
                VStack(spacing: 4) {
                    Text("Available Credit")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text(currencyManager.formatAmount(accountStore.totalAvailableCredit()))
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(.blue)
                }
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
    
    private var financialHealthView: some View {
        let healthScore = accountStore.financialHealthScore()
        return HStack {
            Text("Financial Health")
                .font(.caption)
                .foregroundColor(.secondary)
            
            Spacer()
            
            Text("\(Int(healthScore))%")
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundColor(healthScore >= 70 ? .green : healthScore >= 40 ? .orange : .red)
        }
        .padding(.horizontal)
    }
    
    // MARK: - Account Management Methods
    private func editAccount(_ account: Account) {
        accountToEdit = account
        showingEditAccount = true
    }
    
    private func deleteAccount(_ account: Account) {
        accountToDelete = account
        showingDeleteAlert = true
    }
}

// MARK: - NEW: Quick Meme Generator with Real Data
struct QuickMemeGeneratorView: View {
    let netWorth: Double
    let totalDebt: Double
    let totalAssets: Double
    
    @Environment(\.dismiss) private var dismiss
    @State private var selectedTemplate = 0
    @State private var generatedMeme: UIImage?
    
    private var quickTemplates: [QuickMemeTemplate] {
        return [
            QuickMemeTemplate(
                title: "Net Worth Reality",
                topText: "My net worth: \(formatCurrency(netWorth))",
                bottomText: netWorth < 0 ? "My confidence: Priceless 💪" : "Living my best life 🥔"
            ),
            QuickMemeTemplate(
                title: "Debt Journey",
                topText: totalDebt > 0 ? "Debt: \(formatCurrency(totalDebt))" : "Me: Debt-free",
                bottomText: totalDebt > 0 ? "CashPotato helping me climb out 🥔" : "CashPotato keeping me here 👑"
            ),
            QuickMemeTemplate(
                title: "Financial Glow Up",
                topText: "Current financial status:",
                bottomText: "Glow up in progress... 📈🥔"
            ),
            QuickMemeTemplate(
                title: "Budget Bestie",
                topText: "CashPotato watching my spending:",
                bottomText: "\"Bestie, we need to talk\" 👀"
            )
        ]
    }
    
    private func formatCurrency(_ amount: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.maximumFractionDigits = 0
        return formatter.string(from: NSNumber(value: abs(amount))) ?? "$0"
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                // Quick template selector
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(Array(quickTemplates.enumerated()), id: \.offset) { index, template in
                            QuickTemplateCard(
                                template: template,
                                isSelected: selectedTemplate == index
                            ) {
                                selectedTemplate = index
                            }
                        }
                    }
                    .padding(.horizontal)
                }
                
                // Meme preview
                VStack {
                    ZStack {
                        RoundedRectangle(cornerRadius: 16)
                            .fill(
                                LinearGradient(
                                    colors: [.orange.opacity(0.3), .yellow.opacity(0.2)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(height: 300)
                        
                        VStack {
                            Text(quickTemplates[selectedTemplate].topText)
                                .font(.headline)
                                .fontWeight(.bold)
                                .foregroundColor(.white)
                                .shadow(color: .black, radius: 2)
                                .multilineTextAlignment(.center)
                            
                            Spacer()
                            
                            Text("🥔")
                                .font(.system(size: 60))
                            
                            Spacer()
                            
                            Text(quickTemplates[selectedTemplate].bottomText)
                                .font(.headline)
                                .fontWeight(.bold)
                                .foregroundColor(.white)
                                .shadow(color: .black, radius: 2)
                                .multilineTextAlignment(.center)
                        }
                        .padding()
                    }
                }
                .padding(.horizontal)
                
                // Action buttons
                HStack(spacing: 16) {
                    Button("Share to TikTok") {
                        shareMeme(platform: .tiktok)
                    }
                    .buttonStyle(.borderedProminent)
                    
                    Button("Share to Instagram") {
                        shareMeme(platform: .instagram)
                    }
                    .buttonStyle(.bordered)
                }
                
                Spacer()
            }
            .navigationTitle("Quick Meme")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Done") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Full Editor") {
                        // Open full meme generator
                    }
                }
            }
        }
    }
    
    private func shareMeme(platform: SocialPlatform) {
        let shareText = "\(quickTemplates[selectedTemplate].topText) \(quickTemplates[selectedTemplate].bottomText) Made with #CashPotato 🥔💰"
        
        let activityVC = UIActivityViewController(
            activityItems: [shareText],
            applicationActivities: nil
        )
        
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let window = windowScene.windows.first {
            window.rootViewController?.present(activityVC, animated: true)
        }
        
        dismiss()
    }
}

// MARK: - NEW: Share Win View
struct ShareWinView: View {
    let accountStore: AccountStore
    let viralManager: ViralContentManager
    
    @Environment(\.dismiss) private var dismiss
    @State private var selectedWinType = WinType.netWorthProgress
    
    enum WinType: CaseIterable {
        case netWorthProgress, debtPaydown, savingsGoal, budgetSuccess
        
        var title: String {
            switch self {
            case .netWorthProgress: return "Net Worth Progress"
            case .debtPaydown: return "Debt Paydown"
            case .savingsGoal: return "Savings Goal"
            case .budgetSuccess: return "Budget Success"
            }
        }
        
        var icon: String {
            switch self {
            case .netWorthProgress: return "📈"
            case .debtPaydown: return "💪"
            case .savingsGoal: return "💰"
            case .budgetSuccess: return "🎯"
            }
        }
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                Text("Share Your Financial Win!")
                    .font(.title2)
                    .fontWeight(.bold)
                    .padding()
                
                // Win type selector
                VStack(spacing: 12) {
                    ForEach(WinType.allCases, id: \.self) { winType in
                        WinTypeCard(
                            winType: winType,
                            isSelected: selectedWinType == winType,
                            accountStore: accountStore
                        ) {
                            selectedWinType = winType
                        }
                    }
                }
                .padding(.horizontal)
                
                Spacer()
                
                // Share button
                Button("Create & Share") {
                    createWinPost()
                }
                .buttonStyle(.borderedProminent)
                .font(.headline)
                .padding(.horizontal)
            }
            .navigationTitle("Share Win")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
    }
    
    private func createWinPost() {
        let shareText = generateWinText(for: selectedWinType)
        
        let activityVC = UIActivityViewController(
            activityItems: [shareText],
            applicationActivities: nil
        )
        
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let window = windowScene.windows.first {
            window.rootViewController?.present(activityVC, animated: true)
        }
        
        dismiss()
    }
    
    private func generateWinText(for winType: WinType) -> String {
        switch winType {
        case .netWorthProgress:
            if accountStore.netWorth() < 0 {
                return "Day 1 of my debt-free journey with CashPotato! Currently at \(formatCurrency(accountStore.netWorth())) but the only way is up! 🥔💪 #DebtFreeJourney #CashPotato"
            } else {
                return "Financial progress update: Net worth at \(formatCurrency(accountStore.netWorth()))! CashPotato keeping me on track 🥔📈 #FinancialGrowth #CashPotato"
            }
        case .debtPaydown:
            return "Paying down debt one payment at a time! \(formatCurrency(accountStore.totalDebt())) to go but CashPotato's got my back 🥔💪 #DebtFree #CashPotato"
        case .savingsGoal:
            return "Building my financial future \(formatCurrency(accountStore.totalAssets())) at a time! Small wins, big energy 🥔✨ #SavingsWin #CashPotato"
        case .budgetSuccess:
            return "Successfully tracking my finances with CashPotato! Knowledge is power 🥔📊 #BudgetLife #CashPotato"
        }
    }
    
    private func formatCurrency(_ amount: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.maximumFractionDigits = 0
        return formatter.string(from: NSNumber(value: abs(amount))) ?? "$0"
    }
}

// MARK: - Supporting Views
struct QuickMemeTemplate {
    let title: String
    let topText: String
    let bottomText: String
}

struct QuickTemplateCard: View {
    let template: QuickMemeTemplate
    let isSelected: Bool
    let onSelect: () -> Void
    
    var body: some View {
        VStack(spacing: 8) {
            RoundedRectangle(cornerRadius: 8)
                .fill(isSelected ? Color.orange.opacity(0.3) : Color.gray.opacity(0.2))
                .frame(width: 80, height: 80)
                .overlay(
                    Text("🥔")
                        .font(.title)
                )
            
            Text(template.title)
                .font(.caption)
                .fontWeight(.medium)
                .multilineTextAlignment(.center)
        }
        .frame(width: 100)
        .onTapGesture {
            onSelect()
        }
    }
}

struct WinTypeCard: View {
    let winType: ShareWinView.WinType
    let isSelected: Bool
    let accountStore: AccountStore
    let onSelect: () -> Void
    
    var body: some View {
        Button(action: onSelect) {
            HStack {
                Text(winType.icon)
                    .font(.title2)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(winType.title)
                        .font(.headline)
                        .fontWeight(.semibold)
                    
                    Text(getPreviewText())
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.blue)
                }
            }
            .padding()
            .background(isSelected ? Color.blue.opacity(0.1) : Color(.secondarySystemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? Color.blue : Color.clear, lineWidth: 2)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private func getPreviewText() -> String {
        switch winType {
        case .netWorthProgress:
            return "Share your net worth journey"
        case .debtPaydown:
            return "Celebrate debt reduction progress"
        case .savingsGoal:
            return "Show off your savings wins"
        case .budgetSuccess:
            return "Share budget tracking success"
        }
    }
}

enum SocialPlatform {
    case tiktok, instagram, twitter
}

// MARK: - FIXED: Monetized Quick Action Button with Dark Mode Support (unchanged)

struct MonetizedQuickActionButton: View {
    let title: String
    let icon: String
    let color: Color
    let isLocked: Bool
    let action: () -> Void
    
    @Environment(\.colorScheme) private var colorScheme
    
    private var buttonBackgroundColor: Color {
        if colorScheme == .dark {
            return Color(.systemGray6)
        } else {
            return Color(.systemBackground)
        }
    }
    
    private var borderColor: Color {
        if colorScheme == .dark {
            if isLocked {
                return Color.orange.opacity(0.5)
            } else {
                return Color(.systemGray4)
            }
        } else {
            if isLocked {
                return Color.orange.opacity(0.3)
            } else {
                return Color.clear
            }
        }
    }
    
    private var shadowColor: Color {
        if colorScheme == .dark {
            return Color.clear
        } else {
            return Color.black.opacity(0.05)
        }
    }
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                ZStack {
                    Text(icon.contains("🎭") || icon.contains("🔥") ? icon : "")
                        .font(.title2)
                    
                    if !icon.contains("🎭") && !icon.contains("🔥") {
                        Image(systemName: icon)
                            .font(.title2)
                            .foregroundColor(isLocked ? .gray : color)
                    }
                    
                    // FIXED: Only show lock overlay if feature is locked
                    if isLocked {
                        Image(systemName: "lock.fill")
                            .font(.caption)
                            .foregroundColor(.white)
                            .background(
                                Circle()
                                    .fill(Color.orange)
                                    .frame(width: 16, height: 16)
                            )
                            .offset(x: 8, y: -8)
                    }
                }
                
                Text(title)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(isLocked ? .gray : .primary)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(buttonBackgroundColor)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .shadow(color: shadowColor, radius: 4, x: 0, y: 1)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(borderColor, lineWidth: colorScheme == .dark ? 1 : (isLocked ? 1 : 0))
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

#Preview {
    HomeView()
}
