//
//  AddBeginningBalanceView.swift
//  DailyDollar
//
//  Created by David Wojcik III on 1/7/26.
//

import SwiftUI

struct AddBeginningBalanceView: View {
    let manager = BudgetManager.shared
    
    @State private var amountString = ""
    
    @Environment(\.dismiss) private var dismiss

    private func hideKeyboard() {
        #if canImport(UIKit)
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
        #endif
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Set your starting balance") {
                    HStack {
                        Text("$")
                         TextField("", text: $amountString, prompt: Text("0.00"))
                             .keyboardType(.decimalPad)
                    }
                }
            }
            .navigationTitle("Welcome")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        manager.beginningBalance = Double(amountString) ?? 0
                        manager.saveData()
                        dismiss()
                    }
                    .disabled((Double(amountString) ?? 0) < 0)
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
