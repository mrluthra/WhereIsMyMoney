import Foundation
import SwiftUI

class CategoryStore: ObservableObject {
    @Published var customCategories: [CustomCategory] = []
    
    private let userDefaults = UserDefaults.standard
    private let categoriesKey = "SavedCustomCategories"
    
    // Default categories
    private let defaultExpenseCategories = [
        CustomCategory(name: "Food & Dining", icon: "fork.knife", color: "Orange", type: .expense, isDefault: true),
        CustomCategory(name: "Transportation", icon: "car.fill", color: "Blue", type: .expense, isDefault: true),
        CustomCategory(name: "Shopping", icon: "bag.fill", color: "Purple", type: .expense, isDefault: true),
        CustomCategory(name: "Entertainment", icon: "tv.fill", color: "Red", type: .expense, isDefault: true),
        CustomCategory(name: "Bills & Utilities", icon: "doc.text.fill", color: "Yellow", type: .expense, isDefault: true),
        CustomCategory(name: "Healthcare", icon: "cross.fill", color: "Red", type: .expense, isDefault: true),
        CustomCategory(name: "Education", icon: "book.fill", color: "Blue", type: .expense, isDefault: true),
        CustomCategory(name: "Travel", icon: "airplane", color: "Green", type: .expense, isDefault: true),
        CustomCategory(name: "Other", icon: "questionmark.circle.fill", color: "Blue", type: .expense, isDefault: true)
    ]
    
    private let defaultIncomeCategories = [
        CustomCategory(name: "Salary", icon: "dollarsign.circle.fill", color: "Green", type: .income, isDefault: true),
        CustomCategory(name: "Freelance", icon: "laptopcomputer", color: "Blue", type: .income, isDefault: true),
        CustomCategory(name: "Investment", icon: "chart.line.uptrend.xyaxis", color: "Green", type: .income, isDefault: true),
        CustomCategory(name: "Gift", icon: "gift.fill", color: "Purple", type: .income, isDefault: true),
        CustomCategory(name: "Bonus", icon: "star.fill", color: "Yellow", type: .income, isDefault: true),
        CustomCategory(name: "Other", icon: "questionmark.circle.fill", color: "Green", type: .income, isDefault: true)
    ]
    
    init() {
        loadCategories()
        // Add default categories if none exist
        if customCategories.isEmpty {
            customCategories = defaultExpenseCategories + defaultIncomeCategories
            saveCategories()
        }
    }
    
    func addCategory(_ category: CustomCategory) {
        customCategories.append(category)
        saveCategories()
    }
    
    func deleteCategory(_ category: CustomCategory) {
        // Don't allow deletion of default categories
        if !category.isDefault {
            customCategories.removeAll { $0.id == category.id }
            saveCategories()
        }
    }
    
    func updateCategory(_ category: CustomCategory) {
        if let index = customCategories.firstIndex(where: { $0.id == category.id }) {
            customCategories[index] = category
            saveCategories()
        }
    }
    
    func categoriesForType(_ type: CustomCategory.TransactionType) -> [CustomCategory] {
        return customCategories.filter { $0.type == type }
    }
    
    private func saveCategories() {
        if let encoded = try? JSONEncoder().encode(customCategories) {
            userDefaults.set(encoded, forKey: categoriesKey)
        }
    }
    
    private func loadCategories() {
        if let data = userDefaults.data(forKey: categoriesKey),
           let decoded = try? JSONDecoder().decode([CustomCategory].self, from: data) {
            customCategories = decoded
        }
    }
}
