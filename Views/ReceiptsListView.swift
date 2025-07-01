import SwiftUI
import Photos

struct ReceiptsListView: View {
    @ObservedObject var receiptManager: ReceiptManager
    @ObservedObject var accountStore: AccountStore
    @EnvironmentObject var currencyManager: CurrencyManager
    @Environment(\.dismiss) private var dismiss
    
    @State private var searchText = ""
    @State private var showingDeleteAlert = false
    @State private var receiptToDelete: Receipt?
    @State private var selectedReceipt: Receipt?
    @State private var showingReceiptDetail = false
    
    private var filteredReceipts: [Receipt] {
        if searchText.isEmpty {
            return receiptManager.receipts.sorted { $0.date > $1.date }
        } else {
            return receiptManager.receipts.filter { receipt in
                receipt.name.localizedCaseInsensitiveContains(searchText) ||
                receipt.payee.localizedCaseInsensitiveContains(searchText) ||
                receipt.notes?.localizedCaseInsensitiveContains(searchText) == true
            }.sorted { $0.date > $1.date }
        }
    }
    
    private var groupedReceipts: [(String, [Receipt])] {
        let grouped = Dictionary(grouping: filteredReceipts) { receipt in
            let calendar = Calendar.current
            if calendar.isDateInToday(receipt.date) {
                return "Today"
            } else if calendar.isDateInYesterday(receipt.date) {
                return "Yesterday"
            } else if calendar.isDate(receipt.date, equalTo: Date(), toGranularity: .weekOfYear) {
                return "This Week"
            } else if calendar.isDate(receipt.date, equalTo: Date(), toGranularity: .month) {
                return "This Month"
            } else {
                let formatter = DateFormatter()
                formatter.dateFormat = "MMMM yyyy"
                return formatter.string(from: receipt.date)
            }
        }
        
        let sortOrder = ["Today", "Yesterday", "This Week", "This Month"]
        
        return grouped.sorted { first, second in
            let firstIndex = sortOrder.firstIndex(of: first.key) ?? Int.max
            let secondIndex = sortOrder.firstIndex(of: second.key) ?? Int.max
            
            if firstIndex != Int.max && secondIndex != Int.max {
                return firstIndex < secondIndex
            } else if firstIndex != Int.max {
                return true
            } else if secondIndex != Int.max {
                return false
            } else {
                return first.key > second.key
            }
        }
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                searchBarSection
                
                if filteredReceipts.isEmpty {
                    emptyStateView
                } else {
                    receiptsListSection
                }
            }
            .navigationTitle("Receipts")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .fontWeight(.semibold)
                }
            }
        }
        .sheet(isPresented: $showingReceiptDetail) {
            if let receipt = selectedReceipt {
                ReceiptDetailView(
                    receipt: receipt,
                    receiptManager: receiptManager,
                    accountStore: accountStore,
                    currencyManager: currencyManager
                )
            }
        }
        .alert("Delete Receipt", isPresented: $showingDeleteAlert) {
            Button("Cancel", role: .cancel) {
                receiptToDelete = nil
            }
            Button("Delete", role: .destructive) {
                if let receipt = receiptToDelete {
                    receiptManager.deleteReceipt(receipt)
                    receiptToDelete = nil
                }
            }
        } message: {
            Text("Are you sure you want to delete this receipt? This will also remove it from your Photos library. This action cannot be undone.")
        }
    }
    
    // MARK: - View Components
    
    private var searchBarSection: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.secondary)
            
            TextField("Search receipts...", text: $searchText)
                .textFieldStyle(PlainTextFieldStyle())
            
            if !searchText.isEmpty {
                Button(action: { searchText = "" }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .clipShape(RoundedRectangle(cornerRadius: 10))
        .padding()
    }
    
    private var receiptsListSection: some View {
        List {
            ForEach(groupedReceipts, id: \.0) { section, receipts in
                Section(header: Text(section)) {
                    ForEach(receipts) { receipt in
                        ReceiptRowView(
                            receipt: receipt,
                            accountStore: accountStore,
                            currencyManager: currencyManager,
                            onTap: {
                                selectedReceipt = receipt
                                showingReceiptDetail = true
                            },
                            onDelete: {
                                receiptToDelete = receipt
                                showingDeleteAlert = true
                            }
                        )
                    }
                }
            }
        }
        .listStyle(InsetGroupedListStyle())
    }
    
    private var emptyStateView: some View {
        VStack(spacing: 20) {
            Image(systemName: searchText.isEmpty ? "doc.text" : "magnifyingglass")
                .font(.system(size: 60))
                .foregroundColor(.secondary)
            
            Text(searchText.isEmpty ? "No Receipts Yet" : "No Matching Receipts")
                .font(.title2)
                .fontWeight(.semibold)
                .foregroundColor(.secondary)
            
            Text(searchText.isEmpty
                 ? "Scan your first receipt to get started tracking expenses with photos"
                 : "Try adjusting your search terms")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - Receipt Row View

struct ReceiptRowView: View {
    let receipt: Receipt
    let accountStore: AccountStore
    let currencyManager: CurrencyManager
    let onTap: () -> Void
    let onDelete: () -> Void
    
    @State private var receiptImage: UIImage?
    @State private var isLoadingImage = false
    
    private var associatedAccount: Account? {
        guard let transactionId = receipt.transactionId else { return nil }
        return accountStore.accounts.first { account in
            account.transactions.contains { $0.id == transactionId }
        }
    }
    
    private var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: receipt.date)
    }
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 16) {
                receiptThumbnail
                receiptDetails
                Spacer()
                amountAndActions
            }
            .padding(.vertical, 4)
        }
        .buttonStyle(PlainButtonStyle())
        .contextMenu {
            contextMenuItems
        }
        .onAppear {
            loadReceiptImage()
        }
    }
    
    // MARK: - Row Components
    
    private var receiptThumbnail: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 8)
                .fill(Color(.systemGray5))
                .frame(width: 60, height: 60)
            
            if isLoadingImage {
                ProgressView()
                    .scaleEffect(0.8)
            } else if let image = receiptImage {
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: 60, height: 60)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
            } else {
                Image(systemName: "doc.text.image")
                    .font(.title2)
                    .foregroundColor(.secondary)
            }
        }
    }
    
    private var receiptDetails: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(receipt.name)
                .font(.headline)
                .foregroundColor(.primary)
                .lineLimit(1)
            
            if !receipt.payee.isEmpty {
                Text(receipt.payee)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .lineLimit(1)
            }
            
            receiptMetadata
        }
    }
    
    private var receiptMetadata: some View {
        HStack {
            Text(formattedDate)
                .font(.caption)
                .foregroundColor(.secondary)
            
            if let account = associatedAccount {
                Text("•")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Text(account.name)
                    .font(.caption)
                    .foregroundColor(.blue)
            }
        }
    }
    
    private var amountAndActions: some View {
        VStack(alignment: .trailing, spacing: 8) {
            if let amount = receipt.amount {
                Text(currencyManager.formatAmount(amount))
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(.green)
            }
            
            actionsMenu
        }
    }
    
    private var actionsMenu: some View {
        Menu {
            menuItems
        } label: {
            Image(systemName: "ellipsis.circle")
                .font(.title3)
                .foregroundColor(.secondary)
        }
    }
    
    private var menuItems: some View {
        Group {
            Button(action: onTap) {
                Label("View Details", systemImage: "eye")
            }
            
            if receipt.photoIdentifier != nil {
                Button(action: {
                    openInPhotos()
                }) {
                    Label("Open in Photos", systemImage: "photo")
                }
            }
            
            Divider()
            
            Button(action: onDelete) {
                Label("Delete Receipt", systemImage: "trash")
            }
        }
    }
    
    private var contextMenuItems: some View {
        Group {
            Button(action: onTap) {
                Label("View Details", systemImage: "eye")
            }
            
            if receipt.photoIdentifier != nil {
                Button(action: {
                    openInPhotos()
                }) {
                    Label("Open in Photos", systemImage: "photo")
                }
            }
            
            Button(action: onDelete) {
                Label("Delete Receipt", systemImage: "trash")
            }
        }
    }
    
    // MARK: - Helper Methods
    
    private func loadReceiptImage() {
        guard let photoIdentifier = receipt.photoIdentifier, receiptImage == nil else { return }
        
        isLoadingImage = true
        ReceiptManager().loadImageFromPhotos(identifier: photoIdentifier) { image in
            self.receiptImage = image
            self.isLoadingImage = false
        }
    }
    
    private func openInPhotos() {
        guard let photoIdentifier = receipt.photoIdentifier else { return }
        
        let fetchResult = PHAsset.fetchAssets(withLocalIdentifiers: [photoIdentifier], options: nil)
        guard fetchResult.firstObject != nil else { return }
        
        if let url = URL(string: "photos-redirect://") {
            UIApplication.shared.open(url)
        }
    }
}

// MARK: - Receipt Detail View

struct ReceiptDetailView: View {
    let receipt: Receipt
    @ObservedObject var receiptManager: ReceiptManager
    @ObservedObject var accountStore: AccountStore
    let currencyManager: CurrencyManager
    @Environment(\.dismiss) private var dismiss
    
    @State private var receiptImage: UIImage?
    @State private var isLoadingImage = true
    @State private var showingDeleteAlert = false
    @State private var showingEditSheet = false
    
    private var associatedTransaction: Transaction? {
        guard let transactionId = receipt.transactionId else { return nil }
        for account in accountStore.accounts {
            if let transaction = account.transactions.first(where: { $0.id == transactionId }) {
                return transaction
            }
        }
        return nil
    }
    
    private var associatedAccount: Account? {
        guard let transactionId = receipt.transactionId else { return nil }
        return accountStore.accounts.first { account in
            account.transactions.contains { $0.id == transactionId }
        }
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    receiptImageSection
                    receiptDetailsSection
                }
            }
            .navigationTitle("Receipt Details")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Close") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    actionsMenu
                }
            }
        }
        .onAppear {
            print("ReceiptDetailView appeared for receipt: \(receipt.name)")
            print("Photo identifier: \(receipt.photoIdentifier ?? "nil")")
            loadReceiptImage()
        }
        .alert("Delete Receipt", isPresented: $showingDeleteAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Delete", role: .destructive) {
                receiptManager.deleteReceipt(receipt)
                dismiss()
            }
        } message: {
            Text("Are you sure you want to delete this receipt? This will also remove it from your Photos library. This action cannot be undone.")
        }
        .sheet(isPresented: $showingEditSheet) {
            EditReceiptView(receipt: receipt, receiptManager: receiptManager, currencyManager: currencyManager)
        }
    }
    
    // MARK: - View Components
    
    private var receiptImageSection: some View {
        Group {
            if isLoadingImage {
                loadingImageView
            } else if let image = receiptImage {
                successImageView(image: image)
            } else {
                errorImageView
            }
        }
        .padding(.horizontal)
    }
    
    private var loadingImageView: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemGray6))
                .frame(height: 300)
            
            VStack(spacing: 12) {
                ProgressView()
                    .scaleEffect(1.5)
                Text("Loading receipt...")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
    }
    
    private func successImageView(image: UIImage) -> some View {
        VStack(spacing: 12) {
            Image(uiImage: image)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(maxHeight: 400)
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .shadow(radius: 4)
                .onTapGesture {
                    openInPhotos()
                }
            
            Text("Tap to open in Photos")
                .font(.caption)
                .foregroundColor(.blue)
        }
    }
    
    private var errorImageView: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemGray6))
                .frame(height: 200)
            
            VStack(spacing: 8) {
                Image(systemName: "exclamationmark.triangle")
                    .font(.system(size: 40))
                    .foregroundColor(.orange)
                Text("Image not available")
                    .font(.headline)
                    .foregroundColor(.secondary)
                Text("The receipt image could not be loaded")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
        }
    }
    
    private var receiptDetailsSection: some View {
        VStack(spacing: 16) {
            basicInfoSection
            
            if let transaction = associatedTransaction, let account = associatedAccount {
                associatedTransactionSection(transaction: transaction, account: account)
            }
            
            if let ocrText = receipt.ocrText, !ocrText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                ocrTextSection(ocrText: ocrText)
            }
        }
        .padding(.horizontal)
    }
    
    private var basicInfoSection: some View {
        DetailSection(title: "Receipt Information") {
            DetailRow(label: "Name", value: receipt.name)
            DetailRow(label: "Date", value: receipt.date.formatted(date: .abbreviated, time: .omitted))
            
            if !receipt.payee.isEmpty {
                DetailRow(label: "Payee", value: receipt.payee)
            }
            
            if let amount = receipt.amount {
                DetailRow(label: "Amount", value: currencyManager.formatAmount(amount))
            }
            
            if let notes = receipt.notes, !notes.isEmpty {
                DetailRow(label: "Notes", value: notes)
            }
        }
    }
    
    private func associatedTransactionSection(transaction: Transaction, account: Account) -> some View {
        DetailSection(title: "Associated Transaction") {
            DetailRow(label: "Account", value: account.name)
            DetailRow(label: "Type", value: transaction.type.rawValue)
            DetailRow(label: "Amount", value: currencyManager.formatAmount(transaction.amount))
            DetailRow(label: "Date", value: transaction.date.formatted(date: .abbreviated, time: .omitted))
        }
    }
    
    private func ocrTextSection(ocrText: String) -> some View {
        DetailSection(title: "Extracted Text") {
            Text(ocrText)
                .font(.caption)
                .foregroundColor(.secondary)
                .padding()
                .background(Color(.systemGray6))
                .clipShape(RoundedRectangle(cornerRadius: 8))
        }
    }
    
    private var actionsMenu: some View {
        Menu {
            if receipt.photoIdentifier != nil {
                Button(action: {
                    openInPhotos()
                }) {
                    Label("Open in Photos", systemImage: "photo")
                }
            }
            
            Button(action: { showingEditSheet = true }) {
                Label("Edit Receipt", systemImage: "pencil")
            }
            
            Divider()
            
            Button(action: { showingDeleteAlert = true }) {
                Label("Delete Receipt", systemImage: "trash")
            }
        } label: {
            Image(systemName: "ellipsis.circle")
        }
    }
    
    // MARK: - Helper Methods
    
    private func loadReceiptImage() {
        print("Loading receipt image...")
        guard let photoIdentifier = receipt.photoIdentifier else {
            print("No photo identifier found")
            isLoadingImage = false
            return
        }
        
        print("Photo identifier: \(photoIdentifier)")
        isLoadingImage = true
        
        receiptManager.loadImageFromPhotos(identifier: photoIdentifier) { image in
            print("Image loaded: \(image != nil ? "Success" : "Failed")")
            DispatchQueue.main.async {
                self.receiptImage = image
                self.isLoadingImage = false
            }
        }
    }
    
    private func openInPhotos() {
        guard let photoIdentifier = receipt.photoIdentifier else { return }
        
        let fetchResult = PHAsset.fetchAssets(withLocalIdentifiers: [photoIdentifier], options: nil)
        guard fetchResult.firstObject != nil else { return }
        
        if let url = URL(string: "photos-redirect://") {
            UIApplication.shared.open(url)
        }
    }
}

// MARK: - Helper Views

struct DetailSection<Content: View>: View {
    let title: String
    let content: Content
    
    init(title: String, @ViewBuilder content: () -> Content) {
        self.title = title
        self.content = content()
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.headline)
                .foregroundColor(.primary)
            
            VStack(spacing: 8) {
                content
            }
            .padding()
            .background(Color(.systemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 1)
        }
    }
}

struct DetailRow: View {
    let label: String
    let value: String
    
    var body: some View {
        HStack {
            Text(label)
                .font(.subheadline)
                .foregroundColor(.secondary)
            Spacer()
            Text(value)
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(.primary)
        }
    }
}

// MARK: - Edit Receipt View

struct EditReceiptView: View {
    let receipt: Receipt
    @ObservedObject var receiptManager: ReceiptManager
    let currencyManager: CurrencyManager
    @Environment(\.dismiss) private var dismiss
    
    @State private var receiptName: String
    @State private var notes: String
    
    init(receipt: Receipt, receiptManager: ReceiptManager, currencyManager: CurrencyManager) {
        self.receipt = receipt
        self.receiptManager = receiptManager
        self.currencyManager = currencyManager
        self._receiptName = State(initialValue: receipt.name)
        self._notes = State(initialValue: receipt.notes ?? "")
    }
    
    var body: some View {
        NavigationView {
            Form {
                receiptDetailsSection
                informationSection
            }
            .navigationTitle("Edit Receipt")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        saveChanges()
                    }
                    .fontWeight(.semibold)
                    .disabled(receiptName.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
        }
    }
    
    private var receiptDetailsSection: some View {
        Section(header: Text("Receipt Details")) {
            TextField("Receipt Name", text: $receiptName)
                .textInputAutocapitalization(.words)
            
            TextField("Notes", text: $notes, axis: .vertical)
                .lineLimit(3...6)
        }
    }
    
    private var informationSection: some View {
        Section(header: Text("Information")) {
            HStack {
                Text("Payee")
                Spacer()
                Text(receipt.payee.isEmpty ? "Not detected" : receipt.payee)
                    .foregroundColor(.secondary)
            }
            
            HStack {
                Text("Amount")
                Spacer()
                if let amount = receipt.amount {
                    Text(currencyManager.formatAmount(amount))
                        .foregroundColor(.secondary)
                } else {
                    Text("Not detected")
                        .foregroundColor(.secondary)
                }
            }
            
            HStack {
                Text("Date")
                Spacer()
                Text(receipt.date.formatted(date: .abbreviated, time: .omitted))
                    .foregroundColor(.secondary)
            }
        }
    }
    
    private func saveChanges() {
        var updatedReceipt = receipt
        updatedReceipt.name = receiptName.trimmingCharacters(in: .whitespaces)
        updatedReceipt.notes = notes.trimmingCharacters(in: .whitespaces).isEmpty ? nil : notes.trimmingCharacters(in: .whitespaces)
        
        receiptManager.updateReceipt(updatedReceipt)
        dismiss()
    }
}

#Preview {
    ReceiptsListView(receiptManager: ReceiptManager(), accountStore: AccountStore())
        .environmentObject(CurrencyManager())
}
