//
//  AddExpectedIncomeView.swift
//  DailyDollar
//
//  Created by David Wojcik III on 1/7/26.
//

import SwiftUI

struct AddExpectedIncomeView: View {
    @EnvironmentObject var manager: BudgetManager

    @State private var amountString: String = ""
    @State private var note: String = ""

    @Environment(\.dismiss) private var dismiss

    private func hideKeyboard() {
        #if canImport(UIKit)
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
        #endif
    }

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
            .navigationTitle("New Expected Income")
             .toolbar {
                 ToolbarItem(placement: .cancellationAction) {
                     Button("Cancel") { dismiss() }
                 }
                 ToolbarItem(placement: .confirmationAction) {
                     Button("Save") {
                         let amount = Double(amountString) ?? 0
                         let income = ExpectedIncome(amount: amount, note: note)
                         manager.expectedIncome.append(income)
                         manager.saveData()
                         dismiss()
                     }
                     .disabled((Double(amountString) ?? 0) <= 0)
                 }
                 ToolbarItemGroup(placement: .keyboard) {
                     Spacer()
                     Button("Done") {
                         hideKeyboard()
                     }
                     .foregroundStyle(.blue)
                 }
             }
        }
    }
}