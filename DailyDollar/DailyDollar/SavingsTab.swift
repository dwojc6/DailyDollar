//
//  SavingsTab.swift
//  DailyDollar
//
//  Created by David Wojcik III on 1/7/26.
//

import SwiftUI

struct SavingsTab: View {
    @EnvironmentObject var manager: BudgetManager
    
    @State private var showingAddWithdrawal = false
    
    private var savingsCategory: Category? {
        manager.categories.first { $0.name.lowercased().contains("savings") }
    }
    
    private var savingsTransactions: [Transaction] {
        guard let category = savingsCategory else { return [] }
        return manager.transactions
            .filter { $0.categoryId == category.id }
            .sorted { $0.date > $1.date }
    }
    
    private var totalSaved: Double {
        savingsTransactions.reduce(0) { $0 + $1.amount }
    }
    
    var body: some View {
        NavigationStack {
            if let _ = savingsCategory {
                List {
                    Section("Savings Transactions (\(savingsTransactions.count))") {
                        ForEach(savingsTransactions) { transaction in
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
                    
                    Section("Total Saved") {
                        HStack {
                            Text("Total Saved")
                                .font(.headline)
                            Spacer()
                            Text(totalSaved, format: .currency(code: "USD"))
                                .font(.headline)
                        }
                    }
                    
                    Section {
                        Button("Add Withdrawal") {
                            showingAddWithdrawal = true
                        }
                    }
                }
                .navigationTitle("Savings")
                .sheet(isPresented: $showingAddWithdrawal) {
                    if let category = savingsCategory {
                        AddWithdrawalView(categoryId: category.id)
                    }
                }
            } else {
                Text("No Savings category found.")
                    .navigationTitle("Savings")
            }
        }
    }
}
