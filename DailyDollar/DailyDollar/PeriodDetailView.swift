//
//  PeriodDetailView.swift
//  DailyDollar
//
//  Created by David Wojcik III on 1/7/26.
//

import SwiftUI

struct PeriodDetailView: View {
    @EnvironmentObject var manager: BudgetManager
    let periodStart: Date
    @State private var showingAddTransaction = false
    
    private var periodEnd: Date {
        let calendar = Calendar.current
        let nextMonth = calendar.date(byAdding: .month, value: 1, to: periodStart)!
        return calendar.date(byAdding: .day, value: -1, to: nextMonth)!
    }
    
    private var transactions: [Transaction] {
        manager.transactions.filter { inPeriod($0.date) }.sorted { $0.date > $1.date }
    }
    
    private func inPeriod(_ date: Date) -> Bool {
        date >= periodStart && date <= periodEnd
    }
    
    private func categoryName(for id: UUID) -> String {
        manager.categories.first { $0.id == id }?.name ?? "Unknown"
    }
    
    var body: some View {
        List {
            Section("Transactions (\(transactions.count))") {
                ForEach(transactions) { transaction in
                    NavigationLink(destination: EditTransactionView(transaction: transaction)) {
                        VStack(alignment: .leading) {
                            HStack {
                                Text(transaction.date, formatter: BudgetManager.shortDateFormatter)
                                Spacer()
                                Text(transaction.amount, format: .currency(code: "USD"))
                            }
                            HStack {
                                Text("Category: \(categoryName(for: transaction.categoryId))")
                                Spacer()
                                if !transaction.note.isEmpty {
                                    Text(transaction.note)
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                            }
                        }
                    }
                }
            }
            
            Section {
                Button("Add Transaction") {
                    showingAddTransaction = true
                }
            }
        }
        .navigationTitle("\(periodStart, formatter: BudgetManager.monthYearFormatter)")
        .sheet(isPresented: $showingAddTransaction) {
            AddTransactionViewForPeriod(periodStart: periodStart)
        }
    }
}
