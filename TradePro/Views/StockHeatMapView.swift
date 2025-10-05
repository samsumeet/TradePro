//
//  StockHeatMapView.swift
//  TradePro
//
//  Created by Sumeet Bachchas on 03.10.25.
//

import SwiftUI
import CoreData

enum HeatMapTimeFrame: String, CaseIterable {
    case weekly = "Weekly"
    case monthly = "Monthly"
    case yearly = "Yearly"
}

struct HeatMapData {
    let date: Date
    let totalProfit: Float
    let tradeCount: Int
}

struct StockHeatMapView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \StockJournal.date, ascending: false)],
        animation: .default)
    private var journalEntries: FetchedResults<StockJournal>
    
    @State private var selectedTimeFrame: HeatMapTimeFrame = .monthly
    @State private var selectedDate = Date()
    @State private var heatMapData: [HeatMapData] = []
    
    private let calendar = Calendar.current
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                // Header
                Text("Trading Performance Heatmap")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .padding(.top)
                
                // Time Frame Picker
                Picker("Time Frame", selection: $selectedTimeFrame) {
                    ForEach(HeatMapTimeFrame.allCases, id: \.self) { timeFrame in
                        Text(timeFrame.rawValue).tag(timeFrame)
                    }
                }
                .pickerStyle(SegmentedPickerStyle())
                .padding(.horizontal)
                
                // Navigation Controls
                HStack {
                    Button(action: {
                        navigateTime(backward: true)
                    }) {
                        Image(systemName: "chevron.left")
                            .font(.title2)
                            .foregroundColor(.blue)
                    }
                    
                    Spacer()
                    
                    Text(formatNavigationTitle())
                        .font(.headline)
                        .fontWeight(.semibold)
                    
                    Spacer()
                    
                    Button(action: {
                        navigateTime(backward: false)
                    }) {
                        Image(systemName: "chevron.right")
                            .font(.title2)
                            .foregroundColor(.blue)
                    }
                }
                .padding(.horizontal)
                
                // Heatmap
                ScrollView {
                    LazyVStack(spacing: 10) {
                        switch selectedTimeFrame {
                        case .weekly:
                            WeeklyHeatMapView(data: heatMapData, selectedDate: selectedDate)
                        case .monthly:
                            MonthlyHeatMapView(data: heatMapData, selectedDate: selectedDate)
                        case .yearly:
                            YearlyHeatMapView(data: heatMapData, selectedDate: selectedDate)
                        }
                    }
                    .padding()
                }
                
                // Legend
                HeatMapLegend()
                    .padding(.horizontal)
                
                Spacer()
            }
        }
        .onAppear {
            updateHeatMapData()
        }
        .onChange(of: selectedTimeFrame) { _, _ in
            updateHeatMapData()
        }
        .onChange(of: selectedDate) { _, _ in
            updateHeatMapData()
        }
    }
    
    private func navigateTime(backward: Bool) {
        let component: Calendar.Component
        let value = backward ? -1 : 1
        
        switch selectedTimeFrame {
        case .weekly:
            component = .weekOfYear
        case .monthly:
            component = .month
        case .yearly:
            component = .year
        }
        
        if let newDate = calendar.date(byAdding: component, value: value, to: selectedDate) {
            selectedDate = newDate
        }
    }
    
    private func formatNavigationTitle() -> String {
        let formatter = DateFormatter()
        
        switch selectedTimeFrame {
        case .weekly:
            let weekStart = calendar.dateInterval(of: .weekOfYear, for: selectedDate)?.start ?? selectedDate
            let weekEnd = calendar.date(byAdding: .day, value: 6, to: weekStart) ?? selectedDate
            formatter.dateFormat = "MMM d"
            return "\(formatter.string(from: weekStart)) - \(formatter.string(from: weekEnd)), \(calendar.component(.year, from: selectedDate))"
        case .monthly:
            formatter.dateFormat = "MMMM yyyy"
        case .yearly:
            formatter.dateFormat = "yyyy"
        }
        
        return formatter.string(from: selectedDate)
    }
    
    private func updateHeatMapData() {
        let filteredEntries = filterEntriesForTimeFrame()
        heatMapData = processDataForHeatMap(entries: Array(filteredEntries))
    }
    
    private func filterEntriesForTimeFrame() -> [StockJournal] {
        let startDate: Date
        let endDate: Date
        
        switch selectedTimeFrame {
        case .weekly:
            let weekInterval = calendar.dateInterval(of: .weekOfYear, for: selectedDate)
            startDate = weekInterval?.start ?? selectedDate
            endDate = weekInterval?.end ?? Date()
        case .monthly:
            let monthInterval = calendar.dateInterval(of: .month, for: selectedDate)
            startDate = monthInterval?.start ?? selectedDate
            endDate = monthInterval?.end ?? Date()
        case .yearly:
            let yearInterval = calendar.dateInterval(of: .year, for: selectedDate)
            startDate = yearInterval?.start ?? selectedDate
            endDate = yearInterval?.end ?? Date()
        }
        
        return journalEntries.filter { entry in
            guard let entryDate = entry.date else { return false }
            return entryDate >= startDate && entryDate < endDate
        }
    }
    
    private func processDataForHeatMap(entries: [StockJournal]) -> [HeatMapData] {
        let groupedEntries = Dictionary(grouping: entries) { entry in
            guard let date = entry.date else { return Date() }
            return calendar.startOfDay(for: date)
        }
        
        return groupedEntries.map { (date, entries) in
            let totalProfit = entries.reduce(0) { $0 + $1.profit }
            return HeatMapData(date: date, totalProfit: totalProfit, tradeCount: entries.count)
        }.sorted { $0.date < $1.date }
    }
}

// MARK: - Weekly Heatmap View
struct WeeklyHeatMapView: View {
    let data: [HeatMapData]
    let selectedDate: Date
    private let calendar = Calendar.current
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Weekly Performance")
                .font(.headline)
                .padding(.bottom, 5)
            
            let weekInterval = calendar.dateInterval(of: .weekOfYear, for: selectedDate)
            let startOfWeek = weekInterval?.start ?? selectedDate
            
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 7), spacing: 8) {
                ForEach(0..<7, id: \.self) { dayOffset in
                    let currentDay = calendar.date(byAdding: .day, value: dayOffset, to: startOfWeek) ?? Date()
                    let dayData = data.first { calendar.isDate($0.date, inSameDayAs: currentDay) }
                    
                    VStack(spacing: 4) {
                        Text(dayAbbreviation(for: currentDay))
                            .font(.caption2)
                            .foregroundColor(.secondary)
                        
                        RoundedRectangle(cornerRadius: 6)
                            .fill(colorForProfit(dayData?.totalProfit ?? 0))
                            .frame(height: 50)
                            .overlay(
                                VStack(spacing: 2) {
                                    Text("\(calendar.component(.day, from: currentDay))")
                                        .font(.caption)
                                        .fontWeight(.semibold)
                                        .foregroundColor(.white)
                                    
                                    if let profit = dayData?.totalProfit, profit != 0 {
                                        Text(formatCurrency(profit))
                                            .font(.caption2)
                                            .foregroundColor(.white)
                                    }
                                }
                            )
                    }
                }
            }
            
            let weekTotal = data.reduce(0) { $0 + $1.totalProfit }
            let weekTrades = data.reduce(0) { $0 + $1.tradeCount }
            
            HStack {
                Text("Week Total: \(formatCurrency(weekTotal))")
                Spacer()
                Text("Total Trades: \(weekTrades)")
            }
            .font(.caption)
            .foregroundColor(.secondary)
        }
    }
    
    private func dayAbbreviation(for date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEE"
        return formatter.string(from: date)
    }
}

// MARK: - Monthly Heatmap View
struct MonthlyHeatMapView: View {
    let data: [HeatMapData]
    let selectedDate: Date
    private let calendar = Calendar.current
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Monthly Performance")
                .font(.headline)
                .padding(.bottom, 5)
            
            let monthInterval = calendar.dateInterval(of: .month, for: selectedDate)
            let startOfMonth = monthInterval?.start ?? selectedDate
            let daysInMonth = calendar.range(of: .day, in: .month, for: selectedDate)?.count ?? 30
            
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 7), spacing: 6) {
                // Add empty cells for days before the first day of the month
               
                
                ForEach(1...daysInMonth, id: \.self) { day in
                    let currentDay = calendar.date(byAdding: .day, value: day - 1, to: startOfMonth) ?? Date()
                    let dayData = data.first { calendar.isDate($0.date, inSameDayAs: currentDay) }
                    
                    RoundedRectangle(cornerRadius: 6)
                        .fill(colorForProfit(dayData?.totalProfit ?? 0))
                        .frame(height: 40)
                        .overlay(
                            VStack(spacing: 1) {
                                Text("\(day)")
                                    .font(.caption)
                                    .fontWeight(.medium)
                                    .foregroundColor(.white)
                                
                                if let profit = dayData?.totalProfit, profit != 0 {
                                    Text(formatCurrency(profit))
                                        .font(.system(size: 8))
                                        .foregroundColor(.white)
                                }
                            }
                        )
                }
            }
            
            let monthTotal = data.reduce(0) { $0 + $1.totalProfit }
            let monthTrades = data.reduce(0) { $0 + $1.tradeCount }
            
            HStack {
                Text("Month Total: \(formatCurrency(monthTotal))")
                Spacer()
                Text("Total Trades: \(monthTrades)")
            }
            .font(.caption)
            .foregroundColor(.secondary)
        }
    }
}

// MARK: - Yearly Heatmap View
struct YearlyHeatMapView: View {
    let data: [HeatMapData]
    let selectedDate: Date
    private let calendar = Calendar.current
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Yearly Performance")
                .font(.headline)
                .padding(.bottom, 5)
            
            let yearInterval = calendar.dateInterval(of: .year, for: selectedDate)
            let startOfYear = yearInterval?.start ?? selectedDate
            
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 4), spacing: 12) {
                ForEach(0..<12, id: \.self) { monthOffset in
                    let currentMonth = calendar.date(byAdding: .month, value: monthOffset, to: startOfYear) ?? Date()
                    let monthData = getMonthData(for: currentMonth)
                    
                    VStack(spacing: 6) {
                        Text(monthAbbreviation(for: currentMonth))
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundColor(.secondary)
                        
                        RoundedRectangle(cornerRadius: 8)
                            .fill(colorForProfit(monthData.totalProfit))
                            .frame(height: 60)
                            .overlay(
                                VStack(spacing: 2) {
                                    if monthData.totalProfit != 0 {
                                        Text(formatCurrency(monthData.totalProfit))
                                            .font(.caption)
                                            .fontWeight(.semibold)
                                            .foregroundColor(.white)
                                        
                                        Text("\(monthData.tradeCount) trades")
                                            .font(.system(size: 9))
                                            .foregroundColor(.white.opacity(0.9))
                                    } else {
                                        Text("No trades")
                                            .font(.system(size: 9))
                                            .foregroundColor(.white.opacity(0.7))
                                    }
                                }
                            )
                    }
                }
            }
            
            let yearTotal = data.reduce(0) { $0 + $1.totalProfit }
            let yearTrades = data.reduce(0) { $0 + $1.tradeCount }
            
            VStack(alignment: .leading, spacing: 8) {
                Divider()
                
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Year Total")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text(formatCurrency(yearTotal))
                            .font(.title3)
                            .fontWeight(.bold)
                            .foregroundColor(yearTotal >= 0 ? .green : .red)
                    }
                    
                    Spacer()
                    
                    VStack(alignment: .trailing, spacing: 4) {
                        Text("Total Trades")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text("\(yearTrades)")
                            .font(.title3)
                            .fontWeight(.bold)
                    }
                }
            }
            .padding(.top, 8)
        }
    }
    
    private func monthAbbreviation(for date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM"
        return formatter.string(from: date)
    }
    
    private func getMonthData(for month: Date) -> (totalProfit: Float, tradeCount: Int) {
        let monthInterval = calendar.dateInterval(of: .month, for: month)
        guard let startOfMonth = monthInterval?.start,
              let endOfMonth = monthInterval?.end else {
            return (0, 0)
        }
        
        let monthEntries = data.filter { entryData in
            entryData.date >= startOfMonth && entryData.date < endOfMonth
        }
        
        let totalProfit = monthEntries.reduce(0) { $0 + $1.totalProfit }
        let tradeCount = monthEntries.reduce(0) { $0 + $1.tradeCount }
        
        return (totalProfit, tradeCount)
    }
}

// MARK: - Heatmap Legend
struct HeatMapLegend: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Legend")
                .font(.headline)
            
            HStack(spacing: 15) {
                LegendItem(color: .red, label: "Loss")
                LegendItem(color: .gray, label: "No Trades")
                LegendItem(color: .green, label: "Profit")
            }
        }
    }
}

struct LegendItem: View {
    let color: Color
    let label: String
    
    var body: some View {
        HStack(spacing: 6) {
            RoundedRectangle(cornerRadius: 3)
                .fill(color)
                .frame(width: 12, height: 12)
            Text(label)
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
}

// MARK: - Helper Functions
private func colorForProfit(_ profit: Float) -> Color {
    if profit > 0 {
        let intensity = min(abs(profit) / 1000, 1.0)
        return Color.green.opacity(0.3 + Double(intensity) * 0.7)
    } else if profit < 0 {
        let intensity = min(abs(profit) / 1000, 1.0)
        return Color.red.opacity(0.3 + Double(intensity) * 0.7)
    } else {
        return Color.gray.opacity(0.2)
    }
}

private func formatCurrency(_ amount: Float) -> String {
    let formatter = NumberFormatter()
    formatter.numberStyle = .currency
    formatter.currencyCode = "Euro"
    formatter.maximumFractionDigits = 0
    return formatter.string(from: NSNumber(value: amount)) ?? "$0"
}

#Preview {
    StockHeatMapView()
        .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
}
