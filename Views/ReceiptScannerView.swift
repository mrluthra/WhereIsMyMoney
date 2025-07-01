import SwiftUI
import UIKit
import VisionKit
import PhotosUI

struct ReceiptScannerView: View {
    @ObservedObject var accountStore: AccountStore
    @ObservedObject var receiptManager: ReceiptManager
    @StateObject private var categoryStore = CategoryStore()
    @StateObject private var smartEngine = SmartCategorizationEngine()
    @StateObject private var payeeSuggestionEngine = PayeeSuggestionEngine()
    @Environment(\.dismiss) private var dismiss
    
    @EnvironmentObject var currencyManager: CurrencyManager
    
    @State private var showingImagePicker = false
    @State private var showingCamera = false
    @State private var showingPhotoPicker = false
    @State private var selectedImage: UIImage?
    @State private var isProcessing = false
    @State private var scannedData: ReceiptData?
    @State private var showingTransactionForm = false
    
    // Transaction form data
    @State private var receiptName = ""
    @State private var selectedAccountId: UUID?
    @State private var extractedPayee = ""
    @State private var extractedAmount = ""
    @State private var extractedDate = Date()
    @State private var selectedCategory: CustomCategory?
    @State private var notes = ""
    @State private var transactionType = Transaction.TransactionType.expense
    @State private var aiSuggestedCategory: CustomCategory?
    @State private var showingAISuggestion = false
    @State private var payeeSuggestions: [PayeeSuggestionEngine.PayeeSuggestion] = []
    @State private var showingPayeeSuggestions = false
    
    private var availableCategories: [CustomCategory] {
        categoryStore.categoriesForType(.expense) // Most receipts are expenses
    }
    
    private func colorForAccount(_ colorName: String) -> Color {
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
    
    private func colorForCategoryColor(_ colorName: String) -> Color {
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
            VStack(spacing: 20) {
                if selectedImage == nil {
                    // Image selection screen
                    imageSelectionView
                } else if isProcessing {
                    // Processing screen
                    processingView
                } else if showingTransactionForm {
                    // Transaction creation form
                    transactionFormView
                } else {
                    // Image preview and scan options
                    imagePreviewView
                }
            }
            .navigationTitle("Scan Receipt")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                if selectedImage != nil && !showingTransactionForm {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button("Retake") {
                            selectedImage = nil
                            scannedData = nil
                            showingAISuggestion = false
                            aiSuggestedCategory = nil
                        }
                    }
                }
            }
        }
        .sheet(isPresented: $showingCamera) {
            CameraView { image in
                selectedImage = image
                processImage(image)
            }
        }
        .sheet(isPresented: $showingPhotoPicker) {
            PhotoPickerView { image in
                selectedImage = image
                processImage(image)
            }
        }
    }
    
    // MARK: - Image Selection View
    
    private var imageSelectionView: some View {
        VStack(spacing: 30) {
            Spacer()
            
            // Header
            VStack(spacing: 16) {
                ZStack {
                    Circle()
                        .fill(LinearGradient(
                            colors: [.orange, .red],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ))
                        .frame(width: 100, height: 100)
                    
                    Image(systemName: "doc.text.viewfinder")
                        .font(.system(size: 45))
                        .foregroundColor(.white)
                }
                
                VStack(spacing: 8) {
                    HStack {
                        Text("AI-Powered Receipt Scanner")
                            .font(.title)
                            .fontWeight(.bold)
                        
                        Image(systemName: "sparkles")
                            .font(.title2)
                            .foregroundColor(.orange)
                    }
                    
                    Text("Automatically extract payee, amount, and suggest categories using machine learning")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }
            }
            
            Spacer()
            
            // Action buttons
            VStack(spacing: 16) {
                Button(action: {
                    showingCamera = true
                }) {
                    HStack {
                        Image(systemName: "camera.fill")
                            .font(.title2)
                        Text("Take Photo")
                            .font(.headline)
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(LinearGradient(
                        colors: [.orange, .red],
                        startPoint: .leading,
                        endPoint: .trailing
                    ))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                
                Button(action: {
                    showingPhotoPicker = true
                }) {
                    HStack {
                        Image(systemName: "photo.on.rectangle")
                            .font(.title2)
                        Text("Choose from Library")
                            .font(.headline)
                    }
                    .foregroundColor(.orange)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.orange.opacity(0.1))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                }
            }
            .padding(.horizontal)
            
            Spacer()
        }
    }
    
    // MARK: - Processing View
    
    private var processingView: some View {
        VStack(spacing: 30) {
            Spacer()
            
            // AI Processing Animation
            ZStack {
                Circle()
                    .fill(LinearGradient(
                        colors: [.blue, .purple],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ))
                    .frame(width: 120, height: 120)
                
                Image(systemName: "brain.head.profile")
                    .font(.system(size: 50))
                    .foregroundColor(.white)
            }
            .scaleEffect(1.0)
            .animation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true), value: isProcessing)
            
            VStack(spacing: 12) {
                Text("AI Processing Receipt...")
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Text("Using machine learning to extract transaction details")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                
                HStack {
                    Image(systemName: "sparkles")
                        .foregroundColor(.blue)
                    Text("Smart categorization enabled")
                        .font(.caption)
                        .foregroundColor(.blue)
                }
            }
            
            Spacer()
        }
    }
    
    // MARK: - Image Preview View
    
    private var imagePreviewView: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Image preview
                if let image = selectedImage {
                    Image(uiImage: image)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(maxHeight: 300)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .shadow(radius: 4)
                }
                
                // AI-extracted data preview
                if let data = scannedData {
                    VStack(spacing: 16) {
                        HStack {
                            Image(systemName: "brain.head.profile")
                                .foregroundColor(.blue)
                            Text("AI Detected Information")
                                .font(.headline)
                                .foregroundColor(.blue)
                            Image(systemName: "sparkles")
                                .foregroundColor(.blue)
                        }
                        
                        VStack(spacing: 12) {
                            if !data.payee.isEmpty {
                                HStack {
                                    Text("Business:")
                                        .fontWeight(.medium)
                                    Spacer()
                                    Text(data.payee)
                                        .foregroundColor(.secondary)
                                }
                            }
                            
                            if let amount = data.amount {
                                HStack {
                                    Text("Total Amount:")
                                        .fontWeight(.medium)
                                    Spacer()
                                    //Text("$\(amount, specifier: "%.2f")")
                                    Text(currencyManager.formatAmount(amount))
                                        .foregroundColor(.green)
                                        .fontWeight(.semibold)
                                }
                            }
                            
                            HStack {
                                Text("Date:")
                                    .fontWeight(.medium)
                                Spacer()
                                Text(data.date, style: .date)
                                    .foregroundColor(.secondary)
                            }
                        }
                        .padding()
                        .background(Color.blue.opacity(0.05))
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.blue.opacity(0.2), lineWidth: 1)
                        )
                    }
                }
                
                // Action buttons
                VStack(spacing: 12) {
                    Button(action: {
                        prepareTransactionForm()
                        showingTransactionForm = true
                    }) {
                        HStack {
                            Image(systemName: "plus.circle.fill")
                            Text("Create AI-Enhanced Transaction")
                        }
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(LinearGradient(
                            colors: [.green, .blue],
                            startPoint: .leading,
                            endPoint: .trailing
                        ))
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                    
                    Button(action: {
                        saveReceiptOnly()
                    }) {
                        HStack {
                            Image(systemName: "doc.badge.plus")
                            Text("Save Receipt Only")
                        }
                        .font(.headline)
                        .foregroundColor(.blue)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue.opacity(0.1))
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                }
            }
            .padding()
        }
    }
    
    // MARK: - Transaction Form View
    
    private var transactionFormView: some View {
        Form {
            Section(header: Text("Receipt Details")) {
                TextField("Receipt Name", text: $receiptName)
                    .textInputAutocapitalization(.words)
            }
            
            Section(header: Text("Account")) {
                if accountStore.accounts.isEmpty {
                    Text("No accounts available. Please add an account first.")
                        .foregroundColor(.secondary)
                } else {
                    Picker("Select Account", selection: $selectedAccountId) {
                        Text("Select Account").tag(UUID?.none)
                        ForEach(accountStore.accounts) { account in
                            HStack {
                                Image(systemName: account.icon)
                                    .foregroundColor(colorForAccount(account.color))
                                Text(account.name)
                            }
                            .tag(UUID?.some(account.id))
                        }
                    }
                }
            }
            
            // AI Suggestion Banner
            if showingAISuggestion, let suggested = aiSuggestedCategory {
                Section {
                    HStack(spacing: 12) {
                        // AI Icon
                        ZStack {
                            Circle()
                                .fill(Color.blue.opacity(0.2))
                                .frame(width: 35, height: 35)
                            
                            Image(systemName: "brain.head.profile")
                                .font(.system(size: 16))
                                .foregroundColor(.blue)
                        }
                        
                        VStack(alignment: .leading, spacing: 4) {
                            HStack {
                                Text("AI Suggestion")
                                    .font(.subheadline)
                                    .fontWeight(.semibold)
                                    .foregroundColor(.blue)
                                
                                Image(systemName: "sparkles")
                                    .font(.caption)
                                    .foregroundColor(.blue)
                            }
                            
                            Text("Smart category: \(suggested.name)")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                        
                        // Accept/Dismiss buttons
                        HStack(spacing: 8) {
                            Button("Use") {
                                selectedCategory = suggested
                                showingAISuggestion = false
                            }
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundColor(.white)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(Color.blue)
                            .clipShape(Capsule())
                            
                            Button("Dismiss") {
                                showingAISuggestion = false
                            }
                            .font(.caption)
                            .foregroundColor(.secondary)
                        }
                    }
                    .padding()
                    .background(Color.blue.opacity(0.05))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                }
            }
            
            Section(header: Text("Transaction Details")) {
                HStack {
                    Text("Amount:")
                    TextField("0.00", text: $extractedAmount)
                        .keyboardType(.decimalPad)
                        .multilineTextAlignment(.trailing)
                }
                
                VStack(spacing: 0) {
                    TextField("Payee", text: $extractedPayee)
                        .textInputAutocapitalization(.words)
                        .onChange(of: extractedPayee) { oldValue, newValue in
                            updatePayeeSuggestions(for: newValue)
                        }
                    
                    // Payee Suggestions Dropdown
                    if showingPayeeSuggestions && !payeeSuggestions.isEmpty {
                        PayeeSuggestionView(
                            suggestions: payeeSuggestions,
                            onSelect: { suggestion in
                                selectPayeeSuggestion(suggestion)
                            }
                        )
                        .padding(.top, 8)
                    }
                }
                
                DatePicker("Date", selection: $extractedDate, displayedComponents: .date)
            }
            
            Section(header: Text("Category")) {
                if availableCategories.isEmpty {
                    Text("No categories available. Please add categories first.")
                        .foregroundColor(.secondary)
                } else {
                    Picker("Select Category", selection: $selectedCategory) {
                        Text("Select Category").tag(CustomCategory?.none)
                        ForEach(availableCategories, id: \.id) { category in
                            HStack {
                                Image(systemName: category.icon)
                                    .foregroundColor(colorForCategoryColor(category.color))
                                Text(category.name)
                            }
                            .tag(CustomCategory?.some(category))
                        }
                    }
                }
            }
            
            Section(header: Text("Notes")) {
                TextField("Additional notes", text: $notes, axis: .vertical)
                    .lineLimit(3...6)
            }
            
            Section {
                Button(action: {
                    saveTransactionAndReceipt()
                }) {
                    HStack {
                        Image(systemName: "brain.head.profile")
                        Text("Save AI-Enhanced Transaction")
                    }
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(isFormValid ? LinearGradient(
                        colors: [.blue, .purple],
                        startPoint: .leading,
                        endPoint: .trailing
                    ) : LinearGradient(
                        colors: [.gray, .gray],
                        startPoint: .leading,
                        endPoint: .trailing
                    ))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                .disabled(!isFormValid)
            }
        }
    }
    
    // MARK: - Helper Methods
    
    private func processImage(_ image: UIImage) {
        isProcessing = true
        
        receiptManager.extractTextFromImage(image) { data in
            self.scannedData = data
            self.isProcessing = false
        }
    }
    
    private func prepareTransactionForm() {
        if let data = scannedData {
            extractedPayee = data.payee
            extractedAmount = data.amount.map { String(format: "%.2f", $0) } ?? ""
            extractedDate = data.date
            receiptName = data.payee.isEmpty ? "Receipt \(Date().formatted(date: .abbreviated, time: .omitted))" : "\(data.payee) Receipt"
            
            // AI category suggestion
            if !data.payee.isEmpty {
                let amountValue = data.amount ?? 0
                let suggestion = smartEngine.suggestCategory(
                    for: data.payee,
                    amount: amountValue,
                    existingCategories: availableCategories
                )
                
                if let suggestion = suggestion {
                    aiSuggestedCategory = suggestion
                    showingAISuggestion = true
                } else {
                    selectedCategory = availableCategories.first
                }
            }
        }
        
        // Auto-select first account if not already set
        if selectedAccountId == nil {
            selectedAccountId = accountStore.accounts.first?.id
        }
        
        // Auto-select first category if not set by AI
        if selectedCategory == nil && !showingAISuggestion {
            selectedCategory = availableCategories.first
        }
    }
    
    private var isFormValid: Bool {
        !receiptName.isEmpty &&
        !extractedPayee.isEmpty &&
        !extractedAmount.isEmpty &&
        Double(extractedAmount) != nil &&
        selectedAccountId != nil &&
        selectedCategory != nil
    }
    
    private func saveTransactionAndReceipt() {
        guard let image = selectedImage,
              let amount = Double(extractedAmount),
              let accountId = selectedAccountId,
              let category = selectedCategory else { return }
        
        // Save image to Photos and get identifier
        receiptManager.saveImageToPhotos(image) { photoIdentifier in
            // Create transaction
            let transaction = Transaction(
                amount: amount,
                category: TransactionCategory.other,
                accountId: accountId,
                date: extractedDate,
                payee: extractedPayee,
                type: transactionType,
                notes: "Category: \(category.name)" + (notes.isEmpty ? "" : " | \(notes)")
            )
            
            accountStore.addTransaction(transaction, to: accountId)
            
            // Create receipt
            let receipt = Receipt(
                name: receiptName,
                transactionId: transaction.id,
                photoIdentifier: photoIdentifier,
                date: extractedDate,
                payee: extractedPayee,
                amount: amount,
                notes: notes,
                ocrText: scannedData?.allText
            )
            
            receiptManager.addReceipt(receipt)
            
            dismiss()
        }
    }
    
    // MARK: - Payee Suggestion Methods
    
    private func updatePayeeSuggestions(for query: String) {
        if query.count >= 2 {
            payeeSuggestions = payeeSuggestionEngine.getPayeeSuggestions(
                for: query,
                from: accountStore.accounts,
                categories: availableCategories,
                limit: 5
            )
            showingPayeeSuggestions = !payeeSuggestions.isEmpty
        } else {
            payeeSuggestions = []
            showingPayeeSuggestions = false
        }
    }
    
    private func selectPayeeSuggestion(_ suggestion: PayeeSuggestionEngine.PayeeSuggestion) {
        extractedPayee = suggestion.name
        showingPayeeSuggestions = false
        
        // Auto-suggest category based on payee's history
        if let matchingCategory = availableCategories.first(where: {
            $0.name.lowercased() == suggestion.mostCommonCategory.lowercased()
        }) {
            selectedCategory = matchingCategory
            showingAISuggestion = false // Don't show AI suggestion if we have historical data
        }
        
        // Pre-fill amount if user has consistent spending with this payee and amount is empty
        if suggestion.averageAmount > 0 && extractedAmount.isEmpty {
            extractedAmount = String(format: "%.2f", suggestion.averageAmount)
        }
    }
    
    private func saveReceiptOnly() {
        guard let image = selectedImage else { return }
        
        receiptManager.saveImageToPhotos(image) { photoIdentifier in
            let receipt = Receipt(
                name: scannedData?.payee.isEmpty == false ? "\(scannedData!.payee) Receipt" : "Receipt \(Date().formatted(date: .abbreviated, time: .omitted))",
                photoIdentifier: photoIdentifier,
                date: scannedData?.date ?? Date(),
                payee: scannedData?.payee ?? "",
                amount: scannedData?.amount,
                ocrText: scannedData?.allText
            )
            
            receiptManager.addReceipt(receipt)
            
            dismiss()
        }
    }
}

// MARK: - Camera View

struct CameraView: UIViewControllerRepresentable {
    let onImageCaptured: (UIImage) -> Void
    
    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.sourceType = .camera
        picker.delegate = context.coordinator
        return picker
    }
    
    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(onImageCaptured: onImageCaptured)
    }
    
    class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let onImageCaptured: (UIImage) -> Void
        
        init(onImageCaptured: @escaping (UIImage) -> Void) {
            self.onImageCaptured = onImageCaptured
        }
        
        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
            if let image = info[.originalImage] as? UIImage {
                onImageCaptured(image)
            }
            picker.dismiss(animated: true)
        }
        
        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            picker.dismiss(animated: true)
        }
    }
}

// MARK: - Photo Picker View

struct PhotoPickerView: UIViewControllerRepresentable {
    let onImageSelected: (UIImage) -> Void
    
    func makeUIViewController(context: Context) -> PHPickerViewController {
        var config = PHPickerConfiguration()
        config.filter = .images
        config.selectionLimit = 1
        
        let picker = PHPickerViewController(configuration: config)
        picker.delegate = context.coordinator
        return picker
    }
    
    func updateUIViewController(_ uiViewController: PHPickerViewController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(onImageSelected: onImageSelected)
    }
    
    class Coordinator: NSObject, PHPickerViewControllerDelegate {
        let onImageSelected: (UIImage) -> Void
        
        init(onImageSelected: @escaping (UIImage) -> Void) {
            self.onImageSelected = onImageSelected
        }
        
        func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
            picker.dismiss(animated: true)
            
            guard let result = results.first else { return }
            
            result.itemProvider.loadObject(ofClass: UIImage.self) { image, error in
                if let image = image as? UIImage {
                    DispatchQueue.main.async {
                        self.onImageSelected(image)
                    }
                }
            }
        }
    }
}

#Preview {
    ReceiptScannerView(accountStore: AccountStore(), receiptManager: ReceiptManager())
}
