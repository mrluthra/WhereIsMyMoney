import SwiftUI

#if DEBUG
struct DeveloperSettingsView: View {
    @ObservedObject var subscriptionManager: SubscriptionManager
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            List {
                Section(header: Text("🧪 Development Tools")) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Use these tools to test Pro features without purchasing")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding(.vertical, 4)
                }
                
                Section(header: Text("Subscription Testing")) {
                    // Development Mode Toggle
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Development Mode")
                                .font(.headline)
                            Text("Enable testing features without StoreKit")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                        
                        Toggle("", isOn: $subscriptionManager.isDevelopmentMode)
                            .labelsHidden()
                            .onChange(of: subscriptionManager.isDevelopmentMode) { oldValue, newValue in
                                subscriptionManager.setDevelopmentMode(newValue)
                            }
                    }
                    
                    // Mock Pro Status Toggle (only show if dev mode is on)
                    if subscriptionManager.isDevelopmentMode {
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                HStack {
                                    Text("Mock Pro Status")
                                        .font(.headline)
                                    
                                    if subscriptionManager.mockProStatus {
                                        Text("PRO")
                                            .font(.caption)
                                            .fontWeight(.bold)
                                            .foregroundColor(.white)
                                            .padding(.horizontal, 6)
                                            .padding(.vertical, 2)
                                            .background(Color.orange)
                                            .clipShape(Capsule())
                                    }
                                }
                                
                                Text(subscriptionManager.mockProStatus ?
                                     "All Pro features are unlocked" :
                                     "App behaves as Free tier")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            
                            Spacer()
                            
                            Button(subscriptionManager.mockProStatus ? "Disable Pro" : "Enable Pro") {
                                subscriptionManager.toggleMockProStatus()
                            }
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundColor(.white)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(subscriptionManager.mockProStatus ? Color.red : Color.green)
                            .clipShape(Capsule())
                        }
                        
                        // Current Status Display
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Current Status: \(subscriptionManager.subscriptionStatus.displayName)")
                                .font(.subheadline)
                                .fontWeight(.medium)
                            
                            Text("Features Available:")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            
                            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 8) {
                                FeatureStatusRow(title: "Unlimited Accounts", isEnabled: subscriptionManager.canAddAccount(currentAccountCount: 10))
                                FeatureStatusRow(title: "AI Insights", isEnabled: subscriptionManager.canAccessAIInsights())
                                FeatureStatusRow(title: "Receipt Scanning", isEnabled: subscriptionManager.canAccessReceiptScanning())
                                FeatureStatusRow(title: "Advanced Reports", isEnabled: subscriptionManager.canAccessAdvancedReports())
                            }
                        }
                        .padding()
                        .background(Color(.systemGray6))
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                    }
                }
                
                Section(header: Text("Quick Actions")) {
                    Button("Reset All Development Settings") {
                        resetDevelopmentSettings()
                    }
                    .foregroundColor(.red)
                    
                    Button("Test Paywall") {
                        subscriptionManager.showingPaywall = true
                    }
                    .foregroundColor(.blue)
                }
                
                Section(header: Text("App Information")) {
                    HStack {
                        Text("Build Configuration")
                        Spacer()
                        Text("DEBUG")
                            .font(.caption)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.orange)
                            .clipShape(Capsule())
                    }
                    
                    HStack {
                        Text("StoreKit Available")
                        Spacer()
                        Text(subscriptionManager.subscriptionProducts.isEmpty ? "NO" : "YES")
                            .font(.caption)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(subscriptionManager.subscriptionProducts.isEmpty ? Color.red : Color.green)
                            .clipShape(Capsule())
                    }
                }
                
                Section {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("⚠️ Development Only")
                            .font(.caption)
                            .fontWeight(.bold)
                            .foregroundColor(.orange)
                        
                        Text("This section only appears in DEBUG builds and will not be visible in the App Store version.")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding(.vertical, 4)
                }
            }
            .navigationTitle("Developer Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
        .sheet(isPresented: $subscriptionManager.showingPaywall) {
            PaywallView(subscriptionManager: subscriptionManager)
        }
    }
    
    private func resetDevelopmentSettings() {
        subscriptionManager.setDevelopmentMode(false)
        UserDefaults.standard.removeObject(forKey: "dev_mock_pro_status")
        UserDefaults.standard.removeObject(forKey: "userActionCount")
        UserDefaults.standard.removeObject(forKey: "totalTransactionCount")
        UserDefaults.standard.removeObject(forKey: "totalAdRevenue")
    }
}

struct FeatureStatusRow: View {
    let title: String
    let isEnabled: Bool
    
    var body: some View {
        HStack {
            Text(title)
                .font(.caption)
                .foregroundColor(.primary)
            
            Spacer()
            
            Image(systemName: isEnabled ? "checkmark.circle.fill" : "xmark.circle.fill")
                .foregroundColor(isEnabled ? .green : .red)
                .font(.caption)
        }
    }
}

#Preview {
    DeveloperSettingsView(subscriptionManager: SubscriptionManager())
}
#endif
