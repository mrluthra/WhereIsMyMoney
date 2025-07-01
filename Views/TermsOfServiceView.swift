import SwiftUI

struct TermsOfServiceView: View {
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    Text("Terms of Service")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .padding(.bottom)
                    
                    Group {
                        PolicySection(
                            title: "Acceptance of Terms",
                            content: """
                            By downloading and using CashPotato, you agree to these Terms of Service. If you do not agree, please do not use the app.
                            """
                        )
                        
                        PolicySection(
                            title: "Description of Service",
                            content: """
                            CashPotato is a personal finance management app that helps you track expenses, manage accounts, and analyze spending patterns. The app includes both free and premium (Pro) features.
                            """
                        )
                        
                        PolicySection(
                            title: "User Responsibilities",
                            content: """
                            • You are responsible for the accuracy of financial data you enter
                            • You must keep your device secure and protected
                            • You agree to use the app for lawful purposes only
                            • You are responsible for backing up your data
                            """
                        )
                        
                        PolicySection(
                            title: "Subscription Terms",
                            content: """
                            • Pro subscriptions are billed through your Apple ID
                            • Subscriptions auto-renew unless cancelled 24 hours before renewal
                            • You can manage subscriptions in your Apple ID settings
                            • No refunds for partial subscription periods
                            • Pro features are only available with active subscription
                            """
                        )
                        
                        PolicySection(
                            title: "Disclaimers",
                            content: """
                            • The app is provided "as is" without warranties
                            • We are not responsible for financial decisions based on app data
                            • AI insights are for informational purposes only
                            • Always verify financial calculations independently
                            """
                        )
                        
                        PolicySection(
                            title: "Limitations of Liability",
                            content: """
                            We shall not be liable for any damages arising from:
                            • Loss of data
                            • Financial decisions based on app information
                            • Service interruptions
                            • Technical malfunctions
                            """
                        )
                        
                        PolicySection(
                            title: "Intellectual Property",
                            content: """
                            • The app and its content are protected by copyright
                            • You may not copy, modify, or distribute the app
                            • All trademarks belong to their respective owners
                            """
                        )
                        
                        PolicySection(
                            title: "Termination",
                            content: """
                            • You may stop using the app at any time
                            • We may terminate access for violations of these terms
                            • Upon termination, these terms remain in effect for applicable provisions
                            """
                        )
                        
                        PolicySection(
                            title: "Changes to Terms",
                            content: """
                            We may update these terms from time to time. Continued use of the app after changes constitutes acceptance of new terms.
                            """
                        )
                        
                        PolicySection(
                            title: "Contact Information",
                            content: """
                            For questions about these terms, contact us at:
                            
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

#Preview {
    TermsOfServiceView()
}
