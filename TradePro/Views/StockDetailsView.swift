//
//  StockDetailsView.swift
//  TradePro
//
//  Created by Sumeet Bachchas on 02.10.25.
//

import SwiftUI

struct StockDetailsView: View {
    let stock: WatchlistItem
    @StateObject private var controller = StockDetailsController()
    @State private var selectedTimePeriod: ChartTimePeriod = .intraday
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Stock Header Info
                stockHeaderView
                
                // Chart Time Period Selector
                timePeriodSelector
                
                // Stock Chart
                stockChartView
                
                // Stock Details
                stockDetailsView
                
                Spacer()
            }
            .padding()
        }
        .navigationTitle(stock.name)
        .navigationBarTitleDisplayMode(.large)
        .onAppear {
            loadChartData()
        }
    }
    
    private var stockHeaderView: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(stock.name)
                        .font(.title2)
                        .fontWeight(.bold)
                    Text("WKN: \(stock.wkn)")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    HStack(spacing: 8) {
                        Text(stock.diff)
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundColor(diffColor)
                        Text("(\(stock.diffPercent))")
                            .font(.subheadline)
                            .foregroundColor(diffColor)
                    }
                    Text(stock.time)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            HStack(spacing: 40) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Bid")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text(stock.bid)
                        .font(.title3)
                        .fontWeight(.semibold)
                }
                
                VStack(alignment: .leading, spacing: 2) {
                    Text("Ask")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text(stock.ask)
                        .font(.title3)
                        .fontWeight(.semibold)
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
    }
    
    private var timePeriodSelector: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Chart Period")
                .font(.headline)
            
            HStack(spacing: 12) {
                ForEach(ChartTimePeriod.allCases, id: \.self) { period in
                    Button(action: {
                        selectedTimePeriod = period
                        loadChartData()
                    }) {
                        Text(period.displayName)
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(selectedTimePeriod == period ? Color.blue : Color(.systemGray6))
                            .foregroundColor(selectedTimePeriod == period ? .white : .primary)
                            .cornerRadius(20)
                    }
                }
                Spacer()
            }
        }
    }
    
    private var stockChartView: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Price Chart")
                .font(.headline)
            
            if controller.isLoading {
                VStack {
                    ProgressView("Loading chart data...")
                        .frame(height: 200)
                }
                .frame(maxWidth: .infinity)
                .background(Color(.systemGray6))
                .cornerRadius(12)
            } else if let chartResponse = controller.chartResponse {
                simpleChartView(for: chartResponse)
            } else if let errorMessage = controller.errorMessage {
                VStack {
                    Image(systemName: "chart.line.uptrend.xyaxis")
                        .font(.system(size: 40))
                        .foregroundColor(.secondary)
                    Text("Chart Unavailable")
                        .font(.headline)
                        .foregroundColor(.secondary)
                    Text(errorMessage)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                .frame(height: 200)
                .frame(maxWidth: .infinity)
                .background(Color(.systemGray6))
                .cornerRadius(12)
            } else {
                VStack {
                    Image(systemName: "chart.line.uptrend.xyaxis")
                        .font(.system(size: 40))
                        .foregroundColor(.secondary)
                    Text("No Chart Data")
                        .font(.headline)
                        .foregroundColor(.secondary)
                }
                .frame(height: 200)
                .frame(maxWidth: .infinity)
                .background(Color(.systemGray6))
                .cornerRadius(12)
            }
        }
    }
    
    private func simpleChartView(for response: ChartResponse) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            // Simple chart representation
            VStack {
                HStack {
                    Text("Chart Data Available")
                        .font(.headline)
                    Spacer()
                    Text(selectedTimePeriod.displayName)
                        .font(.subheadline)
                        .foregroundColor(.blue)
                }
                
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("Min Price:")
                        Spacer()
                        Text(response.info.textMinValue)
                            .fontWeight(.medium)
                    }
                    HStack {
                        Text("Max Price:")
                        Spacer()
                        Text(response.info.textMaxValue)
                            .fontWeight(.medium)
                    }
                    
                    if let intraday = response.series.intraday, !intraday.data.isEmpty {
                        HStack {
                            Text("Data Points:")
                            Spacer()
                            Text("\(intraday.data.count)")
                                .fontWeight(.medium)
                        }
                    }
                }
                .font(.subheadline)
                .foregroundColor(.secondary)
                
                // Placeholder for actual chart
                Rectangle()
                    .fill(LinearGradient(
                        gradient: Gradient(colors: [.blue.opacity(0.3), .blue.opacity(0.1)]),
                        startPoint: .top,
                        endPoint: .bottom
                    ))
                    .frame(height: 120)
                    .cornerRadius(8)
                    .overlay(
                        Text("Chart Visualization\n(Requires Charts framework)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    )
            }
            .padding()
            .background(Color(.systemBackground))
            .cornerRadius(12)
            .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
        }
    }
    
    private var stockDetailsView: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Stock Information")
                .font(.headline)
            
            VStack(spacing: 12) {
                detailRow(title: "Instrument ID", value: stock.instrumentId)
                detailRow(title: "WKN", value: stock.wkn)
                detailRow(title: "Last Update", value: stock.time)
                
                if let chartResponse = controller.chartResponse {
                    detailRow(title: "ISIN", value: chartResponse.info.isin)
                    detailRow(title: "Chart Type", value: chartResponse.info.chartType)
                    
                    if !chartResponse.info.plotlines.isEmpty {
                        Text("Key Levels")
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .padding(.top, 8)
                        
                        ForEach(chartResponse.info.plotlines, id: \.id) { plotline in
                            HStack {
                                Circle()
                                    .fill(.blue)
                                    .frame(width: 8, height: 8)
                                Text(plotline.label)
                                    .font(.caption)
                                Spacer()
                                Text(String(plotline.value))
                                    .font(.caption)
                                    .fontWeight(.medium)
                            }
                        }
                    }
                }
            }
            .padding()
            .background(Color(.systemBackground))
            .cornerRadius(12)
            .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
        }
    }
    
    private func detailRow(title: String, value: String) -> some View {
        HStack {
            Text(title)
                .font(.subheadline)
                .foregroundColor(.secondary)
            Spacer()
            Text(value)
                .font(.subheadline)
                .fontWeight(.medium)
        }
    }
    
    private var diffColor: Color {
        if stock.diff.hasPrefix("+") {
            return .green
        } else if stock.diff.hasPrefix("-") {
            return .red
        } else {
            return .secondary
        }
    }
    
    private func loadChartData() {
        controller.fetchChartData(instrumentId: stock.instrumentId) { _ in
            // Chart data loaded and will update the UI automatically through @Published
        }
    }
}

#Preview {
    NavigationView {
        StockDetailsView(stock: WatchlistItem(
            wkn: "A0X8ZS",
            name: "Apple Inc.",
            bid: "150.25",
            ask: "150.50",
            diff: "+2.15",
            diffPercent: "+1.45%",
            time: "15:30",
            instrumentId: "2989463"
        ))
    }
}
