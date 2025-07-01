import SwiftUI

struct PrivacyPolicyView: View {
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    Text("Privacy Policy")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .padding(.bottom)
                    
                    Group {
                        PolicySection(
                            title: "Information We Collect",
                            content: """
                            CashPotato stores all your financial data locally on your device. We do not collect, transmit, or store any of your personal financial information on our servers.
                            
                            The app may collect:
                            • Anonymous usage analytics to improve app performance
                            • Crash reports to fix bugs and improve stability
                            • App Store purchase information for subscription management
                            """
                        )
                        
                        PolicySection(
                            title: "How We Use Your Information",
                            content: """
                            • Your financial data remains on your device and is never transmitted to our servers
                            • Anonymous analytics help us understand how to improve the app
                            • Subscription information is used to provide Pro features
                            • All data processing happens locally on your device
                            """
                        )
                        
                        PolicySection(
                            title: "Data Storage and Security",
                            content: """
                            • All financial data is stored locally using iOS secure storage mechanisms
                            • Your data is protected by your device's security features (Face ID, passcode)
                            • No financial data is transmitted over the internet
                            """
                        )
                        
                        PolicySection(
                            title: "Third-Party Services",
                            content: """
                            We may use the following third-party services:
                            • Apple App Store for subscription processing
                            • Anonymous analytics services (if applicable)
                            • Crash reporting services (if applicable)
                            
                            These services have their own privacy policies and do not receive your financial data.
                            """
                        )
                        
                        PolicySection(
                            title: "Your Rights",
                            content: """
                            • You can delete all your data by deleting the app
                            • You can manage subscriptions through your Apple ID settings
                            • You have full control over your data at all times
                            """
                        )
                        
                        PolicySection(
                            title: "Data Backup",
                            content: """
                            • App data may be included in iOS device backups (iCloud/iTunes)
                            • You control backup settings through iOS Settings
                            • Backups are encrypted and managed by Apple's privacy policies
                            """
                        )
                        
                        PolicySection(
                            title: "Changes to Privacy Policy",
                            content: """
                            We may update this privacy policy from time to time. Any changes will be reflected in app updates with a new version of this policy.
                            """
                        )
                        
                        PolicySection(
                            title: "Contact Us",
                            content: """
                            If you have questions about this privacy policy, please contact us at:
                            
                            Email: cashpotato@protonmail.com
                            
                            Last updated: \(getCurrentDate())
                            """
                        )
                    }
                }
                .padding()
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
    
    private func getCurrentDate() -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .long
        return formatter.string(from: Date())
    }
}

struct PolicySection: View {
    let title: String
    let content: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.headline)
                .fontWeight(.semibold)
            
            Text(content)
                .font(.body)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}

#Preview {
    PrivacyPolicyView()
}
