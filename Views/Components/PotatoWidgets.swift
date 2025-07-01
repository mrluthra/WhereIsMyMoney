import SwiftUI

// MARK: - Dynamic Potato View
struct DynamicPotatoView: View {
    let context: PotatoCharacter.UsageContext
    let amount: Double?
    
    @StateObject private var characterManager = PotatoCharacterManager()
    @State private var isAnimating = false
    @State private var showFloatingEmotions = false
    
    private var selectedCharacter: PotatoCharacter {
        return characterManager.getCharacterForAmount(amount ?? 0, context: context)
    }
    
    private var dynamicMessage: String {
        return characterManager.getMessage(for: context, amount: amount)
    }
    
    var body: some View {
        VStack(spacing: 12) {
            // Main Potato Character
            ZStack {
                // Background glow effect
                Circle()
                    .fill(selectedCharacter.mood.color.opacity(0.2))
                    .frame(width: isAnimating ? 140 : 120, height: isAnimating ? 140 : 120)
                    .animation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true), value: isAnimating)
                
                // Potato Image
                Image(selectedCharacter.imageName)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 100, height: 100)
                    .scaleEffect(isAnimating ? 1.05 : 1.0)
                    .rotationEffect(.degrees(isAnimating ? 2 : -2))
                    .animation(.easeInOut(duration: 2.0).repeatForever(autoreverses: true), value: isAnimating)
                
                // Floating emotion particles for positive contexts
                if showFloatingEmotions {
                    FloatingEmotionsView(emotion: selectedCharacter.mood.emotion)
                }
            }
            
            // Dynamic message
            Text(dynamicMessage)
                .font(.subheadline)
                .fontWeight(.semibold)
                .multilineTextAlignment(.center)
                .foregroundColor(.primary)
                .padding(.horizontal)
        }
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                withAnimation(.easeInOut(duration: 0.5)) {
                    isAnimating = true
                }
            }
            
            // Show emotions for positive contexts
            if [.budgetWin, .payday, .savingsGoal, .goalAchieved, .debtFree].contains(context) {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
                    showFloatingEmotions = true
                }
            }
        }
    }
}

// MARK: - Interactive Potato Widget
struct InteractivePotatoWidget: View {
    let scenario: FinancialScenario
    
    @StateObject private var characterManager = PotatoCharacterManager()
    @State private var currentMood: PotatoCharacter.PotatoMood = .thinking
    @State private var showConfetti = false
    @State private var isAnimating = false
    @Environment(\.dismiss) private var dismiss
    
    enum FinancialScenario {
        case addedFirstTransaction
        case reachedSavingsGoal(amount: Double)
        case overspentBudget(amount: Double)
        case paidOffDebt(amount: Double)
        case bigPurchase(amount: Double)
        case monthlyReview(net: Double)
        case budgetSuccess
        case goalAchieved(name: String, amount: Double)
    }
    
    private var selectedCharacter: PotatoCharacter {
        return characterManager.getCharacter(for: currentMood) ?? characterManager.characters.first!
    }
    
    private var isPositiveScenario: Bool {
        switch scenario {
        case .addedFirstTransaction, .reachedSavingsGoal, .paidOffDebt, .budgetSuccess, .goalAchieved:
            return true
        case .overspentBudget, .bigPurchase:
            return false
        case .monthlyReview(let net):
            return net > 0
        }
    }
    
    private var moodColor: Color {
        selectedCharacter.mood.color
    }
    
    private var scenarioMessage: String {
        switch scenario {
        case .addedFirstTransaction:
            return "Welcome to Team Potato! 🥔\nYour financial journey begins!"
        case .reachedSavingsGoal(let amount):
            return "SPUD-TACULAR! 🎉\nYou saved $\(Int(amount))!"
        case .overspentBudget(let amount):
            return "Oops! Spent $\(Int(amount)) over budget 😤\nThis potato is not pleased..."
        case .paidOffDebt(let amount):
            return "DEBT-FREE POTATO! 🎉\nPaid off $\(Int(amount))!"
        case .bigPurchase(let amount):
            return "Big spender alert! 🤑\n$\(Int(amount)) purchase detected"
        case .monthlyReview(let net):
            let emoji = net > 0 ? "📈" : "📉"
            return "Monthly Detective Report \(emoji)\nNet: $\(Int(net))"
        case .budgetSuccess:
            return "Budget Boss! 💪\nYou stayed on track!"
        case .goalAchieved(let name, let amount):
            return "🎯 GOAL ACHIEVED! 🎯\n\(name): $\(Int(amount))"
        }
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 24) {
                Spacer()
                
                // Main Potato Display
                ZStack {
                    // Background effect
                    Circle()
                        .fill(moodColor.opacity(0.2))
                        .frame(width: 200, height: 200)
                        .scaleEffect(showConfetti ? 1.3 : 1.0)
                        .animation(.easeInOut(duration: 0.8), value: showConfetti)
                    
                    // Potato character
                    Image(selectedCharacter.imageName)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 140, height: 140)
                        .rotationEffect(.degrees(isAnimating ? 10 : -10))
                        .scaleEffect(isAnimating ? 1.1 : 1.0)
                        .animation(.easeInOut(duration: 0.6).repeatForever(autoreverses: true), value: isAnimating)
                    
                    // Confetti for positive scenarios
                    if showConfetti && isPositiveScenario {
                        ConfettiView()
                    }
                }
                
                // Scenario message
                Text(scenarioMessage)
                    .font(.title2)
                    .fontWeight(.bold)
                    .multilineTextAlignment(.center)
                    .foregroundColor(moodColor)
                    .padding(.horizontal)
                
                Spacer()
                
                // Action buttons
                VStack(spacing: 16) {
                    if isPositiveScenario {
                        Button(action: shareAchievement) {
                            HStack {
                                Image(systemName: "square.and.arrow.up")
                                Text("Share This Win!")
                            }
                            .font(.headline)
                            .fontWeight(.semibold)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(moodColor)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                        }
                    }
                    
                    Button("Continue") {
                        dismiss()
                    }
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(moodColor)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(moodColor.opacity(0.2))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                .padding(.horizontal)
                .padding(.bottom)
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("CashPotato")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Close") {
                        dismiss()
                    }
                }
            }
        }
        .onAppear {
            determineMood()
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                withAnimation(.easeInOut(duration: 0.5)) {
                    isAnimating = true
                }
            }
            if isPositiveScenario {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
                    showConfetti = true
                }
            }
        }
    }
    
    private func determineMood() {
        switch scenario {
        case .addedFirstTransaction:
            currentMood = .thinking
        case .reachedSavingsGoal, .paidOffDebt, .budgetSuccess, .goalAchieved:
            currentMood = .celebrating
        case .overspentBudget:
            currentMood = .grumpy
        case .bigPurchase:
            currentMood = .money_eyes
        case .monthlyReview(let net):
            currentMood = net > 0 ? .celebrating : .investigating
        }
    }
    
    private func shareAchievement() {
        let context = getContextForScenario()
        let amount = getAmountForScenario()
        let shareText = characterManager.generateShareText(for: context, amount: amount)
        
        let activityVC = UIActivityViewController(activityItems: [shareText], applicationActivities: nil)
        
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let window = windowScene.windows.first {
            window.rootViewController?.present(activityVC, animated: true)
        }
    }
    
    private func getContextForScenario() -> PotatoCharacter.UsageContext {
        switch scenario {
        case .addedFirstTransaction: return .firstTransaction
        case .reachedSavingsGoal: return .savingsGoal
        case .paidOffDebt: return .debtFree
        case .budgetSuccess: return .budgetWin
        case .goalAchieved: return .goalAchieved
        case .overspentBudget: return .budgetFail
        case .bigPurchase: return .bigExpense
        case .monthlyReview: return .monthlyReport
        }
    }
    
    private func getAmountForScenario() -> Double? {
        switch scenario {
        case .reachedSavingsGoal(let amount): return amount
        case .paidOffDebt(let amount): return amount
        case .bigPurchase(let amount): return amount
        case .overspentBudget(let amount): return amount
        case .monthlyReview(let net): return net
        case .goalAchieved(_, let amount): return amount
        default: return nil
        }
    }
}

// MARK: - Simple Floating Emotions View
struct FloatingEmotionsView: View {
    let emotion: String
    @State private var opacity1: Double = 0
    @State private var opacity2: Double = 0
    @State private var opacity3: Double = 0
    @State private var yOffset1: Double = 0
    @State private var yOffset2: Double = 0
    @State private var yOffset3: Double = 0
    
    var body: some View {
        ZStack {
            // Three floating emotions with staggered timing
            Text(emotion)
                .font(.title2)
                .opacity(opacity1)
                .offset(x: -20, y: yOffset1)
            
            Text(emotion)
                .font(.title2)
                .opacity(opacity2)
                .offset(x: 20, y: yOffset2)
            
            Text(emotion)
                .font(.title2)
                .opacity(opacity3)
                .offset(x: 0, y: yOffset3)
        }
        .onAppear {
            startAnimations()
        }
    }
    
    private func startAnimations() {
        // First emotion
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            withAnimation(.easeOut(duration: 2.0)) {
                opacity1 = 1.0
                yOffset1 = -80
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                withAnimation(.easeIn(duration: 1.0)) {
                    opacity1 = 0.0
                }
            }
        }
        
        // Second emotion
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            withAnimation(.easeOut(duration: 2.0)) {
                opacity2 = 1.0
                yOffset2 = -80
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                withAnimation(.easeIn(duration: 1.0)) {
                    opacity2 = 0.0
                }
            }
        }
        
        // Third emotion
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            withAnimation(.easeOut(duration: 2.0)) {
                opacity3 = 1.0
                yOffset3 = -80
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                withAnimation(.easeIn(duration: 1.0)) {
                    opacity3 = 0.0
                }
            }
        }
    }
}

// MARK: - Simple Confetti Animation
struct ConfettiView: View {
    @State private var confettiOffset1: CGSize = .zero
    @State private var confettiOffset2: CGSize = .zero
    @State private var confettiOffset3: CGSize = .zero
    @State private var confettiOffset4: CGSize = .zero
    @State private var confettiOpacity: Double = 0
    
    var body: some View {
        ZStack {
            // Multiple confetti pieces
            ForEach(0..<8, id: \.self) { index in
                Circle()
                    .fill(confettiColors[index % confettiColors.count])
                    .frame(width: 8, height: 8)
                    .offset(getOffset(for: index))
                    .opacity(confettiOpacity)
                    .rotationEffect(.degrees(Double(index) * 45))
            }
        }
        .onAppear {
            startConfettiAnimation()
        }
    }
    
    private let confettiColors: [Color] = [.red, .blue, .green, .yellow, .orange, .purple, .pink, .mint]
    
    private func getOffset(for index: Int) -> CGSize {
        let angle = Double(index) * 45.0 * .pi / 180.0
        let distance = 100.0
        return CGSize(
            width: cos(angle) * distance * confettiOpacity,
            height: sin(angle) * distance * confettiOpacity
        )
    }
    
    private func startConfettiAnimation() {
        withAnimation(.easeOut(duration: 1.0)) {
            confettiOpacity = 1.0
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            withAnimation(.easeIn(duration: 1.0)) {
                confettiOpacity = 0.0
            }
        }
    }
}

// MARK: - Simple Potato Mood Indicator
struct PotatoMoodIndicator: View {
    let mood: PotatoCharacter.PotatoMood
    let size: CGFloat
    
    @StateObject private var characterManager = PotatoCharacterManager()
    
    private var character: PotatoCharacter? {
        characterManager.getCharacter(for: mood)
    }
    
    var body: some View {
        Group {
            if let character = character {
                Image(character.imageName)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: size, height: size)
            } else {
                Text(mood.emotion)
                    .font(.system(size: size * 0.7))
            }
        }
    }
}

// MARK: - Compact Potato Status
struct CompactPotatoStatus: View {
    let context: PotatoCharacter.UsageContext
    let showMessage: Bool
    
    @StateObject private var characterManager = PotatoCharacterManager()
    
    private var character: PotatoCharacter {
        characterManager.getCharacter(for: context) ?? characterManager.characters.first!
    }
    
    var body: some View {
        HStack(spacing: 8) {
            Image(character.imageName)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 30, height: 30)
            
            if showMessage {
                Text(character.description)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(1)
            }
        }
    }
}
