import SwiftUI

struct PasscodeEntryView: View {
    @ObservedObject var authManager: AuthenticationManager
    @State private var enteredPasscode = ""
    @State private var isIncorrect = false
    @State private var attempts = 0
    let maxAttempts = 5
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            VStack(spacing: 40) {
                // App Header
                VStack(spacing: 16) {
                    Image(systemName: "lock.shield.fill")
                        .font(.system(size: 60))
                        .foregroundColor(.white)
                    
                    Text("CashPotato")
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                    
                    Text("Enter your passcode")
                        .font(.headline)
                        .foregroundColor(.white.opacity(0.8))
                }
                
                // Passcode Display
                VStack(spacing: 20) {
                    HStack(spacing: 20) {
                        ForEach(0..<4) { index in
                            Circle()
                                .fill(index < enteredPasscode.count ? Color.white : Color.white.opacity(0.3))
                                .frame(width: 20, height: 20)
                                .scaleEffect(index < enteredPasscode.count ? 1.2 : 1.0)
                                .animation(.spring(response: 0.3), value: enteredPasscode.count)
                        }
                    }
                    
                    if isIncorrect {
                        Text("Incorrect passcode. Try again.")
                            .font(.subheadline)
                            .foregroundColor(.red)
                            .transition(.opacity)
                        
                        if attempts >= maxAttempts - 2 {
                            Text("\(maxAttempts - attempts) attempts remaining")
                                .font(.caption)
                                .foregroundColor(.orange)
                        }
                    }
                }
                
                // Number Pad
                VStack(spacing: 20) {
                    ForEach(0..<3) { row in
                        HStack(spacing: 20) {
                            ForEach(1..<4) { col in
                                let number = row * 3 + col
                                NumberButton(
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
                        NumberButton(
                            number: "0",
                            action: { addNumber("0") }
                        )
                        
                        // Delete button
                        Button(action: deleteNumber) {
                            Image(systemName: "delete.left.fill")
                                .font(.title2)
                                .foregroundColor(.white)
                                .frame(width: 80, height: 80)
                                .background(Color.white.opacity(0.1))
                                .clipShape(Circle())
                        }
                    }
                }
                
                // Biometric fallback button if available
                if authManager.isBiometricAvailable() {
                    Button(action: {
                        authManager.authenticateWithBiometrics()
                    }) {
                        HStack {
                            Image(systemName: "faceid")
                                .font(.title3)
                            Text("Use \(authManager.biometricType())")
                                .font(.headline)
                        }
                        .foregroundColor(.blue)
                        .padding()
                        .background(Color.white.opacity(0.1))
                        .clipShape(Capsule())
                    }
                }
                
                Spacer()
            }
            .padding()
        }
        .onAppear {
            enteredPasscode = ""
            isIncorrect = false
            attempts = 0
        }
    }
    
    private func addNumber(_ number: String) {
        guard enteredPasscode.count < 4 else { return }
        
        enteredPasscode += number
        
        // Auto-submit when 4 digits are entered
        if enteredPasscode.count == 4 {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                submitPasscode()
            }
        }
    }
    
    private func deleteNumber() {
        guard !enteredPasscode.isEmpty else { return }
        enteredPasscode.removeLast()
        isIncorrect = false
    }
    
    private func submitPasscode() {
        let success = authManager.authenticateWithPasscode(enteredPasscode)
        
        if !success {
            withAnimation {
                isIncorrect = true
                attempts += 1
                enteredPasscode = ""
            }
            
            // Add haptic feedback for incorrect passcode
            let impactFeedback = UIImpactFeedbackGenerator(style: .heavy)
            impactFeedback.impactOccurred()
            
            // Auto-clear error after delay
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                withAnimation {
                    isIncorrect = false
                }
            }
            
            // Lock app after max attempts
            if attempts >= maxAttempts {
                // In a real app, you might want to implement a lockout period
                // For now, we'll just reset attempts
                DispatchQueue.main.asyncAfter(deadline: .now() + 5.0) {
                    attempts = 0
                }
            }
        }
    }
}

struct NumberButton: View {
    let number: String
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(number)
                .font(.title)
                .fontWeight(.medium)
                .foregroundColor(.white)
                .frame(width: 80, height: 80)
                .background(Color.white.opacity(0.1))
                .clipShape(Circle())
        }
        .scaleEffect(1.0)
        .onTapGesture {
            // Add haptic feedback
            let impactFeedback = UIImpactFeedbackGenerator(style: .light)
            impactFeedback.impactOccurred()
            action()
        }
    }
}

#Preview {
    PasscodeEntryView(authManager: AuthenticationManager())
}
