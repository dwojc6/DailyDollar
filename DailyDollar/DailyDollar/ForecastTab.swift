//
//  ForecastTab.swift
//  DailyDollar
//
//  Created by David Wojcik III on 1/7/26.
//

import SwiftUI

struct ForecastTab: View {
    @EnvironmentObject var manager: BudgetManager
    
    @State private var showingAddExpected = false
    @State private var showingAddExpectedIncome = false
    
    var body: some View {
        NavigationStack {
            List {
                 Section("Rollover from Current Period") {
                     Text(manager.rolloverAmount(), format: .currency(code: "USD"))
                 }
                
                Section("Next Paycheck") {
                    Text(manager.paycheckAmount, format: .currency(code: "USD"))
                        .font(.headline)
                     Text("Expected on \(manager.nextPaycheckDate(), formatter: BudgetManager.shortDateFormatter)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                
                Section("Planned Category Spending") {
                    ForEach(manager.categories) { category in
                        HStack {
                            Text(category.name)
                            Spacer()
                            Text(category.budget, format: .currency(code: "USD"))
                        }
                    }
                }
                
                Section {
                    HStack {
                        Text("Total Planned")
                            .font(.headline)
                        Spacer()
                        Text(manager.totalBudgeted(), format: .currency(code: "USD"))
                            .font(.headline)
                    }
                }
                
                Section("Other Expected Expenses") {
                    if manager.expectedExpenses.isEmpty {
                        Text("None added")
                            .foregroundStyle(.secondary)
                    }
                    ForEach(manager.expectedExpenses) { expense in
                        HStack {
                            Text(expense.note.isEmpty ? "Expense" : expense.note)
                            Spacer()
                            Text(expense.amount, format: .currency(code: "USD"))
                        }
                    }
                    .onDelete { indices in
                        manager.expectedExpenses.remove(atOffsets: indices)
                        manager.saveData()
                    }
                    
                     Button("Add Expected Expense") {
                         showingAddExpected = true
                     }
                 }

                 Section("Other Expected Income") {
                     if manager.expectedIncome.isEmpty {
                         Text("None added")
                             .foregroundStyle(.secondary)
                     }
                     ForEach(manager.expectedIncome) { income in
                         HStack {
                             Text(income.note.isEmpty ? "Income" : income.note)
                             Spacer()
                             Text(income.amount, format: .currency(code: "USD"))
                         }
                     }
                     .onDelete { indices in
                         manager.expectedIncome.remove(atOffsets: indices)
                         manager.saveData()
                     }

                     Button("Add Expected Income") {
                         showingAddExpectedIncome = true
                     }
                 }
                
                Section {
                    HStack {
                        Text("Forecasted Ending Balance")
                            .font(.title3)
                            .bold()
                        Spacer()
                        Text(manager.forecastedEnding(), format: .currency(code: "USD"))
                            .font(.title3)
                            .bold()
                            .foregroundStyle(manager.forecastedEnding() >= 0 ? .green : .red)
                    }
                }
            }
            .navigationTitle("Next Month Forecast")
            .sheet(isPresented: $showingAddExpected) {
                 AddExpectedExpenseView()
             }
             .sheet(isPresented: $showingAddExpectedIncome) {
                 AddExpectedIncomeView()
             }
        }
    }
}
