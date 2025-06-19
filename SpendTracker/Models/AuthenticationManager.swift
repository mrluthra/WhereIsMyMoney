import Foundation
import LocalAuthentication
import SwiftUI

class AuthenticationManager: ObservableObject {
    @Published var isAuthenticated = false
    @Published var authenticationMethod: AuthenticationMethod = .none
    @Published var showingPasscodeEntry = false
    
    private let userDefaults = UserDefaults.standard
    private let authMethodKey = "AuthenticationMethod"
    private let passcodeKey = "UserPasscode"
    
    enum AuthenticationMethod: String, CaseIterable {
        case none = "None"
        case passcode = "Passcode"
        case biometric = "Face ID / Touch ID"
        
        var displayName: String {
            switch self {
            case .none: return "None"
            case .passcode: return "4-Digit Passcode"
            case .biometric: return "Face ID / Touch ID"
            }
        }
        
        var systemImage: String {
            switch self {
            case .none: return "lock.slash"
            case .passcode: return "lock.fill"
            case .biometric: return "faceid"
            }
        }
    }
    
    init() {
        loadAuthenticationMethod()
        // Don't auto-authenticate on init - let the app handle it
    }
    
    // MARK: - Authentication Method Management
    
    func loadAuthenticationMethod() {
        if let savedMethod = userDefaults.string(forKey: authMethodKey),
           let method = AuthenticationMethod(rawValue: savedMethod) {
            authenticationMethod = method
        }
    }
    
    func setAuthenticationMethod(_ method: AuthenticationMethod) {
        authenticationMethod = method
        userDefaults.set(method.rawValue, forKey: authMethodKey)
        
        // Clear passcode if switching away from passcode method
        if method != .passcode {
            clearPasscode()
        }
        
        // Reset authentication state when changing methods
        if method == .none {
            isAuthenticated = true
        } else {
            isAuthenticated = false
        }
    }
    
    // MARK: - Passcode Management
    
    func setPasscode(_ passcode: String) {
        userDefaults.set(passcode, forKey: passcodeKey)
    }
    
    func getPasscode() -> String? {
        return userDefaults.string(forKey: passcodeKey)
    }
    
    func clearPasscode() {
        userDefaults.removeObject(forKey: passcodeKey)
    }
    
    func validatePasscode(_ enteredPasscode: String) -> Bool {
        guard let savedPasscode = getPasscode() else { return false }
        return enteredPasscode == savedPasscode
    }
    
    // MARK: - Authentication
    
    func authenticateUser() {
        switch authenticationMethod {
        case .none:
            isAuthenticated = true
        case .passcode:
            showingPasscodeEntry = true
        case .biometric:
            authenticateWithBiometrics()
        }
    }
    
    func authenticateWithPasscode(_ passcode: String) -> Bool {
        if validatePasscode(passcode) {
            isAuthenticated = true
            showingPasscodeEntry = false
            return true
        }
        return false
    }
    
    func authenticateWithBiometrics() {
        let context = LAContext()
        var error: NSError?
        
        if context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) {
            let reason = "Authenticate to access WhereIsMyMoney"
            
            context.evaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, localizedReason: reason) { success, authenticationError in
                DispatchQueue.main.async {
                    if success {
                        self.isAuthenticated = true
                    } else {
                        // If biometric fails, fall back to passcode if available
                        if self.getPasscode() != nil {
                            self.showingPasscodeEntry = true
                        }
                    }
                }
            }
        } else {
            // Biometrics not available, fall back to passcode
            if getPasscode() != nil {
                showingPasscodeEntry = true
            } else {
                // No fallback available, allow access
                isAuthenticated = true
            }
        }
    }
    
    // MARK: - Biometric Availability
    
    func isBiometricAvailable() -> Bool {
        let context = LAContext()
        var error: NSError?
        return context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error)
    }
    
    func biometricType() -> String {
        let context = LAContext()
        var error: NSError?
        
        guard context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) else {
            return "Not Available"
        }
        
        switch context.biometryType {
        case .faceID:
            return "Face ID"
        case .touchID:
            return "Touch ID"
        case .opticID:
            return "Optic ID"
        case .none:
            return "None"
        @unknown default:
            return "Unknown"
        }
    }
    
    // MARK: - App State Management
    
    func lockApp() {
        if authenticationMethod != .none {
            isAuthenticated = false
        }
    }
    
    func shouldShowAuthentication() -> Bool {
        return authenticationMethod != .none && !isAuthenticated
    }
}
