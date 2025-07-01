import SwiftUI
import Foundation

// MARK: - Potato Character Model
struct PotatoCharacter {
    let id: String
    let imageName: String
    let animatedName: String? // For GIF versions (optional)
    let mood: PotatoMood
    let description: String
    let usageContext: [UsageContext]
    
    enum PotatoMood: String, CaseIterable {
        case sleeping = "sleeping"
        case celebrating = "celebrating"
        case investigating = "investigating"
        case grumpy = "grumpy"
        case money_eyes = "money_eyes"
        case thinking = "thinking"
        case broke = "broke"
        case rich = "rich"
        case confused = "confused"
        case excited = "excited"
        
        var emotion: String {
            switch self {
            case .sleeping: return "😴"
            case .celebrating: return "🎉"
            case .investigating: return "🔍"
            case .grumpy: return "😤"
            case .money_eyes: return "🤑"
            case .thinking: return "🤔"
            case .broke: return "💸"
            case .rich: return "💰"
            case .confused: return "😵"
            case .excited: return "🚀"
            }
        }
        
        var color: Color {
            switch self {
            case .celebrating, .rich: return .green
            case .grumpy, .broke: return .red
            case .money_eyes, .excited: return .orange
            case .thinking, .investigating: return .blue
            case .sleeping, .confused: return .gray
            }
        }
    }
    
    enum UsageContext {
        case budgetFail, budgetWin, noTransactions, bigExpense,
             payday, debtFree, savingsGoal, overspending,
             firstTransaction, monthlyReport, negativeBalance,
             goalAchieved, weeklyReview, expenseAlert
    }
}

// MARK: - Potato Character Manager
class PotatoCharacterManager: ObservableObject {
    @Published var characters: [PotatoCharacter] = []
    @Published var currentCharacter: PotatoCharacter?
    
    init() {
        setupCharacters()
        currentCharacter = characters.first
    }
    
    private func setupCharacters() {
        characters = [
            PotatoCharacter(
                id: "sleepy_potato",
                imageName: "potato_sleeping",
                animatedName: "potato_sleeping_animated",
                mood: .sleeping,
                description: "When your account needs some action",
                usageContext: [.noTransactions]
            ),
            PotatoCharacter(
                id: "celebrating_potato",
                imageName: "potato_celebrating",
                animatedName: "potato_money_rain",
                mood: .celebrating,
                description: "Living the financial dream!",
                usageContext: [.budgetWin, .payday, .savingsGoal, .goalAchieved, .debtFree]
            ),
            PotatoCharacter(
                id: "detective_potato",
                imageName: "potato_investigating",
                animatedName: "potato_detective_work",
                mood: .investigating,
                description: "Analyzing your spending patterns",
                usageContext: [.monthlyReport, .weeklyReview]
            ),
            PotatoCharacter(
                id: "grumpy_potato",
                imageName: "potato_grumpy",
                animatedName: "potato_steam_angry",
                mood: .grumpy,
                description: "Not pleased with overspending",
                usageContext: [.budgetFail, .overspending, .negativeBalance]
            ),
            PotatoCharacter(
                id: "money_eyes_shocked",
                imageName: "potato_money_eyes_shocked",
                animatedName: "potato_dollar_eyes_blink",
                mood: .money_eyes,
                description: "Big expense detected!",
                usageContext: [.bigExpense, .expenseAlert]
            ),
            PotatoCharacter(
                id: "money_eyes_thinking",
                imageName: "potato_money_eyes_thinking",
                animatedName: "potato_thinking_gears",
                mood: .thinking,
                description: "Planning your financial future",
                usageContext: [.firstTransaction]
            )
        ]
    }
    
    // MARK: - Character Selection Methods
    
    func getCharacter(for context: PotatoCharacter.UsageContext) -> PotatoCharacter? {
        return characters.first { $0.usageContext.contains(context) }
    }
    
    func getCharacter(for mood: PotatoCharacter.PotatoMood) -> PotatoCharacter? {
        return characters.first { $0.mood == mood }
    }
    
    func getRandomCharacter() -> PotatoCharacter {
        return characters.randomElement() ?? characters.first!
    }
    
    func getCharacterForAmount(_ amount: Double, context: PotatoCharacter.UsageContext = .firstTransaction) -> PotatoCharacter {
        // Smart character selection based on amount and context
        switch context {
        case .bigExpense:
            return amount > 1000 ?
                getCharacter(for: .money_eyes) ?? characters.first! :
                getCharacter(for: .thinking) ?? characters.first!
        case .budgetWin:
            return getCharacter(for: .celebrating) ?? characters.first!
        case .overspending:
            return getCharacter(for: .grumpy) ?? characters.first!
        case .noTransactions:
            return getCharacter(for: .sleeping) ?? characters.first!
        default:
            return getCharacter(for: context) ?? characters.first!
        }
    }
    
    // MARK: - Dynamic Message Generation
    
    func getMessage(for context: PotatoCharacter.UsageContext, amount: Double? = nil) -> String {
        switch context {
        case .budgetWin:
            return "Spud-tacular! You're crushing your budget! 🥔✨"
        case .budgetFail:
            return "Oops! This spud is not amused... 😤"
        case .bigExpense:
            if let amount = amount, amount > 1000 {
                return "WHOA! That's a massive potato expense! 🤑💸"
            } else if let amount = amount, amount > 500 {
                return "Big spender alert! 🤑💰"
            }
            return "Eyes on the prize... or the price! 👀💰"
        case .payday:
            return "Cha-ching! This potato is feeling RICH! 🥔💰"
        case .noTransactions:
            return "Zzz... This spud needs some action! 💤"
        case .debtFree:
            return "FREEDOM! No more debt for this potato! 🎉"
        case .savingsGoal:
            return "Saving like a boss potato! 🥔💪"
        case .overspending:
            return "Houston, we have a spending problem... 🚨"
        case .firstTransaction:
            return "Welcome to the potato club! Let's get started! 🥔"
        case .monthlyReport:
            return "Detective Potato is on the case! 🔍📊"
        case .negativeBalance:
            return "This potato is seeing red... literally! 📉"
        case .goalAchieved:
            return "Goal crushed! This potato is unstoppable! 🏆"
        case .weeklyReview:
            return "Weekly check-in with Detective Potato! 📋"
        case .expenseAlert:
            return "Unusual spending detected! 🚨🥔"
        }
    }
    
    // MARK: - Share Text Generation
    
    func generateShareText(for context: PotatoCharacter.UsageContext, amount: Double? = nil) -> String {
        switch context {
        case .goalAchieved:
            if let amount = amount {
                return "Just crushed my goal of $\(Int(amount)) with CashPotato! 🥔💪 This spud is unstoppable! #CashPotato #GoalCrusher #PotatoPower"
            }
            return "Another goal in the books with CashPotato! 🥔🎯 #CashPotato #Achievement"
        case .debtFree:
            if let amount = amount {
                return "DEBT-FREE POTATO! 🥔🎉 Just paid off $\(Int(amount)) in debt thanks to CashPotato! Freedom tastes like... potatoes? #CashPotato #DebtFree #FinancialFreedom"
            }
            return "DEBT-FREE POTATO! 🥔🎉 Thanks to CashPotato! #CashPotato #DebtFree"
        case .budgetWin:
            return "Stayed under budget like a boss! 🥔💪 CashPotato keeping me on track! #CashPotato #BudgetWin #SmartSpending"
        case .firstTransaction:
            return "Just joined the CashPotato squad! 🥔💪 Ready to take control of my finances one spud at a time! #CashPotato #FinancialJourney #NewUser"
        case .savingsGoal:
            if let amount = amount {
                return "Saved $\(Int(amount)) towards my goal! 🥔💰 This potato knows how to save! #CashPotato #SavingsGoal #MoneyGoals"
            }
            return "Crushing my savings goals with CashPotato! 🥔💰 #CashPotato #Savings"
        default:
            return "Managing my money like a boss with CashPotato! 🥔📊 Every transaction counts! #CashPotato #SmartMoney #FinTech"
        }
    }
    
    // MARK: - Utility Methods
    
    func setCurrentCharacter(_ character: PotatoCharacter) {
        currentCharacter = character
    }
    
    func setCurrentCharacter(for context: PotatoCharacter.UsageContext) {
        if let character = getCharacter(for: context) {
            currentCharacter = character
        }
    }
    
    func getAllMoods() -> [PotatoCharacter.PotatoMood] {
        return PotatoCharacter.PotatoMood.allCases
    }
    
    func getCharactersForMood(_ mood: PotatoCharacter.PotatoMood) -> [PotatoCharacter] {
        return characters.filter { $0.mood == mood }
    }
}
