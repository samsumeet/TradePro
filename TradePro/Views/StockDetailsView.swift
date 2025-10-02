//
//  StockDetailsView.swift
//  TradePro
//
//  Created by Sumeet Bachchas on 02.10.25.
//

import SwiftUI
import Charts

struct StockDetailsView: View {
    let stock: WatchlistItem
    @StateObject private var controller = StockDetailsController()
    @State private var selectedTimePeriod: ChartTimePeriod = .intraday
    @State private var hoveredDataPoint: ChartDataPoint?
    @State private var hoveredLocation: CGPoint = .zero
    
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
            // Get chart data points
            let chartData = getChartData(from: response)
            
            VStack {
                HStack {
                    Text("Price Chart")
                        .font(.headline)
                    Spacer()
                    Text(selectedTimePeriod.displayName)
                        .font(.subheadline)
                        .foregroundColor(.blue)
                }
                
                if !chartData.isEmpty {
                    // Enhanced Interactive SwiftUI Chart
                    Chart(chartData, id: \.timestamp) { dataPoint in
                        // Area mark for background fill
                        AreaMark(
                            x: .value("Time", dataPoint.timestamp),
                            y: .value("Price", dataPoint.price)
                        )
                        .foregroundStyle(LinearGradient(
                            gradient: Gradient(colors: [.blue.opacity(0.3), .blue.opacity(0.05)]),
                            startPoint: .top,
                            endPoint: .bottom
                        ))
                        
                        // Main line mark
                        LineMark(
                            x: .value("Time", dataPoint.timestamp),
                            y: .value("Price", dataPoint.price)
                        )
                        .foregroundStyle(Color.blue)
                        .lineStyle(StrokeStyle(lineWidth: selectedTimePeriod == .intraday ? 2.5 : 2))
                        .interpolationMethod(.catmullRom)
                        
                        // Data points for intraday view
                        if selectedTimePeriod == .intraday {
                            PointMark(
                                x: .value("Time", dataPoint.timestamp),
                                y: .value("Price", dataPoint.price)
                            )
                            .foregroundStyle(Color.blue)
                            .symbolSize(hoveredDataPoint?.timestamp == dataPoint.timestamp ? 80 : 30)
                            .opacity(hoveredDataPoint?.timestamp == dataPoint.timestamp ? 1.0 : 0.7)
                        }
                        
                        // Highlight hovered point
                        if let hoveredPoint = hoveredDataPoint,
                           hoveredPoint.timestamp == dataPoint.timestamp {
                            PointMark(
                                x: .value("Time", dataPoint.timestamp),
                                y: .value("Price", dataPoint.price)
                            )
                            .foregroundStyle(Color.white)
                            .symbolSize(60)
                            
                            PointMark(
                                x: .value("Time", dataPoint.timestamp),
                                y: .value("Price", dataPoint.price)
                            )
                            .foregroundStyle(Color.blue)
                            .symbolSize(40)
                        }
                    }
                    .frame(height: selectedTimePeriod == .intraday ? 250 : 200)
                    .chartBackground { chartProxy in
                        GeometryReader { geometry in
                            Rectangle()
                                .fill(Color.clear)
                                .contentShape(Rectangle())
                                .onTapGesture { location in
                                    updateHoveredPoint(at: location, geometry: geometry, chartProxy: chartProxy, data: chartData)
                                }
                                .gesture(
                                    DragGesture(minimumDistance: 0)
                                        .onChanged { value in
                                            updateHoveredPoint(at: value.location, geometry: geometry, chartProxy: chartProxy, data: chartData)
                                        }
                                        .onEnded { _ in
                                            hoveredDataPoint = nil
                                        }
                                )
                        }
                    }
                    .chartXAxis {
                        AxisMarks(values: .automatic(desiredCount: selectedTimePeriod == .intraday ? 6 : 4)) { value in
                            AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5))
                                .foregroundStyle(.gray.opacity(0.3))
                            AxisTick(stroke: StrokeStyle(lineWidth: 0.5))
                                .foregroundStyle(.gray.opacity(0.5))
                            AxisValueLabel {
                                if let date = value.as(Date.self) {
                                    Text(formatDateForAxis(date, period: selectedTimePeriod))
                                        .font(.caption2)
                                        .foregroundColor(.secondary)
                                }
                            }
                        }
                    }
                    .chartYAxis {
                        AxisMarks(position: .trailing, values: .automatic(desiredCount: 6)) { value in
                            AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5))
                                .foregroundStyle(.gray.opacity(0.3))
                            AxisTick(stroke: StrokeStyle(lineWidth: 0.5))
                                .foregroundStyle(.gray.opacity(0.5))
                            AxisValueLabel {
                                if let price = value.as(Double.self) {
                                    Text(formatPrice(price))
                                        .font(.caption2)
                                        .foregroundColor(.secondary)
                                }
                            }
                        }
                    }
                    .overlay(alignment: .topLeading) {
                        // Hover info overlay
                        if let hoveredPoint = hoveredDataPoint {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Price: \(formatPrice(hoveredPoint.price))")
                                    .font(.caption)
                                    .fontWeight(.semibold)
                                    .foregroundColor(.primary)
                                Text("Time: \(formatTime(hoveredPoint.timestamp))")
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
                            }
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .background(
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(.regularMaterial)
                                    .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
                            )
                            .padding(.leading, 16)
                            .padding(.top, 16)
                        }
                    }
                } else {
                    // Fallback when no data
                    Rectangle()
                        .fill(Color(.systemGray6))
                        .frame(height: 200)
                        .cornerRadius(8)
                        .overlay(
                            VStack {
                                Image(systemName: "chart.line.uptrend.xyaxis")
                                    .font(.system(size: 30))
                                    .foregroundColor(.secondary)
                                Text("No chart data available")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                            }
                        )
                }
                
                // Enhanced chart statistics
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
                    
                    if !chartData.isEmpty {
                        HStack {
                            Text("Data Points:")
                            Spacer()
                            Text("\(chartData.count)")
                                .fontWeight(.medium)
                        }
                        
                        if selectedTimePeriod == .intraday {
                            HStack {
                                Text("Range:")
                                Spacer()
                                Text(getPriceRange(from: chartData))
                                    .fontWeight(.medium)
                            }
                            
                            if let currentPrice = chartData.last?.price,
                               let firstPrice = chartData.first?.price {
                                let change = currentPrice - firstPrice
                                let changePercent = (change / firstPrice) * 100
                                HStack {
                                    Text("Day Change:")
                                    Spacer()
                                    Text("\(formatPriceChange(change)) (\(String(format: "%.2f", changePercent))%)")
                                        .fontWeight(.medium)
                                        .foregroundColor(change >= 0 ? .green : .red)
                                }
                            }
                        }
                    }
                }
                .font(.subheadline)
                .foregroundColor(.secondary)
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
    
    private func getChartData(from response: ChartResponse) -> [ChartDataPoint] {
        var dataPoints: [ChartDataPoint] = []
        
        // Use intraday data for intraday period, history for others
        let chartSeries: ChartSeries?
        switch selectedTimePeriod {
        case .intraday:
            chartSeries = response.series.intraday
        case .oneMonth, .sixMonths:
            chartSeries = response.series.history
        }
        
        if let series = chartSeries {
            for dataPoint in series.data {
                if dataPoint.count >= 2 {
                    let timestamp = dataPoint[0]
                    let price = dataPoint[1]
                    dataPoints.append(ChartDataPoint(
                        timestamp: Date(timeIntervalSince1970: timestamp / 1000),
                        price: price
                    ))
                }
            }
        }
        
        return dataPoints.sorted { $0.timestamp < $1.timestamp }
    }
    
    private func updateHoveredPoint(at location: CGPoint, geometry: GeometryProxy, chartProxy: ChartProxy, data: [ChartDataPoint]) {
        let xValue = chartProxy.value(atX: location.x, as: Date.self)
        
        guard let xValue = xValue else { return }
        
        // Find closest data point
        let closestPoint = data.min { point1, point2 in
            abs(point1.timestamp.timeIntervalSince(xValue)) < abs(point2.timestamp.timeIntervalSince(xValue))
        }
        
        hoveredDataPoint = closestPoint
        hoveredLocation = location
    }
    
    private func formatDateForAxis(_ date: Date, period: ChartTimePeriod) -> String {
        let formatter = DateFormatter()
        switch period {
        case .intraday:
            formatter.dateFormat = "HH:mm"
        case .oneMonth:
            formatter.dateFormat = "MMM d"
        case .sixMonths:
            formatter.dateFormat = "MMM"
        }
        return formatter.string(from: date)
    }
    
    private func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = selectedTimePeriod == .intraday ? "HH:mm:ss" : "MMM d, HH:mm"
        return formatter.string(from: date)
    }
    
    private func formatPrice(_ price: Double) -> String {
        return String(format: "%.2f €", price)
    }
    
    private func formatPriceChange(_ change: Double) -> String {
        let sign = change >= 0 ? "+" : ""
        return String(format: "%@%.2f €", sign, change)
    }
    
    private func getPriceRange(from data: [ChartDataPoint]) -> String {
        guard !data.isEmpty else { return "N/A" }
        let prices = data.map { $0.price }
        let minPrice = prices.min() ?? 0
        let maxPrice = prices.max() ?? 0
        let range = maxPrice - minPrice
        return String(format: "%.2f €", range)
    }
}

struct ChartDataPoint {
    let timestamp: Date
    let price: Double
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
