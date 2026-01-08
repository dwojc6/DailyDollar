//
//  BudgetManager.swift
//  DailyDollar
//
//  Created by David Wojcik III on 1/7/26.
//

import SwiftUI
import Foundation
import Combine

class BudgetManager: ObservableObject {
    static let shared = BudgetManager()
    
    @Published var beginningBalance: Double = 0.0
    @Published var paycheckAmount: Double = 3000.0
    @Published var paycheckDay: Int = 1 // 1–31 (user should choose a valid day; app will handle overflow gracefully)
    @Published var categories: [Category] = [
        Category(name: "Rent/Mortgage", budget: 1200),
        Category(name: "Groceries", budget: 500),
        Category(name: "Utilities", budget: 200),
        Category(name: "Transportation", budget: 300),
        Category(name: "Savings", budget: 400),
        Category(name: "Income", budget: 0)
    ]
    @Published var transactions: [Transaction] = []
    @Published var expectedExpenses: [ExpectedExpense] = []
    @Published var expectedIncome: [ExpectedIncome] = []
    @Published var lastPeriodStart: Date = Date.distantPast
    
    private let saveKey = "BudgetAppData"

    static let shortDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter
    }()
    
    static let monthYearFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"
        return formatter
    }()

    private init() {
        loadData()
    }
    
    func saveData() {
        let data = AppData(
            beginningBalance: beginningBalance,
            paycheckAmount: paycheckAmount,
            paycheckDay: paycheckDay,
            categories: categories,
            transactions: transactions,
            expectedExpenses: expectedExpenses,
            expectedIncome: expectedIncome,
            lastPeriodStart: lastPeriodStart
        )
        if let encoded = try? JSONEncoder().encode(data) {
            UserDefaults.standard.set(encoded, forKey: saveKey)
        }
    }
    
    private func loadData() {
        guard let data = UserDefaults.standard.data(forKey: saveKey),
              let decoded = try? JSONDecoder().decode(AppData.self, from: data) else { return }
        beginningBalance = decoded.beginningBalance
        paycheckAmount = decoded.paycheckAmount
        paycheckDay = decoded.paycheckDay
        categories = decoded.categories
        transactions = decoded.transactions
        expectedExpenses = decoded.expectedExpenses
        expectedIncome = decoded.expectedIncome
        lastPeriodStart = decoded.lastPeriodStart
    }
    
    // MARK: Period Calculations
    
    private let calendar = Calendar.current
    
    func currentPeriodStart() -> Date {
        let today = Date()
        let components = calendar.dateComponents([.year, .month, .day], from: today)
        guard let day = components.day else { return today }
        
        var startComponents = DateComponents()
        if day >= paycheckDay {
            startComponents.year = components.year
            startComponents.month = components.month
        } else {
            let prevMonth = calendar.date(byAdding: .month, value: -1, to: today)!
            let prevComponents = calendar.dateComponents([.year, .month], from: prevMonth)
            startComponents.year = prevComponents.year
            startComponents.month = prevComponents.month
        }
        startComponents.day = paycheckDay
        return calendar.date(from: startComponents) ?? today
    }
    
    func currentPeriodEnd() -> Date {
        let nextStart = calendar.date(byAdding: .month, value: 1, to: currentPeriodStart())!
        return calendar.date(byAdding: .day, value: -1, to: nextStart)!
    }
    
    func nextPaycheckDate() -> Date {
        calendar.date(byAdding: .month, value: 1, to: currentPeriodStart())!
    }
    
    // MARK: Current Period Stats
    
    func transactionsInCurrentPeriod() -> [Transaction] {
        let start = currentPeriodStart()
        let end = currentPeriodEnd()
        return transactions.filter { $0.date >= start && $0.date <= end }
    }
    
    func totalSpentCurrent() -> Double {
        let incomeIds = categories.filter { $0.name.lowercased().contains("income") }.map { $0.id }
        return transactionsInCurrentPeriod()
            .filter { !incomeIds.contains($0.categoryId) }
            .reduce(0) { $0 + $1.amount }
    }
    
    func totalIncomeCurrent() -> Double {
        guard let incomeCategory = categories.first(where: { $0.name.lowercased().contains("income") }) else { return 0 }
        return transactionsInCurrentPeriod()
            .filter { $0.categoryId == incomeCategory.id }
            .reduce(0) { $0 + $1.amount }
    }
    
    func remainingCurrent() -> Double {
        beginningBalance + paycheckAmount + totalIncomeCurrent() - totalSpentCurrent()
    }

    func totalUnallocatedBudget() -> Double {
        categories.reduce(0) { $0 + max(0, $1.budget - spentForCategory($1)) }
    }

    func rolloverAmount() -> Double {
        remainingCurrent() - totalUnallocatedBudget()
    }
    
    func spentForCategory(_ category: Category) -> Double {
        transactionsInCurrentPeriod()
            .filter { $0.categoryId == category.id }
            .reduce(0) { $0 + $1.amount }
    }
    
    // MARK: Forecast Stats
    
    func totalBudgetedExpenses() -> Double {
        categories.filter { !$0.name.lowercased().contains("income") }.reduce(0) { $0 + $1.budget }
    }
    
    func totalBudgetedIncome() -> Double {
        categories.filter { $0.name.lowercased().contains("income") }.reduce(0) { $0 + $1.budget }
    }
    
    func totalBudgeted() -> Double {
        totalBudgetedExpenses() + totalBudgetedIncome()
    }
    
    func checkPeriodChange() {
        let currentStart = currentPeriodStart()
        if currentStart != lastPeriodStart && lastPeriodStart != Date.distantPast {
            let previousRemaining = calculatePreviousRemaining()
            beginningBalance = previousRemaining
            lastPeriodStart = currentStart
            saveData()
        } else if lastPeriodStart == Date.distantPast {
            lastPeriodStart = currentStart
            saveData()
        }
    }
    
    private func calculatePreviousRemaining() -> Double {
        let previousStart = calendar.date(byAdding: .month, value: -1, to: currentPeriodStart())!
        let previousEnd = calendar.date(byAdding: .day, value: -1, to: currentPeriodStart())!
        let incomeIds = categories.filter { $0.name.lowercased().contains("income") }.map { $0.id }
        let spentPrev = transactions.filter { $0.date >= previousStart && $0.date <= previousEnd && !incomeIds.contains($0.categoryId) }.reduce(0) { $0 + $1.amount }
        let incomePrev = transactions.filter { $0.date >= previousStart && $0.date <= previousEnd && incomeIds.contains($0.categoryId) }.reduce(0) { $0 + $1.amount }
        return beginningBalance + paycheckAmount + incomePrev - spentPrev
    }
    
    func totalExpectedAdditional() -> Double {
        expectedExpenses.reduce(0) { $0 + $1.amount }
    }

    func totalExpectedIncome() -> Double {
        expectedIncome.reduce(0) { $0 + $1.amount }
    }
    
    func forecastedEnding() -> Double {
        rolloverAmount() + paycheckAmount - totalBudgetedExpenses() - totalExpectedAdditional() + totalBudgetedIncome() + totalExpectedIncome()
    }
}
