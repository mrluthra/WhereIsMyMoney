//
//  SpendTrackerApp.swift
//  SpendTracker
//
//  Created by Jatinder Luthra on 6/14/25.
//

import SwiftUI

@main
struct CashPotatoApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @StateObject private var currencyManager = CurrencyManager()
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(currencyManager) // Inject as environment object
        }
    }
}
