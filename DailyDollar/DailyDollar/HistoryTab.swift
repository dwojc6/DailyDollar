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
        }
    }
}
