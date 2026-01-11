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
    @State private var editingCategoryId: UUID?
    @FocusState private var focusedField: UUID?
    
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
                              if editingCategoryId == category.id {
                                  TextField("", value: Binding(get: { manager.forecastBudgets[category.id] ?? category.budget }, set: { manager.forecastBudgets[category.id] = $0; manager.saveData() }), format: .currency(code: "USD"))
                                      .keyboardType(.decimalPad)
                                      .frame(width: 100)
                                      .multilineTextAlignment(.trailing)
                                      .focused($focusedField, equals: category.id)
                                      .onSubmit {
                                          editingCategoryId = nil
                                          focusedField = nil
                                      }
                             } else {
                                 Text(manager.forecastBudgets[category.id] ?? category.budget, format: .currency(code: "USD"))
                             }
                         }
                         .contentShape(Rectangle())
                          .onTapGesture {
                              if editingCategoryId == category.id {
                                  editingCategoryId = nil
                                  focusedField = nil
                              } else {
                                  editingCategoryId = category.id
                                  DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
                                      focusedField = category.id
                                  }
                              }
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
                .toolbar {
                    ToolbarItemGroup(placement: .keyboard) {
                        Spacer()
                        Button("Done") {
                            editingCategoryId = nil
                            focusedField = nil
                        }
                        .foregroundStyle(.blue)
                    }
                }
        }
    }
}

struct ForecastBudgetEditView: View {
    @EnvironmentObject var manager: BudgetManager
    let category: Category
    @State private var budget: Double
    @Environment(\.dismiss) var dismiss

    init(category: Category, initialBudget: Double) {
        self.category = category
        _budget = State(initialValue: initialBudget)
    }

    var body: some View {
        VStack(spacing: 16) {
            TextField(category.name, value: $budget, format: .currency(code: "USD"))
                .keyboardType(.decimalPad)
                .textFieldStyle(.roundedBorder)
                .multilineTextAlignment(.center)
                .font(.title2)
            HStack(spacing: 20) {
                Button("Cancel") {
                    dismiss()
                }
                .foregroundStyle(.secondary)
                Button("Save") {
                    manager.forecastBudgets[category.id] = budget
                    manager.saveData()
                    dismiss()
                }
                .bold()
            }
        }
        .padding()
    }
}
