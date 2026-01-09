//
//  DailyDollarApp.swift
//  DailyDollar
//
//  Created by David Wojcik III on 1/7/26.
//

import SwiftUI

@main
struct BudgetTrackerApp: App {
    let manager = BudgetManager.shared
    @State private var showingFirstTime = false
    
    var body: some Scene {
        WindowGroup {
            TabView {
                BudgetTab()
                    .tabItem {
                        Label("Current", systemImage: "dollarsign.circle")
                    }
                
                ForecastTab()
                    .tabItem {
                        Label("Forecast", systemImage: "chart.line.uptrend.xyaxis")
                    }

                SavingsTab()
                    .tabItem {
                        Label("Savings", systemImage: "banknote")
                    }

                HistoryTab()
                    .tabItem {
                        Label("History", systemImage: "clock")
                    }
            }
            .environmentObject(manager)
            .onAppear {
                manager.checkPeriodChange()
                if manager.beginningBalance == 0 && manager.transactions.isEmpty {
                    showingFirstTime = true
                }
            }
            .sheet(isPresented: $showingFirstTime) {
                AddBeginningBalanceView()
            }
        }
    }
}
