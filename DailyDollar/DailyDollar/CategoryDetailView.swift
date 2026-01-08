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
    
    @State private var showingAddTransaction = false
    @State private var budgetString = ""
    
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
        let budgetBinding = Binding<String>(
            get: { 
                let val = categoryBinding.wrappedValue.budget
                return val.truncatingRemainder(dividingBy: 1) == 0 ? String(Int(val)) : String(val)
            },
            set: { 
                if let val = Double($0) {
                    var newCategory = categoryBinding.wrappedValue
                    newCategory.budget = val
                    categoryBinding.wrappedValue = newCategory
                }
            }
        )
        
        return List {
            Section("Category Settings") {
                TextField("Name", text: categoryBinding.name)
                TextField("", value: Binding(
                    get: { Double(budgetBinding.wrappedValue) ?? 0 },
                    set: { budgetBinding.wrappedValue = String($0) }
                ), format: .currency(code: "USD"))
                    .keyboardType(.decimalPad)
            }
            
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
        .sheet(isPresented: $showingAddTransaction) {
            AddTransactionView(categoryId: category.id)
        }
    }
}
