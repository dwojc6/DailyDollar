//
//Models.swift
//  DailyDollar
//
//  Created by David Wojcik III on 1/7/26.
//

import Foundation   

struct Category: Identifiable, Codable, Equatable, Hashable {
    var id = UUID()
    var name: String
    var budget: Double = 0.0
}

struct Transaction: Identifiable, Codable, Equatable {
    var id = UUID()
    var amount: Double
    var date: Date = Date()
    var note: String = ""
    var categoryId: UUID
}

struct ExpectedExpense: Identifiable, Codable, Equatable {
    var id = UUID()
    var amount: Double
    var note: String = ""
}

struct ExpectedIncome: Identifiable, Codable, Equatable {
    var id = UUID()
    var amount: Double
    var note: String = ""
}

struct AppData: Codable {
    var beginningBalance: Double
    var paycheckAmount: Double
    var paycheckDay: Int
    var categories: [Category]
    var transactions: [Transaction]
    var expectedExpenses: [ExpectedExpense]
    var expectedIncome: [ExpectedIncome] = []
    var lastPeriodStart: Date
}
