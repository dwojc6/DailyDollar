//
//  HistoryTab.swift
//  DailyDollar
//
//  Created by David Wojcik III on 1/7/26.
//

import SwiftUI

struct HistoryTab: View {
    @EnvironmentObject var manager: BudgetManager

    private var pastPeriods: [Date] {
        var periods: [Date] = []
        let current = manager.currentPeriodStart()
        let calendar = Calendar.current
        for i in 0..<12 {
            if let period = calendar.date(byAdding: .month, value: -i, to: current) {
                let periodEnd = calendar.date(byAdding: .month, value: 1, to: period)!
                let hasTransactions = manager.transactions.contains { $0.date >= period && $0.date < periodEnd }
                if hasTransactions {
                    periods.append(period)
                }
            }
        }
        return periods
    }

    private struct AnnualSpending: Identifiable {
        let id = UUID()
        let category: Category
        let amount: Double
    }

    private var annualSpendingByCategory: [AnnualSpending] {
        let calendar = Calendar.current
        let oneYearAgo = calendar.date(byAdding: .year, value: -1, to: Date())!
        let incomeCategoryIds = manager.categories.filter { $0.name.lowercased().contains("income") }.map { $0.id }
        
        var spendingByCategory: [UUID: Double] = [:]
        
        for transaction in manager.transactions {
            if transaction.date >= oneYearAgo && !incomeCategoryIds.contains(transaction.categoryId) {
                spendingByCategory[transaction.categoryId, default: 0] += transaction.amount
            }
        }
        
        var result: [AnnualSpending] = []
        for category in manager.categories {
            if let amount = spendingByCategory[category.id], amount > 0 {
                result.append(AnnualSpending(category: category, amount: amount))
            }
        }
        
        return result.sorted { $0.amount > $1.amount }
    }

    @State private var showingDocumentPicker = false
    @State private var showingPasteCSV = false
    @State private var pastedCSV = ""

    private func importCSV(from url: URL) {
        let accessGranted = url.startAccessingSecurityScopedResource()
        guard accessGranted else {
            print("Failed to access security scoped resource")
            return
        }
        defer { url.stopAccessingSecurityScopedResource() }

        do {
            // Try UTF-8 first
            var csvContent = try String(contentsOf: url, encoding: .utf8)
            print("CSV loaded with UTF-8, length: \(csvContent.count)")
            manager.importTransactionsFromCSV(csvContent: csvContent)
        } catch {
            print("UTF-8 failed, trying other encodings: \(error)")
            // Try other encodings
            let encodings: [String.Encoding] = [.ascii, .isoLatin1, .windowsCP1252]
            for encoding in encodings {
                do {
                    let csvContent = try String(contentsOf: url, encoding: encoding)
                    print("CSV loaded with \(encoding), length: \(csvContent.count)")
                    manager.importTransactionsFromCSV(csvContent: csvContent)
                    return
                } catch {
                    continue
                }
            }
            print("All encodings failed")
        }
    }

    private func importPastedCSV() {
        if !pastedCSV.isEmpty {
            manager.importTransactionsFromCSV(csvContent: pastedCSV)
            pastedCSV = ""
            showingPasteCSV = false
        }
    }
    
    var body: some View {
        NavigationStack {
            List {
                Section("Annual Spending by Category") {
                    if annualSpendingByCategory.isEmpty {
                        Text("No transactions in the past year")
                            .foregroundStyle(.secondary)
                    }
                    ForEach(annualSpendingByCategory) { item in
                        HStack {
                            Text(item.category.name)
                            Spacer()
                            Text(item.amount, format: .currency(code: "USD"))
                        }
                    }
                }
                
                Section("Past Transactions") {
                    if pastPeriods.isEmpty {
                        Text("No periods with transactions")
                            .foregroundStyle(.secondary)
                    }
                    ForEach(pastPeriods, id: \.self) { periodStart in
                        NavigationLink(destination: PeriodDetailView(periodStart: periodStart)) {
                            Text(periodStart, formatter: BudgetManager.monthYearFormatter)
                        }
                    }
                }
            }
            .navigationTitle("History")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Menu {
                        Button("Import from File") {
                            showingDocumentPicker = true
                        }
                        Button("Paste CSV Content") {
                            showingPasteCSV = true
                        }
                    } label: {
                        Label("Import CSV", systemImage: "square.and.arrow.down")
                    }
                }
            }
            .sheet(isPresented: $showingDocumentPicker) {
                DocumentPicker(isPresented: $showingDocumentPicker) { url in
                    importCSV(from: url)
                }
            }
            .sheet(isPresented: $showingPasteCSV) {
                NavigationStack {
                    Form {
                        Section("Paste your CSV content here") {
                            TextEditor(text: $pastedCSV)
                                .frame(height: 200)
                        }
                    }
                    .navigationTitle("Import CSV")
                    .navigationBarItems(
                        leading: Button("Cancel") {
                            showingPasteCSV = false
                            pastedCSV = ""
                        },
                        trailing: Button("Import") {
                            importPastedCSV()
                        }
                    )
                }
                .presentationDetents([.medium, .large])
            }
        }
    }
}
