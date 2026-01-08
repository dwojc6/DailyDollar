//
//  AddTransactionView.swift
//  DailyDollar
//
//  Created by David Wojcik III on 1/7/26.
//

import SwiftUI

struct AddTransactionView: View {
    @EnvironmentObject var manager: BudgetManager
    let categoryId: UUID
    
    @State private var amountString = ""
    @State private var note: String = ""
    @State private var date: Date = Date()
    
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            Form {
                Section {
                     HStack {
                         Text("$")
                         TextField("", text: $amountString, prompt: Text("0.00"))
                             .keyboardType(.decimalPad)
                     }
                    TextField("Note (optional)", text: $note)
                    DatePicker("Date", selection: $date, in: manager.currentPeriodStart()...manager.currentPeriodEnd(), displayedComponents: [.date])
                }
            }
            .navigationTitle("New Transaction")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        let amount = Double(amountString) ?? 0
                        let transaction = Transaction(amount: amount, date: date, note: note, categoryId: categoryId)
                        manager.transactions.append(transaction)
                        manager.saveData()
                        dismiss()
                    }
                    .disabled((Double(amountString) ?? 0) <= 0)
                }
            }
        }
    }
}

// MARK: - Edit Transaction View

struct EditTransactionView: View {
    @EnvironmentObject var manager: BudgetManager
    let transaction: Transaction
    
    @State private var amount: Double
    @State private var note: String
    @State private var date: Date
    @State private var selectedCategoryId: UUID
    
    init(transaction: Transaction) {
        self.transaction = transaction
        _amount = State(initialValue: transaction.amount)
        _note = State(initialValue: transaction.note)
        _date = State(initialValue: transaction.date)
        _selectedCategoryId = State(initialValue: transaction.categoryId)
    }
    
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Picker("Category", selection: $selectedCategoryId) {
                        ForEach(manager.categories) { category in
                            Text(category.name).tag(category.id)
                        }
                    }
                    TextField("Amount", value: $amount, format: .currency(code: "USD"))
                        .keyboardType(.decimalPad)
                    TextField("Note (optional)", text: $note)
                    DatePicker("Date", selection: $date, displayedComponents: [.date])
                }
            }
            .navigationTitle("Edit Transaction")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        if let index = manager.transactions.firstIndex(where: { $0.id == transaction.id }) {
                            manager.transactions[index] = Transaction(id: transaction.id, amount: amount, date: date, note: note, categoryId: selectedCategoryId)
                            manager.saveData()
                        }
                        dismiss()
                    }
                    .disabled(amount <= 0)
                }
            }
        }
    }
}

// MARK: - Add Withdrawal View

struct AddWithdrawalView: View {
    @EnvironmentObject var manager: BudgetManager
    let categoryId: UUID
    
    @State private var amount: Double = 0.0
    @State private var note: String = ""
    @State private var date: Date = Date()
    
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("Amount", value: $amount, format: .currency(code: "USD"))
                        .keyboardType(.decimalPad)
                    TextField("Note (optional)", text: $note)
                    DatePicker("Date", selection: $date)
                }
            }
            .navigationTitle("Withdraw from Savings")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Withdraw") {
                        let transaction = Transaction(amount: -amount, date: date, note: note, categoryId: categoryId)
                        manager.transactions.append(transaction)
                        manager.saveData()
                        dismiss()
                    }
                    .disabled(amount <= 0)
                }
            }
        }
    }
}
