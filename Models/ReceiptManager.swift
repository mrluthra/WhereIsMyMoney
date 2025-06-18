import Foundation
import UIKit
import Vision
import VisionKit
import Photos

class ReceiptManager: ObservableObject {
    @Published var receipts: [Receipt] = []
    
    private let userDefaults = UserDefaults.standard
    private let receiptsKey = "SavedReceipts"
    
    init() {
        loadReceipts()
    }
    
    // MARK: - Receipt Management
    
    func addReceipt(_ receipt: Receipt) {
        receipts.append(receipt)
        saveReceipts()
    }
    
    func deleteReceipt(_ receipt: Receipt) {
        // Delete the image file from Photos if it exists
        if let photoIdentifier = receipt.photoIdentifier {
            deletePhotoFromLibrary(identifier: photoIdentifier)
        }
        
        receipts.removeAll { $0.id == receipt.id }
        saveReceipts()
    }
    
    func updateReceipt(_ receipt: Receipt) {
        if let index = receipts.firstIndex(where: { $0.id == receipt.id }) {
            receipts[index] = receipt
            saveReceipts()
        }
    }
    
    func getReceiptsForTransaction(_ transactionId: UUID) -> [Receipt] {
        return receipts.filter { $0.transactionId == transactionId }
    }
    
    // MARK: - OCR Text Recognition
    
    func extractTextFromImage(_ image: UIImage, completion: @escaping (ReceiptData) -> Void) {
        guard let cgImage = image.cgImage else {
            completion(ReceiptData(payee: "", amount: nil, date: Date(), allText: ""))
            return
        }
        
        let request = VNRecognizeTextRequest { request, error in
            guard let observations = request.results as? [VNRecognizedTextObservation] else {
                DispatchQueue.main.async {
                    completion(ReceiptData(payee: "", amount: nil, date: Date(), allText: ""))
                }
                return
            }
            
            var allText = ""
            var detectedAmount: Double?
            var detectedPayee = ""
            var detectedDate = Date()
            
            // Extract all text
            for observation in observations {
                guard let topCandidate = observation.topCandidates(1).first else { continue }
                allText += topCandidate.string + "\n"
            }
            
            // Parse the text for amount, payee, and date
            let parsedData = self.parseReceiptText(allText)
            detectedAmount = parsedData.amount
            detectedPayee = parsedData.payee
            detectedDate = parsedData.date ?? Date()
            
            DispatchQueue.main.async {
                completion(ReceiptData(
                    payee: detectedPayee,
                    amount: detectedAmount,
                    date: detectedDate,
                    allText: allText
                ))
            }
        }
        
        request.recognitionLevel = .accurate
        request.usesLanguageCorrection = true
        
        let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
        
        DispatchQueue.global(qos: .userInitiated).async {
            do {
                try handler.perform([request])
            } catch {
                DispatchQueue.main.async {
                    completion(ReceiptData(payee: "", amount: nil, date: Date(), allText: ""))
                }
            }
        }
    }
    
    // MARK: - Text Parsing Logic
    
    private func parseReceiptText(_ text: String) -> (amount: Double?, payee: String, date: Date?) {
        let lines = text.components(separatedBy: .newlines).map { $0.trimmingCharacters(in: .whitespaces) }
        
        var detectedAmount: Double?
        var detectedPayee = ""
        var detectedDate: Date?
        
        // IMPROVED: More sophisticated amount detection
        detectedAmount = findTotalAmount(in: lines)
        
        // IMPROVED: Better payee detection
        detectedPayee = findPayeeName(in: lines)
        
        // IMPROVED: Enhanced date detection
        detectedDate = findReceiptDate(in: lines)
        
        return (detectedAmount, detectedPayee, detectedDate)
    }
    
    // MARK: - Enhanced Amount Detection
    
    private func findTotalAmount(in lines: [String]) -> Double? {
        var amounts: [(amount: Double, priority: Int, lineIndex: Int)] = []
        
        // Priority-based amount detection
        for (index, line) in lines.enumerated() {
            let cleanLine = line.uppercased()
            
            // Find all dollar amounts in this line
            let dollarAmounts = extractDollarAmounts(from: line)
            
            for amount in dollarAmounts {
                var priority = 0
                
                // HIGHEST PRIORITY: Lines with "TOTAL" keywords
                if cleanLine.contains("TOTAL") || cleanLine.contains("AMOUNT DUE") || cleanLine.contains("BALANCE DUE") {
                    priority = 100
                } else if cleanLine.contains("SUBTOTAL") && !cleanLine.contains("TAX") {
                    priority = 90
                } else if cleanLine.contains("GRAND TOTAL") || cleanLine.contains("FINAL TOTAL") {
                    priority = 95
                }
                // HIGH PRIORITY: Lines at the bottom of receipt (likely totals)
                else if index > lines.count - 10 { // Last 10 lines
                    if cleanLine.contains("DUE") || cleanLine.contains("OWING") || cleanLine.contains("BALANCE") {
                        priority = 85
                    } else if isLikelyTotalLine(cleanLine) {
                        priority = 80
                    } else {
                        priority = 60 // Bottom section but no total keywords
                    }
                }
                // MEDIUM PRIORITY: Lines with tax (often near total)
                else if cleanLine.contains("TAX") && amount > 1.0 {
                    priority = 50
                }
                // LOW PRIORITY: Regular amounts
                else if amount > 0.50 { // Ignore very small amounts (likely individual item prices)
                    priority = 20
                }
                
                // BONUS: Larger amounts get higher priority (totals are usually larger)
                if amount > 10.0 { priority += 10 }
                if amount > 50.0 { priority += 10 }
                if amount > 100.0 { priority += 5 }
                
                amounts.append((amount: amount, priority: priority, lineIndex: index))
            }
        }
        
        // Sort by priority (highest first), then by amount (largest first)
        amounts.sort { first, second in
            if first.priority == second.priority {
                return first.amount > second.amount
            }
            return first.priority > second.priority
        }
        
        // Return the highest priority amount
        return amounts.first?.amount
    }
    
    private func extractDollarAmounts(from text: String) -> [Double] {
        var amounts: [Double] = []
        
        // Multiple regex patterns for different dollar formats
        let patterns = [
            #"\$(\d+\.?\d*)"#,                    // $123.45 or $123
            #"(\d+\.\d{2})\s*(?:USD|\$|usd)"#,    // 123.45 USD or 123.45$
            #"(?:USD|usd|\$)\s*(\d+\.?\d*)"#,     // USD 123.45 or $123.45
            #"(\d+\.\d{2})(?=\s*$)"#              // 123.45 at end of line
        ]
        
        for pattern in patterns {
            if let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive) {
                let range = NSRange(location: 0, length: text.utf16.count)
                let matches = regex.matches(in: text, options: [], range: range)
                
                for match in matches {
                    let amountRange = Range(match.range(at: 1), in: text)
                    if let amountRange = amountRange {
                        let amountString = String(text[amountRange])
                        if let amount = Double(amountString), amount > 0 {
                            amounts.append(amount)
                        }
                    }
                }
            }
        }
        
        return amounts.sorted { $0 > $1 } // Largest first
    }
    
    private func isLikelyTotalLine(_ line: String) -> Bool {
        let totalIndicators = [
            "TOTAL", "AMOUNT", "DUE", "BALANCE", "OWING", "PAY", "CHARGE",
            "FINAL", "GRAND", "NET", "SUMMARY", "PAYMENT"
        ]
        
        return totalIndicators.contains { line.contains($0) }
    }
    
    // MARK: - Enhanced Payee Detection
    
    private func findPayeeName(in lines: [String]) -> String {
        var candidates: [(name: String, priority: Int)] = []
        
        for (index, line) in lines.enumerated() {
            let cleanLine = line.trimmingCharacters(in: .whitespaces)
            
            // Skip empty lines or very short lines
            guard cleanLine.count >= 3 && cleanLine.count <= 50 else { continue }
            
            var priority = 0
            
            // HIGHEST PRIORITY: First few lines (business name usually at top)
            if index < 3 {
                priority = 100
            } else if index < 6 {
                priority = 80
            }
            
            // REDUCE PRIORITY for address-like content
            if isAddressLine(cleanLine) {
                priority -= 50
            }
            
            // REDUCE PRIORITY for phone numbers
            if isPhoneNumber(cleanLine) {
                priority -= 40
            }
            
            // REDUCE PRIORITY for dates
            if isDateLine(cleanLine) {
                priority -= 30
            }
            
            // REDUCE PRIORITY for lines with lots of numbers
            if hasLotsOfNumbers(cleanLine) {
                priority -= 20
            }
            
            // INCREASE PRIORITY for lines that look like business names
            if looksLikeBusinessName(cleanLine) {
                priority += 30
            }
            
            // INCREASE PRIORITY for longer lines (business names are often longer)
            if cleanLine.count > 10 {
                priority += 10
            }
            
            // Only consider lines with reasonable priority
            if priority > 20 {
                candidates.append((name: cleanLine, priority: priority))
            }
        }
        
        // Sort by priority and return the best candidate
        candidates.sort { $0.priority > $1.priority }
        return candidates.first?.name ?? ""
    }
    
    private func isAddressLine(_ line: String) -> Bool {
        let addressKeywords = ["STREET", "AVENUE", "ROAD", "BLVD", "BOULEVARD", "DRIVE", "LANE", "WAY", "ST", "AVE", "RD", "DR"]
        let upperLine = line.uppercased()
        return addressKeywords.contains { upperLine.contains($0) } ||
               line.range(of: #"\d+\s+\w+\s+(ST|AVE|RD|BLVD|STREET|AVENUE|ROAD)"#, options: .regularExpression) != nil
    }
    
    private func isPhoneNumber(_ line: String) -> Bool {
        return line.range(of: #"\(?\d{3}\)?[-.\s]?\d{3}[-.\s]?\d{4}"#, options: .regularExpression) != nil
    }
    
    private func isDateLine(_ line: String) -> Bool {
        let datePatterns = [
            #"\d{1,2}[/\-]\d{1,2}[/\-]\d{2,4}"#,
            #"\d{4}[/\-]\d{1,2}[/\-]\d{1,2}"#
        ]
        
        return datePatterns.contains { pattern in
            line.range(of: pattern, options: .regularExpression) != nil
        }
    }
    
    private func hasLotsOfNumbers(_ line: String) -> Bool {
        let numberCount = line.filter { $0.isNumber }.count
        return numberCount > line.count / 3 // More than 1/3 numbers
    }
    
    private func looksLikeBusinessName(_ line: String) -> Bool {
        // Common business suffixes and patterns
        let businessKeywords = ["LLC", "INC", "CORP", "LTD", "CO", "COMPANY", "RESTAURANT", "CAFE", "STORE", "SHOP", "MARKET"]
        let upperLine = line.uppercased()
        
        return businessKeywords.contains { upperLine.contains($0) } ||
               line.range(of: #"^[A-Z][A-Z\s&'.-]+$"#, options: .regularExpression) != nil
    }
    
    // MARK: - Enhanced Date Detection
    
    private func findReceiptDate(in lines: [String]) -> Date? {
        let dateFormatter = DateFormatter()
        let datePatterns = [
            "MM/dd/yyyy", "MM-dd-yyyy", "yyyy-MM-dd", "dd/MM/yyyy",
            "MM/dd/yy", "MM-dd-yy", "dd/MM/yy", "yy-MM-dd",
            "MMM dd, yyyy", "dd MMM yyyy", "yyyy MMM dd"
        ]
        
        // Look for dates in the first 20 lines (dates usually near top)
        for line in Array(lines.prefix(20)) {
            // Clean the line and extract potential date strings
            let cleanLine = line.trimmingCharacters(in: .whitespaces)
            
            for pattern in datePatterns {
                dateFormatter.dateFormat = pattern
                
                // Try to find date pattern in the line
                if let regex = try? NSRegularExpression(pattern: pattern.replacingOccurrences(of: "M", with: #"\d"#).replacingOccurrences(of: "d", with: #"\d"#).replacingOccurrences(of: "y", with: #"\d"#), options: []) {
                    let range = NSRange(location: 0, length: cleanLine.utf16.count)
                    if let match = regex.firstMatch(in: cleanLine, options: [], range: range) {
                        let dateRange = Range(match.range, in: cleanLine)
                        if let dateRange = dateRange {
                            let dateString = String(cleanLine[dateRange])
                            if let date = dateFormatter.date(from: dateString) {
                                return date
                            }
                        }
                    }
                }
                
                // Also try parsing the entire line
                if let date = dateFormatter.date(from: cleanLine) {
                    return date
                }
            }
        }
        
        return nil
    }
    
    // MARK: - Photo Library Management
    
    func saveImageToPhotos(_ image: UIImage, completion: @escaping (String?) -> Void) {
        PHPhotoLibrary.requestAuthorization { status in
            guard status == .authorized else {
                DispatchQueue.main.async {
                    completion(nil)
                }
                return
            }
            
            var localIdentifier: String?
            
            PHPhotoLibrary.shared().performChanges({
                let request = PHAssetChangeRequest.creationRequestForAsset(from: image)
                localIdentifier = request.placeholderForCreatedAsset?.localIdentifier
            }) { success, error in
                DispatchQueue.main.async {
                    completion(success ? localIdentifier : nil)
                }
            }
        }
    }
    
    func deletePhotoFromLibrary(identifier: String) {
        let fetchResult = PHAsset.fetchAssets(withLocalIdentifiers: [identifier], options: nil)
        
        PHPhotoLibrary.shared().performChanges({
            PHAssetChangeRequest.deleteAssets(fetchResult)
        }, completionHandler: nil)
    }
    
    func loadImageFromPhotos(identifier: String, completion: @escaping (UIImage?) -> Void) {
        let fetchResult = PHAsset.fetchAssets(withLocalIdentifiers: [identifier], options: nil)
        
        guard let asset = fetchResult.firstObject else {
            completion(nil)
            return
        }
        
        let options = PHImageRequestOptions()
        options.deliveryMode = .highQualityFormat
        options.isSynchronous = false
        
        PHImageManager.default().requestImage(for: asset, targetSize: PHImageManagerMaximumSize, contentMode: .aspectFit, options: options) { image, _ in
            DispatchQueue.main.async {
                completion(image)
            }
        }
    }
    
    // MARK: - Persistence
    
    private func saveReceipts() {
        if let encoded = try? JSONEncoder().encode(receipts) {
            userDefaults.set(encoded, forKey: receiptsKey)
        }
    }
    
    private func loadReceipts() {
        if let data = userDefaults.data(forKey: receiptsKey),
           let decoded = try? JSONDecoder().decode([Receipt].self, from: data) {
            receipts = decoded
        }
    }
}

// MARK: - Data Models

struct Receipt: Identifiable, Codable {
    let id: UUID
    var name: String
    var transactionId: UUID?
    var photoIdentifier: String? // Reference to photo in Photos app
    var date: Date
    var payee: String
    var amount: Double?
    var notes: String?
    var ocrText: String? // Full OCR extracted text
    
    init(name: String, transactionId: UUID? = nil, photoIdentifier: String? = nil, date: Date = Date(), payee: String = "", amount: Double? = nil, notes: String? = nil, ocrText: String? = nil) {
        self.id = UUID()
        self.name = name
        self.transactionId = transactionId
        self.photoIdentifier = photoIdentifier
        self.date = date
        self.payee = payee
        self.amount = amount
        self.notes = notes
        self.ocrText = ocrText
    }
}

struct ReceiptData {
    let payee: String
    let amount: Double?
    let date: Date
    let allText: String
}
