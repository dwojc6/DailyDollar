//
//  AddExpectedExpenseView.swift
//  DailyDollar
//
//  Created by David Wojcik III on 1/7/26.
//

import SwiftUI

struct AddExpectedExpenseView: View {
    @EnvironmentObject var manager: BudgetManager
    
    @State private var amountString: String = ""
    @State private var note: String = ""
    
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
                }
            }
            .navigationTitle("New Expected Expense")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                     Button("Save") {
                         let amount = Double(amountString) ?? 0
                         let expense = ExpectedExpense(amount: amount, note: note)
                         manager.expectedExpenses.append(expense)
                         manager.saveData()
                         dismiss()
                     }
                     .disabled((Double(amountString) ?? 0) <= 0)
                }
            }
        }
    }
}
