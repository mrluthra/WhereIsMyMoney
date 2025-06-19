import SwiftUI

struct SettingsView: View {
    @ObservedObject var authManager: AuthenticationManager
    @ObservedObject var subscriptionManager: SubscriptionManager
    @Environment(\.dismiss) private var dismiss
    @State private var showingPasscodeSetup = false
    @State private var showingDisableAlert = false
    @State private var showingDeveloperSettings = false
    
    init(authManager: AuthenticationManager, subscriptionManager: SubscriptionManager) {
        self.authManager = authManager
        self.subscriptionManager = subscriptionManager
    }
    
    // Fallback initializer for backwards compatibility
    init(authManager: AuthenticationManager) {
        self.authManager = authManager
        self.subscriptionManager = SubscriptionManager()
    }
    
    var body: some View {
        NavigationView {
            List {
                // Subscription Section
                subscriptionSection
                
                // Developer Section (DEBUG only)
                #if DEBUG
                developerSection
                #endif
                
                // Security Section
                securitySection
                
                // Data & Privacy Section
                dataPrivacySection
                
                // Support Section
                supportSection
                
                // App Information Section
                appInfoSection
            }
            .navigationTitle("Settings")
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
        .sheet(isPresented: $showingPasscodeSetup) {
            PasscodeSetupView(authManager: authManager)
        }
        .sheet(isPresented: $subscriptionManager.showingPaywall) {
            PaywallView(subscriptionManager: subscriptionManager)
        }
        #if DEBUG
        .sheet(isPresented: $showingDeveloperSettings) {
            DeveloperSettingsView(subscriptionManager: subscriptionManager)
        }
        #endif
        .alert("Disable Security", isPresented: $showingDisableAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Disable", role: .destructive) {
                authManager.setAuthenticationMethod(.none)
            }
        } message: {
            Text("Are you sure you want to disable app security? Your financial data will be accessible without authentication.")
        }
    }
    
    // MARK: - Subscription Section
    
    private var subscriptionSection: some View {
        Section(header: Text("Subscription")) {
            HStack {
                if subscriptionManager.isSubscribed {
                    Circle()
                        .fill(LinearGradient(colors: [.orange, .yellow], startPoint: .topLeading, endPoint: .bottomTrailing))
                        .frame(width: 40, height: 40)
                } else {
                    Circle()
                        .fill(Color.gray.opacity(0.3))
                        .frame(width: 40, height: 40)
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text("Plan Status")
                            .font(.headline)
                        
                        if subscriptionManager.isSubscribed {
                            Text("PRO")
                                .font(.caption)
                                .fontWeight(.bold)
                                .foregroundColor(.white)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(Color.orange)
                                .clipShape(Capsule())
                        }
                        
                        #if DEBUG
                        if subscriptionManager.isDevelopmentMode && subscriptionManager.mockProStatus {
                            Text("DEV")
                                .font(.caption)
                                .fontWeight(.bold)
                                .foregroundColor(.white)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(Color.blue)
                                .clipShape(Capsule())
                        }
                        #endif
                    }
                    
                    Text(subscriptionManager.subscriptionStatus.displayName)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                if !subscriptionManager.isSubscribed {
                    #if DEBUG
                    if !(subscriptionManager.isDevelopmentMode && subscriptionManager.mockProStatus) {
                        upgradeButton
                    }
                    #else
                    upgradeButton
                    #endif
                }
            }
            .padding(.vertical, 8)
            
            if subscriptionManager.isSubscribed || (subscriptionManager.isDevelopmentMode && subscriptionManager.mockProStatus) {
                proFeaturesSection
            } else {
                freeFeaturesSection
            }
        }
    }
    
    private var upgradeButton: some View {
        Button("Upgrade") {
            subscriptionManager.showingPaywall = true
        }
        .font(.subheadline)
        .fontWeight(.medium)
        .foregroundColor(.white)
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .background(
            LinearGradient(
                colors: [.blue, .purple],
                startPoint: .leading,
                endPoint: .trailing
            )
        )
        .clipShape(Capsule())
    }
    
    private var proFeaturesSection: some View {
        VStack(spacing: 12) {
            // Pro Features List
            VStack(spacing: 8) {
                FeatureBadge(icon: "infinity", title: "Unlimited Accounts", isActive: true)
                FeatureBadge(icon: "infinity", title: "Unlimited Transactions", isActive: true)
                FeatureBadge(icon: "brain.head.profile", title: "AI Insights", isActive: true)
                FeatureBadge(icon: "doc.text.viewfinder", title: "Receipt Scanning", isActive: true)
                FeatureBadge(icon: "chart.bar.fill", title: "Advanced Reports", isActive: true)
                FeatureBadge(icon: "bell.slash.fill", title: "No Ads", isActive: true)
            }
            
            if subscriptionManager.isSubscribed {
                Button("Manage Subscription") {
                    if let url = URL(string: "https://apps.apple.com/account/subscriptions") {
                        UIApplication.shared.open(url)
                    }
                }
                .font(.subheadline)
                .foregroundColor(.blue)
            }
        }
    }
    
    private var freeFeaturesSection: some View {
        VStack(spacing: 12) {
            // Free Plan Limitations
            VStack(spacing: 8) {
                FeatureBadge(icon: "2.circle", title: "Up to 2 Accounts", isActive: true)
                FeatureBadge(icon: "50.circle", title: "50 Transactions/Account/Month", isActive: true)
                FeatureBadge(icon: "rectangle.and.text.magnifyingglass", title: "Ad-Supported", isActive: true)
                FeatureBadge(icon: "brain.head.profile", title: "AI Insights", isActive: false)
                FeatureBadge(icon: "doc.text.viewfinder", title: "Receipt Scanning", isActive: false)
                FeatureBadge(icon: "chart.bar.fill", title: "Advanced Reports", isActive: false)
            }
            
            Button("See All Pro Features") {
                subscriptionManager.showingPaywall = true
            }
            .font(.subheadline)
            .fontWeight(.medium)
            .foregroundColor(.blue)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(Color.blue.opacity(0.1))
            .clipShape(RoundedRectangle(cornerRadius: 8))
        }
    }
    
    // MARK: - Developer Section (DEBUG only)
    
    #if DEBUG
    private var developerSection: some View {
        Section(header: Text("🧪 Developer")) {
            Button(action: { showingDeveloperSettings = true }) {
                HStack {
                    Image(systemName: "hammer.fill")
                        .foregroundColor(.orange)
                        .frame(width: 24)
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Developer Settings")
                            .font(.headline)
                            .foregroundColor(.primary)
                        Text("Test Pro features without purchasing")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    if subscriptionManager.isDevelopmentMode {
                        Text("DEV MODE")
                            .font(.caption)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.orange)
                            .clipShape(Capsule())
                    }
                    
                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .buttonStyle(PlainButtonStyle())
        }
    }
    #endif
    
    // MARK: - Security Section
    
    private var securitySection: some View {
        Section(header: Text("Security")) {
            // Current Security Status
            HStack {
                Image(systemName: authManager.authenticationMethod.systemImage)
                    .foregroundColor(authManager.authenticationMethod == .none ? .gray : .blue)
                    .frame(width: 24)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text("App Security")
                        .font(.headline)
                    Text("Currently: \(authManager.authenticationMethod.displayName)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                if authManager.authenticationMethod != .none {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                }
            }
            .padding(.vertical, 4)
            
            // Passcode Option
            Button(action: {
                if authManager.authenticationMethod == .passcode {
                    showingDisableAlert = true
                } else {
                    showingPasscodeSetup = true
                }
            }) {
                HStack {
                    Image(systemName: "lock.fill")
                        .foregroundColor(.blue)
                        .frame(width: 24)
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text("4-Digit Passcode")
                            .font(.headline)
                            .foregroundColor(.primary)
                        Text("Secure your app with a 4-digit passcode")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    if authManager.authenticationMethod == .passcode {
                        Text("Enabled")
                            .font(.subheadline)
                            .foregroundColor(.green)
                    } else {
                        Image(systemName: "chevron.right")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
            .buttonStyle(PlainButtonStyle())
            
            // Biometric Option
            Button(action: {
                if authManager.authenticationMethod == .biometric {
                    authManager.setAuthenticationMethod(.none)
                } else if authManager.isBiometricAvailable() {
                    authManager.setAuthenticationMethod(.biometric)
                }
            }) {
                HStack {
                    Image(systemName: "faceid")
                        .foregroundColor(authManager.isBiometricAvailable() ? .blue : .gray)
                        .frame(width: 24)
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text(authManager.biometricType())
                            .font(.headline)
                            .foregroundColor(authManager.isBiometricAvailable() ? .primary : .secondary)
                        
                        Text(authManager.isBiometricAvailable()
                             ? "Use biometric authentication to unlock the app"
                             : "Biometric authentication is not available on this device")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    if authManager.isBiometricAvailable() {
                        if authManager.authenticationMethod == .biometric {
                            Text("Enabled")
                                .font(.subheadline)
                                .foregroundColor(.green)
                        } else {
                            Toggle("", isOn: Binding(
                                get: { authManager.authenticationMethod == .biometric },
                                set: { enabled in
                                    if enabled {
                                        authManager.setAuthenticationMethod(.biometric)
                                    } else {
                                        authManager.setAuthenticationMethod(.none)
                                    }
                                }
                            ))
                            .labelsHidden()
                        }
                    } else {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundColor(.orange)
                            .font(.caption)
                    }
                }
            }
            .buttonStyle(PlainButtonStyle())
            .disabled(!authManager.isBiometricAvailable())
            
            // Disable Security Option
            if authManager.authenticationMethod != .none {
                Button(action: {
                    showingDisableAlert = true
                }) {
                    HStack {
                        Image(systemName: "lock.slash")
                            .foregroundColor(.red)
                            .frame(width: 24)
                        
                        Text("Disable App Security")
                            .font(.headline)
                            .foregroundColor(.red)
                        
                        Spacer()
                    }
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
    }
    
    // MARK: - Data & Privacy Section
    
    private var dataPrivacySection: some View {
        Section(header: Text("Data & Privacy")) {
            HStack {
                Image(systemName: "shield.fill")
                    .foregroundColor(.green)
                    .frame(width: 24)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text("Data Storage")
                        .font(.headline)
                    Text("All data is stored locally on your device")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(.green)
            }
            .padding(.vertical, 4)
            
            Button(action: {
                if let url = URL(string: "https://example.com/privacy") {
                    UIApplication.shared.open(url)
                }
            }) {
                HStack {
                    Image(systemName: "doc.text")
                        .foregroundColor(.blue)
                        .frame(width: 24)
                    
                    Text("Privacy Policy")
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    Spacer()
                    
                    Image(systemName: "arrow.up.right")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .buttonStyle(PlainButtonStyle())
        }
    }
    
    // MARK: - Support Section
    
    private var supportSection: some View {
        Section(header: Text("Support")) {
            Button(action: {
                if let url = URL(string: "mailto:support@whereismymoney.app") {
                    UIApplication.shared.open(url)
                }
            }) {
                HStack {
                    Image(systemName: "envelope.fill")
                        .foregroundColor(.blue)
                        .frame(width: 24)
                    
                    Text("Contact Support")
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    Spacer()
                    
                    Image(systemName: "arrow.up.right")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .buttonStyle(PlainButtonStyle())
            
            Button(action: {
                if let url = URL(string: "https://apps.apple.com/app/whereismymoney/id123456789?action=write-review") {
                    UIApplication.shared.open(url)
                }
            }) {
                HStack {
                    Image(systemName: "star.fill")
                        .foregroundColor(.yellow)
                        .frame(width: 24)
                    
                    Text("Rate the App")
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    Spacer()
                    
                    Image(systemName: "arrow.up.right")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .buttonStyle(PlainButtonStyle())
        }
    }
    
    // MARK: - App Information Section
    
    private var appInfoSection: some View {
        Section(header: Text("About")) {
            HStack {
                Image(systemName: "app.badge")
                    .foregroundColor(.blue)
                    .frame(width: 24)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text("WhereIsMyMoney")
                        .font(.headline)
                    Text("Personal Finance Tracker")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 2) {
                    Text("v1.0")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    #if DEBUG
                    Text("DEBUG")
                        .font(.caption)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                        .padding(.horizontal, 4)
                        .padding(.vertical, 1)
                        .background(Color.orange)
                        .clipShape(Capsule())
                    #endif
                }
            }
            .padding(.vertical, 4)
            
            Button(action: {
                if let url = URL(string: "https://example.com/terms") {
                    UIApplication.shared.open(url)
                }
            }) {
                HStack {
                    Image(systemName: "doc.text")
                        .foregroundColor(.blue)
                        .frame(width: 24)
                    
                    Text("Terms of Service")
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    Spacer()
                    
                    Image(systemName: "arrow.up.right")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .buttonStyle(PlainButtonStyle())
        }
    }
}

// MARK: - Feature Badge

struct FeatureBadge: View {
    let icon: String
    let title: String
    let isActive: Bool
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 16))
                .foregroundColor(isActive ? .blue : .gray)
                .frame(width: 20)
            
            Text(title)
                .font(.subheadline)
                .foregroundColor(isActive ? .primary : .secondary)
            
            Spacer()
            
            if isActive {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 14))
                    .foregroundColor(.green)
            } else {
                Image(systemName: "lock.fill")
                    .font(.system(size: 12))
                    .foregroundColor(.orange)
            }
        }
        .padding(.vertical, 2)
    }
}

#Preview {
    SettingsView(authManager: AuthenticationManager(), subscriptionManager: SubscriptionManager())
}
