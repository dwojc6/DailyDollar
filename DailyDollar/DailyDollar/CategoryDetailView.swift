//
//  CategoryDetailView.swift
//  DailyDollar
//
//  Created by David Wojcik III on 1/7/26.
//

import SwiftUI
import Foundation
import Combine

struct CategoryDetailView: View {
    @EnvironmentObject var manager: BudgetManager
    let category: Category
    var isForecast: Bool = false

    @State private var showingAddTransaction = false
    @State private var budgetString = ""
    @State private var forecastBudget: Double = 0

    private func hideKeyboard() {
        #if canImport(UIKit)
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
        #endif
    }
    
    private var categoryBinding: Binding<Category> {
        Binding(
            get: { manager.categories.first(where: { $0.id == category.id }) ?? category },
            set: { newValue in
                if let index = manager.categories.firstIndex(where: { $0.id == category.id }) {
                    manager.categories[index] = newValue
                    manager.saveData()
                }
            }
        )
    }
    
    private var categoryTransactions: [Transaction] {
        manager.transactionsInCurrentPeriod()
            .filter { $0.categoryId == category.id }
            .sorted { $0.date > $1.date }
    }
    
    var body: some View {
        
        return List {
            Section("Category Settings") {
                if !isForecast {
                    TextField("Name", text: categoryBinding.name)
                }
                if isForecast {
                    TextField("", value: $forecastBudget, format: .currency(code: "USD"))
                        .keyboardType(.decimalPad)
                        .multilineTextAlignment(.leading)
                        .onChange(of: forecastBudget) { _, _ in
                            manager.forecastBudgets[category.id] = forecastBudget
                            manager.saveData()
                        }
                } else {
                    HStack(spacing: 0) {
                        Text("$")
                        TextField("", text: $budgetString, prompt: Text("0.00"))
                            .keyboardType(.decimalPad)
                            .onChange(of: budgetString) { _, newValue in
                                if let doubleValue = Double(newValue) {
                                    var newCategory = categoryBinding.wrappedValue
                                    newCategory.budget = doubleValue
                                    categoryBinding.wrappedValue = newCategory
                                }
                            }
                    }
                }
            }
            
            if !isForecast {
                Section("Transactions (\(categoryTransactions.count))") {
                    ForEach(categoryTransactions) { transaction in
                        NavigationLink(destination: EditTransactionView(transaction: transaction)) {
                            VStack(alignment: .leading) {
                                HStack {
                                    Text(transaction.date, formatter: BudgetManager.shortDateFormatter)
                                    Spacer()
                                    Text(transaction.amount, format: .currency(code: "USD"))
                                }
                                if !transaction.note.isEmpty {
                                    Text(transaction.note)
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                            }
                        }
                    }
                    .onDelete { indices in
                        let toDelete = indices.map { categoryTransactions[$0] }
                        manager.transactions.removeAll { toDelete.contains($0) }
                        manager.saveData()
                    }
                    
                    Button("Add Transaction") {
                        showingAddTransaction = true
                    }
                }
            }
            
            Section("Summary") {
                let spentOrEarned = category.name.lowercased().contains("income") ? "Earned this period" : "Spent this period"
                let spent = manager.spentForCategory(category)
                let isIncome = category.name.lowercased().contains("income")
                HStack {
                    Text(spentOrEarned)
                    Spacer()
                    Text(spent, format: .currency(code: "USD"))
                        .foregroundStyle(spent > category.budget ? (isIncome ? .green : .red) : .primary)
                }
                if category.budget > 0 {
                    ProgressView(value: min(spent, category.budget), total: max(category.budget, 0.01))
                }
            }
        }
        .navigationTitle(category.name)
        .toolbar {
            ToolbarItemGroup(placement: .keyboard) {
                Spacer()
                Button("Done") {
                    hideKeyboard()
                }
                .foregroundStyle(.blue)
            }
        }
        .sheet(isPresented: $showingAddTransaction) {
            AddTransactionView(categoryId: category.id)
        }
        .onAppear {
            if isForecast {
                forecastBudget = manager.forecastBudgets[category.id] ?? category.budget
            } else {
                budgetString = String(format: "%.2f", category.budget)
            }
        }
    }
}
