//
//  BudgetTab.swift
//  DailyDollar
//
//  Created by David Wojcik III on 1/7/26.
//

import SwiftUI
import UIKit

struct BudgetTab: View {
    @EnvironmentObject var manager: BudgetManager

    @State private var showingAddTransaction = false

    private func hideKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }

    var body: some View {
        NavigationStack {
            List {
                  Section("Beginning Balance") {
                      Text("Amount")
                          .bold()
                      TextField("", value: $manager.beginningBalance, format: .currency(code: "USD"))
                          .keyboardType(.decimalPad)
                          .multilineTextAlignment(.leading)
                          .onChange(of: manager.beginningBalance) { _, _ in
                              manager.saveData()
                          }
                  }
                
                  Section("Paycheck") {
                      Text("Monthly Amount")
                          .bold()
                      TextField("", value: $manager.paycheckAmount, format: .currency(code: "USD"))
                          .keyboardType(.decimalPad)
                          .multilineTextAlignment(.leading)
                          .onChange(of: manager.paycheckAmount) { _, _ in
                              manager.saveData()
                          }
                    
                    Picker("Paycheck Day of Month", selection: $manager.paycheckDay) {
                        ForEach(1...31, id: \.self) { day in
                            Text(String(day)).tag(day)
                        }
                    }
                    .onChange(of: manager.paycheckDay) { _, _ in
                        manager.saveData()
                    }
                    
                     Text("Current period: \(manager.currentPeriodStart(), formatter: BudgetManager.shortDateFormatter) – \(manager.currentPeriodEnd(), formatter: BudgetManager.shortDateFormatter)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                
                Section("Categories") {
                    ForEach(manager.categories) { category in
                        NavigationLink(destination: CategoryDetailView(category: category)) {
                            VStack(alignment: .leading, spacing: 8) {
                                HStack {
                                    Text(category.name)
                                        .font(.body)
                                    Spacer()
                                    let spent = manager.spentForCategory(category)
                                    let isIncome = category.name.lowercased().contains("income")
        Text("$\(spent, format: .number.precision(.fractionLength(2))) / $\(category.budget, format: .number.precision(.fractionLength(2)))")
            .font(.callout)
            .foregroundStyle(spent > category.budget ? (isIncome ? .green : .red) : .primary)
                                }
                                ProgressView(value: min(manager.spentForCategory(category), category.budget), total: max(category.budget, 0.01))
                                    .progressViewStyle(LinearProgressViewStyle())
                            }
                        }
                    }
                    .onDelete { indices in
                        manager.categories.remove(atOffsets: indices)
                        manager.saveData()
                    }
                    .onMove { indices, newOffset in
                        manager.categories.move(fromOffsets: indices, toOffset: newOffset)
                        manager.saveData()
                    }
                    
                    Button("Add Category") {
                        let newCategory = Category(name: "New Category", budget: 100)
                        manager.categories.append(newCategory)
                        manager.saveData()
                    }
                }
                
                Section {
                    HStack {
                        Text("Remaining Balance")
                            .font(.headline)
                        Spacer()
                        Text(manager.remainingCurrent(), format: .currency(code: "USD"))
                            .font(.headline)
                            .foregroundStyle(manager.remainingCurrent() >= 0 ? .green : .red)
                    }
                }
            }
            .navigationTitle("Budget Tracker")
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button(action: { showingAddTransaction = true }) {
                        Label("Add Transaction", systemImage: "plus")
                    }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    EditButton()
                }
                ToolbarItemGroup(placement: .keyboard) {
                    Spacer()
                    Button("Done") {
                        hideKeyboard()
                    }
                    .foregroundStyle(.blue)
                }
            }
             .sheet(isPresented: $showingAddTransaction) {
                 AddTransactionViewGeneral()
             }
         }
     }
 }

