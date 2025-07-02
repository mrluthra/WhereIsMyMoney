import SwiftUI

struct HomeView: View {
    @StateObject private var accountStore = AccountStore()
    @StateObject private var recurringStore = RecurringPaymentStore()
    @StateObject private var authManager = AuthenticationManager()
    @StateObject private var receiptManager = ReceiptManager()
    @EnvironmentObject var currencyManager: CurrencyManager
    
    // MARK: - Environment and Device Detection
    @Environment(\.horizontalSizeClass) var horizontalSizeClass
    @Environment(\.verticalSizeClass) var verticalSizeClass
    @Environment(\.colorScheme) var colorScheme
    
    // MARK: - Monetization Objects
    @StateObject private var subscriptionManager = SubscriptionManager()
    @StateObject private var adManager = AdManager()
    @StateObject private var usageAnalytics = UsageAnalytics.shared
    
    // MARK: - Viral Features
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
    
    // iPad specific states
    @State private var selectedSidebarItem: SidebarItem? = .dashboard
    @State private var columnVisibility = NavigationSplitViewVisibility.automatic
    
    enum SidebarItem: CaseIterable, Identifiable {
        case dashboard, accounts, transactions, reports, settings
        
        var id: Self { self }
        
        var title: String {
            switch self {
            case .dashboard: return "Dashboard"
            case .accounts: return "Accounts"
            case .transactions: return "Transactions"
            case .reports: return "Reports"
            case .settings: return "Settings"
            }
        }
        
        var icon: String {
            switch self {
            case .dashboard: return "house.fill"
            case .accounts: return "creditcard.fill"
            case .transactions: return "list.bullet"
            case .reports: return "chart.bar.fill"
            case .settings: return "gear"
            }
        }
    }
    
    private var duePayments: [RecurringPayment] {
        recurringStore.getDuePayments()
    }
    
    private var isProUser: Bool {
        #if DEBUG
        return subscriptionManager.isSubscribed || (subscriptionManager.isDevelopmentMode && subscriptionManager.mockProStatus)
        #else
        return subscriptionManager.isSubscribed
        #endif
    }
    
    // iPad detection
    private var isIPad: Bool {
        UIDevice.current.userInterfaceIdiom == .pad
    }
    
    // Compact layout detection
    private var isCompactLayout: Bool {
        horizontalSizeClass == .compact || verticalSizeClass == .compact
    }
    
    var body: some View {
        ZStack {
            if authManager.shouldShowAuthentication() {
                authenticationView
            } else {
                if isIPad && !isCompactLayout {
                    iPadSplitView
                } else {
                    iPhoneNavigationView
                }
            }
        }
        .animation(.easeInOut(duration: 0.3), value: authManager.isAuthenticated)
        .onAppear {
            setupApp()
        }
        .onReceive(NotificationCenter.default.publisher(for: UIApplication.willEnterForegroundNotification)) { _ in
            handleForegroundReturn()
        }
        // MARK: - All Sheets (moved here from extension)
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
    
    // MARK: - Authentication View
    private var authenticationView: some View {
        Group {
            if authManager.showingPasscodeEntry {
                PasscodeEntryView(authManager: authManager)
                    .transition(.opacity)
            } else {
                Color.black
                    .ignoresSafeArea()
                    .onAppear {
                        authManager.authenticateUser()
                    }
            }
        }
    }
    
    // MARK: - iPad Split View Layout
    private var iPadSplitView: some View {
        NavigationSplitView(columnVisibility: $columnVisibility) {
            iPadSidebar
        } detail: {
            iPadDetailView
        }
        .navigationSplitViewStyle(.balanced)
    }
    
    private var iPadSidebar: some View {
        List(SidebarItem.allCases, selection: $selectedSidebarItem) { item in
            NavigationLink(value: item) {
                Label(item.title, systemImage: item.icon)
            }
        }
        .navigationTitle("CashPotato")
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Menu {
                    Button("Add Account") { handleAddAccount() }
                    Button("Add Transaction") { showingQuickAddTransaction = true }
                    Button("Scan Receipt") { handleReceiptScanning() }
                } label: {
                    Image(systemName: "plus")
                }
            }
        }
    }
    
    private var iPadDetailView: some View {
        Group {
            switch selectedSidebarItem ?? .dashboard {
            case .dashboard:
                iPadDashboardView
            case .accounts:
                iPadAccountsView
            case .transactions:
                iPadTransactionsView
            case .reports:
                iPadReportsView
            case .settings:
                iPadSettingsView
            }
        }
        .navigationBarTitleDisplayMode(.large)
    }
    
    // MARK: - iPhone Navigation View
    private var iPhoneNavigationView: some View {
        NavigationView {
            mainContent
        }
        .navigationViewStyle(StackNavigationViewStyle())
    }
    
    // MARK: - Main Content (iPhone Layout)
    private var mainContent: some View {
        ScrollView {
            LazyVStack(spacing: 20) {
                // Header with financial overview
                financialOverviewSection
                
                // Subscription status banner ONLY for free users
                if !isProUser {
                    PromotionalBannerView(subscriptionManager: subscriptionManager)
                        .padding(.horizontal)
                }
                
                // Due Payments Alert
                if !duePayments.isEmpty {
                    duePaymentsAlert
                }
                
                // Quick Actions (Monetized)
                monetizedQuickActionsSection
                
                // Ad Banner ONLY for free users
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
                    Button(action: { handleAIInsights() }) {
                        Image(systemName: isProUser ? "brain.head.profile" : "lock.fill")
                            .font(.title3)
                            .foregroundColor(isProUser ? .purple : .gray)
                    }
                    
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
                    
                    Button(action: {
                        showingManageCategories = true
                        usageAnalytics.trackFeatureUsage("categories_tap")
                    }) {
                        Image(systemName: "tag.circle")
                            .font(.title3)
                            .foregroundColor(.orange)
                    }
                    
                    Button(action: { showingSettings = true }) {
                        Image(systemName: "gear")
                            .font(.title3)
                            .foregroundColor(.blue)
                    }
                }
            }
        }
    }
    
    // MARK: - iPad Dashboard View
    private var iPadDashboardView: some View {
        ScrollView {
            LazyVGrid(columns: [
                GridItem(.flexible(), spacing: 20),
                GridItem(.flexible(), spacing: 20)
            ], spacing: 20) {
                // Financial Overview Card
                VStack(alignment: .leading, spacing: 16) {
                    HStack {
                        Text("Financial Overview")
                            .font(.headline)
                            .fontWeight(.semibold)
                        
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
                    
                    VStack(spacing: 12) {
                        HStack {
                            Text("Net Worth")
                            Spacer()
                            Text(currencyManager.formatAmount(accountStore.netWorth()))
                                .fontWeight(.semibold)
                                .foregroundColor(accountStore.netWorth() >= 0 ? .green : .red)
                        }
                        
                        HStack {
                            Text("Total Assets")
                            Spacer()
                            Text(currencyManager.formatAmount(accountStore.totalAssets()))
                                .fontWeight(.semibold)
                                .foregroundColor(.blue)
                        }
                        
                        HStack {
                            Text("Total Debt")
                            Spacer()
                            Text(currencyManager.formatAmount(accountStore.totalDebt()))
                                .fontWeight(.semibold)
                                .foregroundColor(.red)
                        }
                    }
                    .font(.subheadline)
                }
                .padding()
                .background(Color(.systemBackground))
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
                
                // Quick Actions Card
                VStack(alignment: .leading, spacing: 16) {
                    Text("Quick Actions")
                        .font(.headline)
                        .fontWeight(.semibold)
                    
                    LazyVGrid(columns: [
                        GridItem(.flexible()),
                        GridItem(.flexible()),
                        GridItem(.flexible())
                    ], spacing: 12) {
                        iPadQuickActionButton(title: "Add Transaction", icon: "plus.square.fill", color: .green) {
                            showingQuickAddTransaction = true
                            usageAnalytics.trackFeatureUsage("add_transaction")
                        }
                        
                        iPadQuickActionButton(
                            title: "Scan Receipt",
                            icon: isProUser ? "camera.viewfinder" : "lock.fill",
                            color: isProUser ? .orange : .gray,
                            isLocked: !isProUser
                        ) {
                            handleReceiptScanning()
                        }
                        
                        iPadQuickActionButton(
                            title: "Add Account",
                            icon: subscriptionManager.canAddAccount(currentAccountCount: accountStore.accounts.count) ? "plus.circle.fill" : "lock.fill",
                            color: subscriptionManager.canAddAccount(currentAccountCount: accountStore.accounts.count) ? .blue : .gray,
                            isLocked: !subscriptionManager.canAddAccount(currentAccountCount: accountStore.accounts.count)
                        ) {
                            handleAddAccount()
                        }
                        
                        iPadQuickActionButton(
                            title: "AI Insights",
                            icon: isProUser ? "brain.head.profile" : "lock.fill",
                            color: isProUser ? .purple : .gray,
                            isLocked: !isProUser
                        ) {
                            handleAIInsights()
                        }
                        
                        iPadQuickActionButton(title: "Reports", icon: isProUser ? "chart.bar.fill" : "lock.fill", color: isProUser ? .indigo : .gray, isLocked: !isProUser) {
                            selectedSidebarItem = .reports
                        }
                        
                        iPadQuickActionButton(title: "Settings", icon: "gear", color: .gray) {
                            selectedSidebarItem = .settings
                        }
                    }
                }
                .padding()
                .background(Color(.systemBackground))
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
                
                // Due Payments Card (if any)
                if !duePayments.isEmpty {
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Due Payments")
                            .font(.headline)
                            .fontWeight(.semibold)
                        
                        ForEach(duePayments.prefix(3), id: \.id) { payment in
                            HStack {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(payment.name)
                                        .font(.subheadline)
                                        .fontWeight(.medium)
                                    Text("Due: \(payment.nextDueDate, style: .date)")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                                Spacer()
                                Text(currencyManager.formatAmount(payment.amount))
                                    .font(.subheadline)
                                    .fontWeight(.semibold)
                                    .foregroundColor(.red)
                            }
                        }
                        
                        if duePayments.count > 3 {
                            Button("View All Due Payments") {
                                showingDuePayments = true
                            }
                            .font(.caption)
                            .foregroundColor(.blue)
                        }
                    }
                    .padding()
                    .background(Color(.systemBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
                }
                
                // Recent Transactions Card
                VStack(alignment: .leading, spacing: 16) {
                    Text("Recent Transactions")
                        .font(.headline)
                        .fontWeight(.semibold)
                    
                    if accountStore.getAllTransactions().isEmpty {
                        Text("No transactions yet")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    } else {
                        ForEach(accountStore.getAllTransactions().sorted(by: { $0.date > $1.date }).prefix(5), id: \.id) { transaction in
                            HStack {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(transaction.payee)
                                        .font(.subheadline)
                                        .fontWeight(.medium)
                                    Text(transaction.date, style: .date)
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                                Spacer()
                                Text(currencyManager.formatAmount(transaction.amount))
                                    .font(.subheadline)
                                    .fontWeight(.semibold)
                                    .foregroundColor(transaction.type == .income ? .green : .red)
                            }
                        }
                    }
                }
                .padding()
                .background(Color(.systemBackground))
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
                
                // Pro Banner for free users
                if !isProUser {
                    VStack(spacing: 16) {
                        HStack {
                            Image(systemName: "crown.fill")
                                .foregroundColor(.orange)
                            Text("Upgrade to Pro")
                                .font(.headline)
                                .fontWeight(.semibold)
                        }
                        
                        Text("Unlock AI insights, unlimited accounts, receipt scanning, and more!")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                        
                        Button("Upgrade Now") {
                            subscriptionManager.showingPaywall = true
                        }
                        .buttonStyle(.borderedProminent)
                    }
                    .padding()
                    .background(Color(.systemBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.orange.opacity(0.3), lineWidth: 2)
                    )
                    .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
                }
            }
            .padding()
        }
        .navigationTitle("Dashboard")
        .background(Color(.systemGroupedBackground))
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("Add Transaction") {
                    showingQuickAddTransaction = true
                }
            }
        }
    }
    
    // MARK: - iPad Accounts View
    private var iPadAccountsView: some View {
        ScrollView {
            LazyVGrid(columns: [
                GridItem(.flexible(), spacing: 20),
                GridItem(.flexible(), spacing: 20),
                GridItem(.flexible(), spacing: 20)
            ], spacing: 20) {
                // Add Account Card
                Button(action: { handleAddAccount() }) {
                    VStack(spacing: 16) {
                        Image(systemName: subscriptionManager.canAddAccount(currentAccountCount: accountStore.accounts.count) ? "plus.circle.fill" : "lock.fill")
                            .font(.system(size: 32))
                            .foregroundColor(subscriptionManager.canAddAccount(currentAccountCount: accountStore.accounts.count) ? .blue : .gray)
                        
                        Text("Add Account")
                            .font(.headline)
                            .fontWeight(.semibold)
                            .foregroundColor(.primary)
                    }
                    .frame(maxWidth: .infinity, minHeight: 120)
                    .background(Color(.systemBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.blue.opacity(0.3), lineWidth: 2)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Color.blue.opacity(0.05))
                            )
                    )
                }
                .buttonStyle(PlainButtonStyle())
                
                // Account Cards
                ForEach(accountStore.accounts) { account in
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Circle()
                                .fill(colorForAccount(account.color))
                                .frame(width: 12, height: 12)
                            
                            Text(account.name)
                                .font(.headline)
                                .fontWeight(.semibold)
                            
                            Spacer()
                            
                            Menu {
                                Button("Edit Account") {
                                    editAccount(account)
                                }
                                Button("Delete Account", role: .destructive) {
                                    deleteAccount(account)
                                }
                            } label: {
                                Image(systemName: "ellipsis")
                                    .foregroundColor(.secondary)
                            }
                        }
                        
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Text("Balance")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                Spacer()
                                Text(currencyManager.formatAmount(account.currentBalance))
                                    .font(.title2)
                                    .fontWeight(.bold)
                                    .foregroundColor(account.currentBalance >= 0 ? .primary : .red)
                            }
                            
                            if !account.transactions.isEmpty {
                                HStack {
                                    Text("Transactions")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                    Spacer()
                                    Text("\(account.transactions.count)")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                            }
                        }
                    }
                    .padding()
                    .background(Color(.systemBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
                    .onTapGesture {
                        selectedSidebarItem = .accounts
                    }
                }
            }
            .padding()
        }
        .navigationTitle("Accounts")
        .background(Color(.systemGroupedBackground))
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("Add Account") {
                    handleAddAccount()
                }
            }
        }
    }
    
    // MARK: - iPad Transactions View
    private var iPadTransactionsView: some View {
        VStack {
            if accountStore.getAllTransactions().isEmpty {
                VStack(spacing: 16) {
                    Image(systemName: "list.bullet")
                        .font(.system(size: 50))
                        .foregroundColor(.secondary)
                    
                    Text("No Transactions Yet")
                        .font(.headline)
                        .foregroundColor(.secondary)
                    
                    Text("Add your first transaction to get started")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                List {
                    ForEach(accountStore.getAllTransactions().sorted(by: { $0.date > $1.date })) { transaction in
                        HStack {
                            VStack(alignment: .leading) {
                                Text(transaction.payee)
                                    .font(.headline)
                                Text(transaction.date, style: .date)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            
                            Spacer()
                            
                            Text(currencyManager.formatAmount(transaction.amount))
                                .font(.headline)
                                .foregroundColor(transaction.type == .income ? .green : .red)
                        }
                        .padding(.vertical, 4)
                    }
                }
            }
        }
        .navigationTitle("Transactions")
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("Add Transaction") {
                    showingQuickAddTransaction = true
                }
            }
        }
    }
    
    // MARK: - iPad Reports View
    private var iPadReportsView: some View {
        ScrollView {
            LazyVGrid(columns: [
                GridItem(.flexible(), spacing: 20),
                GridItem(.flexible(), spacing: 20)
            ], spacing: 20) {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Net Worth Trend")
                        .font(.headline)
                        .fontWeight(.semibold)
                    
                    Text(currencyManager.formatAmount(accountStore.netWorth()))
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundColor(accountStore.netWorth() >= 0 ? .green : .red)
                    
                    Text("Track your financial progress over time")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding()
                .background(Color(.systemBackground))
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
                
                VStack(alignment: .leading, spacing: 12) {
                    Text("Spending Analysis")
                        .font(.headline)
                        .fontWeight(.semibold)
                    
                    if isProUser {
                        Text("View detailed spending patterns and insights")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    } else {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Unlock with Pro")
                                .font(.subheadline)
                                .foregroundColor(.orange)
                            
                            Button("Upgrade") {
                                subscriptionManager.showingPaywall = true
                            }
                            .font(.caption)
                            .buttonStyle(.bordered)
                        }
                    }
                }
                .padding()
                .background(Color(.systemBackground))
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
                
                VStack(alignment: .leading, spacing: 12) {
                    Text("Monthly Trends")
                        .font(.headline)
                        .fontWeight(.semibold)
                    
                    Text("Analyze monthly income and expenses")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .padding()
                .background(Color(.systemBackground))
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
                
                VStack(alignment: .leading, spacing: 12) {
                    Text("Category Breakdown")
                        .font(.headline)
                        .fontWeight(.semibold)
                    
                    Text("See spending by category")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .padding()
                .background(Color(.systemBackground))
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
            }
            .padding()
        }
        .navigationTitle("Reports")
        .background(Color(.systemGroupedBackground))
    }
    
    // MARK: - iPad Settings View
    private var iPadSettingsView: some View {
        Form {
            Section("Account") {
                NavigationLink("Security Settings") {
                    SettingsView(authManager: authManager, subscriptionManager: subscriptionManager)
                }
            }
            
            Section("Features") {
                NavigationLink("Categories") {
                    ManageCategoriesView()
                }
                NavigationLink("Recurring Payments") {
                    DuePaymentsView(
                        duePayments: duePayments,
                        recurringStore: recurringStore,
                        accountStore: accountStore
                    )
                }
            }
            
            Section("Pro Features") {
                if !isProUser {
                    Button("Upgrade to Pro") {
                        subscriptionManager.showingPaywall = true
                    }
                } else {
                    HStack {
                        Image(systemName: "crown.fill")
                            .foregroundColor(.orange)
                        Text("Pro Active")
                            .foregroundColor(.orange)
                    }
                }
            }
        }
        .navigationTitle("Settings")
    }
    
    // MARK: - iPad Quick Action Button
    private func iPadQuickActionButton(
        title: String,
        icon: String,
        color: Color,
        isLocked: Bool = false,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            VStack(spacing: 8) {
                ZStack {
                    Image(systemName: icon)
                        .font(.title2)
                        .foregroundColor(isLocked ? .gray : color)
                    
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
        }
        .buttonStyle(PlainButtonStyle())
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
    
    // MARK: - Quick Actions Section
    private var monetizedQuickActionsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Quick Actions")
                    .font(.headline)
                
                Spacer()
                
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
                    
                    MonetizedQuickActionButton(
                        title: "Scan Receipt",
                        icon: isProUser ? "camera.viewfinder" : "lock.fill",
                        color: isProUser ? .orange : .gray,
                        isLocked: !isProUser,
                        action: {
                            handleReceiptScanning()
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
                            handleAddAccount()
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
                    MonetizedQuickActionButton(
                        title: "AI Insights",
                        icon: isProUser ? "brain.head.profile" : "lock.fill",
                        color: isProUser ? .purple : .gray,
                        isLocked: !isProUser,
                        action: {
                            handleAIInsights()
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
    
    // MARK: - Due Payments Alert
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
    
    // MARK: - Accounts Section
    private var accountsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Accounts")
                    .font(.title2)
                    .fontWeight(.semibold)
                
                Spacer()
                
                Button(action: {
                    handleAddAccount()
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
                VStack(alignment: .leading, spacing: 12) {
                    let debitAccounts = accountStore.accounts.filter { $0.accountType == .debit }
                    if !debitAccounts.isEmpty {
                        assetsSection(debitAccounts)
                    }
                    
                    if !isProUser && !debitAccounts.isEmpty {
                        NativeAdCard(
                            subscriptionManager: subscriptionManager,
                            adManager: adManager
                        )
                        .padding(.horizontal)
                    }
                    
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
    
    // MARK: - Helper Methods
    private func setupApp() {
        if authManager.authenticationMethod != .none && !authManager.isAuthenticated {
            authManager.authenticateUser()
        }
        
        RecurringPaymentScheduler.shared.configure(
            recurringStore: recurringStore,
            accountStore: accountStore
        )
        
        _ = RecurringPaymentScheduler.shared.checkAndProcessDuePayments()
        RecurringPaymentScheduler.shared.scheduleUpcomingPaymentNotifications()
        
        usageAnalytics.trackAppOpen()
    }
    
    private func handleForegroundReturn() {
        if authManager.authenticationMethod != .none {
            authManager.lockApp()
            authManager.authenticateUser()
        }
        
        RecurringPaymentScheduler.shared.applicationWillEnterForeground()
    }
    
    private func handleAddAccount() {
        if subscriptionManager.canAddAccount(currentAccountCount: accountStore.accounts.count) {
            showingAddAccount = true
        } else {
            subscriptionManager.showPaywallIfNeeded(for: .addAccount(currentCount: accountStore.accounts.count))
        }
        usageAnalytics.trackFeatureUsage("add_account")
    }
    
    private func handleReceiptScanning() {
        if subscriptionManager.canAccessReceiptScanning() {
            showingScanReceipt = true
        } else {
            subscriptionManager.showPaywallIfNeeded(for: .receiptScanning)
        }
        usageAnalytics.trackFeatureUsage("scan_receipt")
    }
    
    private func handleAIInsights() {
        if subscriptionManager.canAccessAIInsights() {
            showingAIInsights = true
        } else {
            subscriptionManager.showPaywallIfNeeded(for: .aiInsights)
        }
        usageAnalytics.trackFeatureUsage("ai_insights_tap")
    }
    
    private func colorForAccount(_ colorName: String) -> Color {
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
    
    private func editAccount(_ account: Account) {
        accountToEdit = account
        showingEditAccount = true
    }
    
    private func deleteAccount(_ account: Account) {
        accountToDelete = account
        showingDeleteAlert = true
    }
}

// MARK: - Quick Meme Generator with Real Data
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

// MARK: - Share Win View
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

// MARK: - Monetized Quick Action Button with Dark Mode Support
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
