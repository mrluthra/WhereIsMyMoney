import SwiftUI

struct ManageCategoriesView: View {
    @StateObject private var categoryStore = CategoryStore()
    @State private var showingAddCategory = false
    @State private var selectedSegment = 0
    
    private var expenseCategories: [CustomCategory] {
        categoryStore.categoriesForType(.expense)
    }
    
    private var incomeCategories: [CustomCategory] {
        categoryStore.categoriesForType(.income)
    }
    
    var body: some View {
        NavigationView {
            VStack {
                // Segment Control
                Picker("Category Type", selection: $selectedSegment) {
                    Text("Expense").tag(0)
                    Text("Income").tag(1)
                }
                .pickerStyle(.segmented)
                .padding()
                
                // Categories List
                List {
                    ForEach(selectedSegment == 0 ? expenseCategories : incomeCategories) { category in
                        CategoryRowView(category: category, categoryStore: categoryStore)
                    }
                    .onDelete(perform: deleteCategories)
                }
            }
            .navigationTitle("Manage Categories")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showingAddCategory = true }) {
                        Image(systemName: "plus")
                    }
                }
            }
        }
        .sheet(isPresented: $showingAddCategory) {
            AddCategoryView(categoryStore: categoryStore, initialType: selectedSegment == 0 ? .expense : .income)
        }
    }
    
    private func deleteCategories(offsets: IndexSet) {
        let categories = selectedSegment == 0 ? expenseCategories : incomeCategories
        for index in offsets {
            let category = categories[index]
            categoryStore.deleteCategory(category)
        }
    }
}

struct CategoryRowView: View {
    let category: CustomCategory
    let categoryStore: CategoryStore
    
    private func colorForName(_ colorName: String) -> Color {
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
    
    var body: some View {
        HStack(spacing: 16) {
            // Icon
            ZStack {
                Circle()
                    .fill(colorForName(category.color).opacity(0.2))
                    .frame(width: 40, height: 40)
                
                Image(systemName: category.icon)
                    .font(.title3)
                    .foregroundColor(colorForName(category.color))
            }
            
            // Category Info
            VStack(alignment: .leading, spacing: 4) {
                Text(category.name)
                    .font(.headline)
                
                HStack {
                    Text(category.type.rawValue)
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    if category.isDefault {
                        Text("• Default")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
            
            Spacer()
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    ManageCategoriesView()
}
