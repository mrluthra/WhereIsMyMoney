import SwiftUI

struct HomeView: View {
    @StateObject private var accountStore = AccountStore()
    @StateObject private var recurringStore = RecurringPaymentStore()
    @StateObject private var authManager = AuthenticationManager()
    @StateObject private var receiptManager = ReceiptManager()
    
    // MARK: - Monetization Objects
    @StateObject private var subscriptionManager = SubscriptionManager()
    @StateObject private var adManager = AdManager()
    @StateObject private var usageAnalytics = UsageAnalytics.shared
    
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
            
            // Process any due payments when app launches
            let processedTransactions = recurringStore.checkAndProcessDuePayments()
            
            // Add processed transactions to their respective accounts
            for transaction in processedTransactions {
                accountStore.addTransaction(transaction, to: transaction.accountId)
            }
            
            // Track app open
            usageAnalytics.trackAppOpen()
        }
        .onReceive(NotificationCenter.default.publisher(for: UIApplication.willEnterForegroundNotification)) { _ in
            // Re-authenticate when app comes to foreground
            if authManager.authenticationMethod != .none {
                authManager.lockApp()
                authManager.authenticateUser()
            }
        }
    }
    
    private var mainContent: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // Header with financial overview
                    financialOverviewSection
                    
                    // FIXED: Subscription status banner ONLY for free users
                    if !isProUser {
                        PromotionalBannerView(subscriptionManager: subscriptionManager)
                            .padding(.horizontal)
                    }
                    
                    // Due Payments Alert
                    if !duePayments.isEmpty {
                        duePaymentsAlert
                    }
                    
                    // FIXED: Quick Actions (Monetized) - No "Upgrade for More" for Pro users
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
            .navigationTitle("WhereIsMyMoney")
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
                    HStack(spacing: 16) {
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
                //AIInsightsView(accountStore: accountStore)
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
    
    // MARK: - FIXED: Monetized Quick Actions Section
    
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
            }
            .padding(.horizontal)
        }
    }
    
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
                
                Text("$\(accountStore.netWorth(), specifier: "%.2f")")
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
                Text("$\(accountStore.totalAssets(), specifier: "%.2f")")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(.green)
            }
            .padding(.horizontal)
            
            LazyVStack(spacing: 8) {
                ForEach(Array(debitAccounts.enumerated()), id: \.element.id) { index, account in
                    VStack(spacing: 0) {
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
                        
                        // FIXED: Show ad every 2 accounts ONLY for free users
                        if index == 1 && !isProUser && debitAccounts.count > 2 {
                            AdBannerView(
                                subscriptionManager: subscriptionManager,
                                adManager: adManager,
                                placement: .accountDetailBanner
                            )
                            .padding(.top, 8)
                        }
                    }
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
                    Text("$\(accountStore.totalDebt(), specifier: "%.2f") debt")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(.red)
                } else {
                    Text("$\(accountStore.totalAvailableCredit(), specifier: "%.2f") available")
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
                    Text("$\(accountStore.totalAssets(), specifier: "%.2f")")
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
                    Text("$\(accountStore.totalDebt(), specifier: "%.2f")")
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
                    Text("$\(accountStore.totalAvailableCredit(), specifier: "%.2f")")
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

// MARK: - FIXED: Monetized Quick Action Button with Dark Mode Support

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
                    Image(systemName: icon)
                        .font(.title2)
                        .foregroundColor(isLocked ? .gray : color)
                    
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
