import SwiftUI

struct AddCategoryView: View {
    @ObservedObject var categoryStore: CategoryStore
    @Environment(\.dismiss) private var dismiss
    
    @State private var categoryName = ""
    @State private var selectedType: CustomCategory.TransactionType
    @State private var selectedColor = "Blue"
    @State private var selectedIcon = "star.fill"
    
    private let availableColors = ["Blue", "Green", "Purple", "Orange", "Red", "Yellow"]
    private let availableIcons = [
        "star.fill", "heart.fill", "house.fill", "car.fill", "airplane", "bicycle",
        "fork.knife", "cup.and.saucer", "cart.fill", "bag.fill", "creditcard.fill",
        "book.fill", "graduationcap.fill", "stethoscope", "pill.fill", "cross.fill",
        "gamecontroller.fill", "tv.fill", "music.note", "camera.fill", "phone.fill",
        "laptopcomputer", "desktopcomputer", "printer.fill", "wrench.and.screwdriver.fill",
        "hammer.fill", "scissors", "paintbrush.fill", "leaf.fill", "tree.fill",
        "sun.max.fill", "cloud.fill", "drop.fill", "flame.fill", "bolt.fill"
    ]
    
    init(categoryStore: CategoryStore, initialType: CustomCategory.TransactionType) {
        self.categoryStore = categoryStore
        self._selectedType = State(initialValue: initialType)
    }
    
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
        NavigationView {
            Form {
                Section(header: Text("Category Details")) {
                    TextField("Category Name", text: $categoryName)
                        .textInputAutocapitalization(.words)
                    
                    Picker("Type", selection: $selectedType) {
                        ForEach(CustomCategory.TransactionType.allCases, id: \.self) { type in
                            Text(type.rawValue).tag(type)
                        }
                    }
                    .pickerStyle(.segmented)
                }
                
                Section(header: Text("Appearance")) {
                    // Color Selection
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Color")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        
                        LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 6), spacing: 12) {
                            ForEach(availableColors, id: \.self) { color in
                                Button(action: { selectedColor = color }) {
                                    Circle()
                                        .fill(colorForName(color))
                                        .frame(width: 35, height: 35)
                                        .overlay(
                                            Circle()
                                                .stroke(selectedColor == color ? Color.primary : Color.clear, lineWidth: 2)
                                        )
                                        .scaleEffect(selectedColor == color ? 1.1 : 1.0)
                                        .animation(.easeInOut(duration: 0.2), value: selectedColor)
                                }
                                .buttonStyle(PlainButtonStyle())
                            }
                        }
                    }
                    .padding(.vertical, 8)
                    
                    // Icon Selection
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Icon")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        
                        LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 8), spacing: 12) {
                            ForEach(availableIcons, id: \.self) { icon in
                                Button(action: { selectedIcon = icon }) {
                                    ZStack {
                                        Circle()
                                            .fill(selectedIcon == icon ? colorForName(selectedColor).opacity(0.2) : Color.secondary.opacity(0.1))
                                            .frame(width: 35, height: 35)
                                        
                                        Image(systemName: icon)
                                            .font(.system(size: 14))
                                            .foregroundColor(selectedIcon == icon ? colorForName(selectedColor) : .secondary)
                                    }
                                    .scaleEffect(selectedIcon == icon ? 1.1 : 1.0)
                                    .animation(.easeInOut(duration: 0.2), value: selectedIcon)
                                }
                                .buttonStyle(PlainButtonStyle())
                            }
                        }
                    }
                    .padding(.vertical, 8)
                }
                
                if isFormValid {
                    Section(header: Text("Preview")) {
                        HStack(spacing: 16) {
                            ZStack {
                                Circle()
                                    .fill(colorForName(selectedColor).opacity(0.2))
                                    .frame(width: 40, height: 40)
                                
                                Image(systemName: selectedIcon)
                                    .font(.title3)
                                    .foregroundColor(colorForName(selectedColor))
                            }
                            
                            VStack(alignment: .leading, spacing: 4) {
                                Text(categoryName)
                                    .font(.headline)
                                Text(selectedType.rawValue)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            
                            Spacer()
                        }
                        .padding(.vertical, 4)
                    }
                }
            }
            .navigationTitle("Add Category")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        saveCategory()
                    }
                    .fontWeight(.semibold)
                    .disabled(!isFormValid)
                }
            }
        }
    }
    
    private var isFormValid: Bool {
        !categoryName.trimmingCharacters(in: .whitespaces).isEmpty
    }
    
    private func saveCategory() {
        let newCategory = CustomCategory(
            name: categoryName.trimmingCharacters(in: .whitespaces),
            icon: selectedIcon,
            color: selectedColor,
            type: selectedType
        )
        
        categoryStore.addCategory(newCategory)
        dismiss()
    }
}

#Preview {
    AddCategoryView(categoryStore: CategoryStore(), initialType: .expense)
}
