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
                periods.append(period)
            }
        }
        return periods
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
                ForEach(pastPeriods, id: \.self) { periodStart in
                    NavigationLink(destination: PeriodDetailView(periodStart: periodStart)) {
                        Text(periodStart, formatter: BudgetManager.monthYearFormatter)
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
