import SwiftUI

struct PasscodeSetupView: View {
    @ObservedObject var authManager: AuthenticationManager
    @Environment(\.dismiss) private var dismiss
    @State private var enteredPasscode = ""
    @State private var confirmPasscode = ""
    @State private var setupStep: SetupStep = .enterPasscode
    @State private var passcodesDontMatch = false
    
    enum SetupStep {
        case enterPasscode
        case confirmPasscode
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                Color(.systemGroupedBackground).ignoresSafeArea()
                
                VStack(spacing: 40) {
                    // Header
                    VStack(spacing: 16) {
                        Image(systemName: "lock.shield.fill")
                            .font(.system(size: 60))
                            .foregroundColor(.blue)
                        
                        Text(setupStep == .enterPasscode ? "Set up Passcode" : "Confirm Passcode")
                            .font(.title)
                            .fontWeight(.bold)
                        
                        Text(setupStep == .enterPasscode
                             ? "Enter a 4-digit passcode"
                             : "Enter your passcode again")
                            .font(.headline)
                            .foregroundColor(.secondary)
                    }
                    
                    // Passcode Display
                    VStack(spacing: 20) {
                        HStack(spacing: 20) {
                            ForEach(0..<4) { index in
                                let currentPasscode = setupStep == .enterPasscode ? enteredPasscode : confirmPasscode
                                Circle()
                                    .fill(index < currentPasscode.count ? Color.blue : Color.gray.opacity(0.3))
                                    .frame(width: 20, height: 20)
                                    .scaleEffect(index < currentPasscode.count ? 1.2 : 1.0)
                                    .animation(.spring(response: 0.3), value: currentPasscode.count)
                            }
                        }
                        
                        if passcodesDontMatch {
                            Text("Passcodes don't match. Try again.")
                                .font(.subheadline)
                                .foregroundColor(.red)
                                .transition(.opacity)
                        }
                    }
                    
                    // Number Pad
                    VStack(spacing: 20) {
                        ForEach(0..<3) { row in
                            HStack(spacing: 20) {
                                ForEach(1..<4) { col in
                                    let number = row * 3 + col
                                    NumberPadButton(
                                        number: "\(number)",
                                        action: { addNumber("\(number)") }
                                    )
                                }
                            }
                        }
                        
                        // Bottom row with 0 and delete
                        HStack(spacing: 20) {
                            // Empty space
                            Color.clear
                                .frame(width: 80, height: 80)
                            
                            // Zero button
                            NumberPadButton(
                                number: "0",
                                action: { addNumber("0") }
                            )
                            
                            // Delete button
                            Button(action: deleteNumber) {
                                Image(systemName: "delete.left.fill")
                                    .font(.title2)
                                    .foregroundColor(.blue)
                                    .frame(width: 80, height: 80)
                                    .background(Color.blue.opacity(0.1))
                                    .clipShape(Circle())
                            }
                        }
                    }
                    
                    Spacer()
                }
                .padding()
            }
            .navigationTitle("Passcode Setup")
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
    
    private func addNumber(_ number: String) {
        if setupStep == .enterPasscode {
            guard enteredPasscode.count < 4 else { return }
            enteredPasscode += number
            
            if enteredPasscode.count == 4 {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    setupStep = .confirmPasscode
                }
            }
        } else {
            guard confirmPasscode.count < 4 else { return }
            confirmPasscode += number
            
            if confirmPasscode.count == 4 {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    validatePasscodes()
                }
            }
        }
    }
    
    private func deleteNumber() {
        if setupStep == .enterPasscode {
            guard !enteredPasscode.isEmpty else { return }
            enteredPasscode.removeLast()
        } else {
            guard !confirmPasscode.isEmpty else { return }
            confirmPasscode.removeLast()
        }
        passcodesDontMatch = false
    }
    
    private func validatePasscodes() {
        if enteredPasscode == confirmPasscode {
            // Passcodes match, save and enable
            authManager.setPasscode(enteredPasscode)
            authManager.setAuthenticationMethod(.passcode)
            dismiss()
        } else {
            // Passcodes don't match, reset and try again
            withAnimation {
                passcodesDontMatch = true
                confirmPasscode = ""
                setupStep = .enterPasscode
                enteredPasscode = ""
            }
            
            // Auto-clear error after delay
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                withAnimation {
                    passcodesDontMatch = false
                }
            }
        }
    }
}

struct NumberPadButton: View {
    let number: String
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(number)
                .font(.title)
                .fontWeight(.medium)
                .foregroundColor(.primary)
                .frame(width: 80, height: 80)
                .background(Color(.systemGray6))
                .clipShape(Circle())
        }
    }
}

#Preview {
    PasscodeSetupView(authManager: AuthenticationManager())
}
