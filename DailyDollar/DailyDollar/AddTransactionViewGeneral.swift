//
//  AddTransactionViewGeneral.swift
//  DailyDollar
//
//  Created by David Wojcik III on 1/7/26.
//

import SwiftUI

struct AddTransactionViewGeneral: View {
    @EnvironmentObject var manager: BudgetManager

    @State private var selectedCategoryId: UUID = UUID()
    @State private var amountString: String = ""
    @State private var date: Date = Date()
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
                    Picker("Category", selection: $selectedCategoryId) {
                        ForEach(manager.categories) { category in
                            Text(category.name).tag(category.id)
                        }
                    }
                     HStack {
                         Text("$")
                         TextField("", text: $amountString, prompt: Text("0.00"))
                             .keyboardType(.decimalPad)
                     }
                     TextField("Note (optional)", text: $note)
                    DatePicker("Date", selection: $date, displayedComponents: [.date])
                }
            }
            .navigationTitle("Add Transaction")
             .toolbar {
                 ToolbarItem(placement: .cancellationAction) {
                     Button("Cancel") { dismiss() }
                 }
                 ToolbarItem(placement: .confirmationAction) {
                      Button("Save") {
                          let amount = Double(amountString) ?? 0
                          let transaction = Transaction(amount: amount, date: date, note: note, categoryId: selectedCategoryId)
                          manager.transactions.append(transaction)
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
             .onAppear {
                 if let firstCategoryId = manager.categories.first?.id {
                     selectedCategoryId = firstCategoryId
                 }
             }
         }
     }
 }