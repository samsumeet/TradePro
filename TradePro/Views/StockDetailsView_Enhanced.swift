//
//  StockDetailsView_Enhanced.swift
//  TradePro
//
//  Created by Sumeet Bachchas on 02.10.25.
//

import SwiftUI
import Charts

struct StockDetailsView_Enhanced: View {
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
                
                // Enhanced Stock Chart
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
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 6) {
                    Text(stock.name)
                        .font(.system(size: 22, weight: .bold))
                        .foregroundColor(.primary)
                    Text("WKN: \(stock.wkn)")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 6) {
                    HStack(spacing: 8) {
                        Text(stock.diff)
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(diffColor)
                        
                        Text("(\(stock.diffPercent))")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(diffColor)
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(
                        Capsule()
                            .fill(diffColor.opacity(0.15))
                    )
                    
                    Text(stock.time)
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.secondary)
                }
            }
            
            // Bid/Ask Cards
            HStack(spacing: 16) {
                PriceCard(title: "Bid", price: stock.bid, color: .green)
                PriceCard(title: "Ask", price: stock.ask, color: .red)
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.08), radius: 8, x: 0, y: 2)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(.blue.opacity(0.1), lineWidth: 1)
        )
    }
    
    private var timePeriodSelector: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Chart Period")
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(.primary)
            
            HStack(spacing: 12) {
                ForEach(ChartTimePeriod.allCases, id: \.self) { period in
                    Button(action: {
                        selectedTimePeriod = period
                        hoveredDataPoint = nil
                        loadChartData()
                    }) {
                        HStack(spacing: 6) {
                            if selectedTimePeriod == period {
                                Image(systemName: "checkmark.circle.fill")
                                    .font(.system(size: 12, weight: .bold))
                            }
                            Text(period.displayName)
                                .font(.system(size: 14, weight: .semibold))
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)
                        .background(
                            RoundedRectangle(cornerRadius: 25)
                                .fill(selectedTimePeriod == period ? .blue : Color(.systemGray6))
                        )
                        .foregroundColor(selectedTimePeriod == period ? .white : .primary)
                    }
                    .scaleEffect(selectedTimePeriod == period ? 1.05 : 1.0)
                    .animation(.easeInOut(duration: 0.2), value: selectedTimePeriod)
                }
                Spacer()
            }
        }
    }
    
    private var stockChartView: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Interactive Price Chart")
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(.primary)
            
            if controller.isLoading {
                LoadingChartView()
            } else if let chartResponse = controller.chartResponse {
                enhancedChartView(for: chartResponse)
            } else if let errorMessage = controller.errorMessage {
                ErrorChartView(message: errorMessage)
            } else {
                EmptyChartView()
            }
        }
    }
    
    private func enhancedChartView(for response: ChartResponse) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            // Get chart data points
            let chartData = getChartData(from: response)
            
            VStack(spacing: 20) {
                // Chart Header with live info
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        if let lastPoint = chartData.last {
                            Text("Latest: \(formatPrice(lastPoint.price))")
                                .font(.system(size: 20, weight: .bold))
                                .foregroundColor(.primary)
                            
                            Text("Updated: \(formatTime(lastPoint.timestamp))")
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    Spacer()
                    
                    // Period indicator
                    HStack(spacing: 6) {
                        Circle()
                            .fill(.blue)
                            .frame(width: 6, height: 6)
                        Text(selectedTimePeriod.displayName)
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(.blue)
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(
                        Capsule()
                            .fill(.blue.opacity(0.1))
                    )
                }
                
                if !chartData.isEmpty {
                    // Beautiful Interactive Chart
                    Chart(chartData, id: \.timestamp) { dataPoint in
                        // Gradient area fill
                        AreaMark(
                            x: .value("Time", dataPoint.timestamp),
                            y: .value("Price", dataPoint.price)
                        )
                        .foregroundStyle(
                            LinearGradient(
                                gradient: Gradient(colors: [
                                    .blue.opacity(0.5),
                                    .blue.opacity(0.3),
                                    .blue.opacity(0.1),
                                    .blue.opacity(0.05)
                                ]),
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        
                        // Main trend line
                        LineMark(
                            x: .value("Time", dataPoint.timestamp),
                            y: .value("Price", dataPoint.price)
                        )
                        .foregroundStyle(.blue)
                        .lineStyle(StrokeStyle(lineWidth: selectedTimePeriod == .intraday ? 3.5 : 2.5))
                        .interpolationMethod(.catmullRom)
                        
                        // Interactive data points for intraday
                        if selectedTimePeriod == .intraday {
                            PointMark(
                                x: .value("Time", dataPoint.timestamp),
                                y: .value("Price", dataPoint.price)
                            )
                            .foregroundStyle(.blue)
                            .symbolSize(hoveredDataPoint?.timestamp == dataPoint.timestamp ? 120 : 40)
                            .opacity(hoveredDataPoint?.timestamp == dataPoint.timestamp ? 1.0 : 0.7)
                            .animation(.easeInOut(duration: 0.2), value: hoveredDataPoint?.timestamp)
                        }
                        
                        // Enhanced hover highlight
                        if let hoveredPoint = hoveredDataPoint,
                           hoveredPoint.timestamp == dataPoint.timestamp {
                            // Outer glow effect
                            PointMark(
                                x: .value("Time", hoveredPoint.timestamp),
                                y: .value("Price", hoveredPoint.price)
                            )
                            .foregroundStyle(.blue.opacity(0.2))
                            .symbolSize(150)
                            
                            // White border
                            PointMark(
                                x: .value("Time", hoveredPoint.timestamp),
                                y: .value("Price", hoveredPoint.price)
                            )
                            .foregroundStyle(.white)
                            .symbolSize(90)
                            
                            // Blue center
                            PointMark(
                                x: .value("Time", hoveredPoint.timestamp),
                                y: .value("Price", hoveredPoint.price)
                            )
                            .foregroundStyle(.blue)
                            .symbolSize(60)
                            
                            // Vertical reference line
                            RuleMark(
                                x: .value("Time", hoveredPoint.timestamp)
                            )
                            .foregroundStyle(.blue.opacity(0.6))
                            .lineStyle(StrokeStyle(lineWidth: 2, dash: [8, 4]))
                            
                            // Horizontal reference line
                            RuleMark(
                                y: .value("Price", hoveredPoint.price)
                            )
                            .foregroundStyle(.blue.opacity(0.4))
                            .lineStyle(StrokeStyle(lineWidth: 1, dash: [4, 4]))
                        }
                    }
                    .frame(height: selectedTimePeriod == .intraday ? 320 : 250)
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
                                            // Keep point visible for 3 seconds
                                            DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                                                hoveredDataPoint = nil
                                            }
                                        }
                                )
                        }
                    }
                    .chartXAxis {
                        AxisMarks(values: .automatic(desiredCount: selectedTimePeriod == .intraday ? 8 : 6)) { value in
                            AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5))
                                .foregroundStyle(.gray.opacity(0.3))
                            AxisTick(stroke: StrokeStyle(lineWidth: 1))
                                .foregroundStyle(.gray.opacity(0.5))
                            AxisValueLabel {
                                if let date = value.as(Date.self) {
                                    Text(formatDateForAxis(date, period: selectedTimePeriod))
                                        .font(.system(size: 11, weight: .medium))
                                        .foregroundColor(.secondary)
                                }
                            }
                        }
                    }
                    .chartYAxis {
                        AxisMarks(position: .trailing, values: .automatic(desiredCount: 8)) { value in
                            AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5))
                                .foregroundStyle(.gray.opacity(0.3))
                            AxisTick(stroke: StrokeStyle(lineWidth: 1))
                                .foregroundStyle(.gray.opacity(0.5))
                            AxisValueLabel {
                                if let price = value.as(Double.self) {
                                    Text(formatPriceShort(price))
                                        .font(.system(size: 11, weight: .medium))
                                        .foregroundColor(.secondary)
                                }
                            }
                        }
                    }
                    .overlay(alignment: .topLeading) {
                        // Enhanced hover info overlay
                        if let hoveredPoint = hoveredDataPoint {
                            HoverInfoCard(dataPoint: hoveredPoint, chartData: chartData)
                                .padding(.leading, 20)
                                .padding(.top, 20)
                                .transition(.asymmetric(
                                    insertion: .scale.combined(with: .opacity),
                                    removal: .opacity
                                ))
                                .animation(.spring(response: 0.4, dampingFraction: 0.8), value: hoveredDataPoint?.timestamp)
                        }
                    }
                } else {
                    EmptyDataView()
                }
                
                // Enhanced statistics grid
                LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 16) {
                    StatisticCard(title: "High", value: response.info.textMaxValue, color: .green, icon: "arrow.up")
                    StatisticCard(title: "Low", value: response.info.textMinValue, color: .red, icon: "arrow.down")
                    
                    if !chartData.isEmpty {
                        StatisticCard(title: "Data Points", value: "\(chartData.count)", color: .blue, icon: "chart.dots.scatter")
                        
                        if selectedTimePeriod == .intraday {
                            StatisticCard(title: "Range", value: getPriceRange(from: chartData), color: .orange, icon: "arrow.up.arrow.down")
                            
                            if let currentPrice = chartData.last?.price,
                               let firstPrice = chartData.first?.price {
                                let change = currentPrice - firstPrice
                                let changePercent = (change / firstPrice) * 100
                                StatisticCard(
                                    title: "Day Change",
                                    value: "\(formatPriceChange(change))",
                                    subtitle: "(\(String(format: "%.2f", changePercent))%)",
                                    color: change >= 0 ? .green : .red,
                                    icon: change >= 0 ? "trending.up" : "trending.down"
                                )
                            }
                        }
                    }
                }
            }
            .padding(24)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color(.systemBackground))
                    .shadow(color: .black.opacity(0.1), radius: 15, x: 0, y: 5)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 20)
                    .stroke(.blue.opacity(0.15), lineWidth: 1.5)
            )
        }
    }
    
    // MARK: - Helper Views
    
    private var stockDetailsView: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Stock Information")
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(.primary)
            
            VStack(spacing: 12) {
                DetailRow(title: "Instrument ID", value: stock.instrumentId, icon: "number")
                DetailRow(title: "WKN", value: stock.wkn, icon: "doc.text")
                DetailRow(title: "Last Update", value: stock.time, icon: "clock")
                
                if let chartResponse = controller.chartResponse {
                    DetailRow(title: "ISIN", value: chartResponse.info.isin, icon: "barcode")
                    DetailRow(title: "Chart Type", value: chartResponse.info.chartType, icon: "chart.bar")
                    
                    if !chartResponse.info.plotlines.isEmpty {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Key Levels")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(.primary)
                                .padding(.top, 8)
                            
                            ForEach(chartResponse.info.plotlines, id: \.id) { plotline in
                                KeyLevelRow(plotline: plotline)
                            }
                        }
                    }
                }
            }
            .padding(20)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color(.systemBackground))
                    .shadow(color: .black.opacity(0.08), radius: 8, x: 0, y: 2)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(.blue.opacity(0.1), lineWidth: 1)
            )
        }
    }
    
    // MARK: - Helper Functions
    
    private var diffColor: Color {
        if stock.diff.hasPrefix("+") {
            return .green
        } else if stock.diff.hasPrefix("-") {
            return .red
        } else {
            return .orange
        }
    }
    
    private func loadChartData() {
        controller.fetchChartData(instrumentId: stock.instrumentId) { _ in }
    }
    
    private func getChartData(from response: ChartResponse) -> [ChartDataPoint] {
        var dataPoints: [ChartDataPoint] = []
        
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
        return String(format: "%.3f €", price)
    }
    
    private func formatPriceShort(_ price: Double) -> String {
        return String(format: "%.2f", price)
    }
    
    private func formatPriceChange(_ change: Double) -> String {
        let sign = change >= 0 ? "+" : ""
        return String(format: "%@%.3f €", sign, change)
    }
    
    private func getPriceRange(from data: [ChartDataPoint]) -> String {
        guard !data.isEmpty else { return "N/A" }
        let prices = data.map { $0.price }
        let minPrice = prices.min() ?? 0
        let maxPrice = prices.max() ?? 0
        let range = maxPrice - minPrice
        return String(format: "%.3f €", range)
    }
    
    private func getPreviousPrice(for dataPoint: ChartDataPoint, in data: [ChartDataPoint]) -> Double? {
        guard let index = data.firstIndex(where: { $0.timestamp == dataPoint.timestamp }),
              index > 0 else { return nil }
        return data[index - 1].price
    }
}

// MARK: - Supporting Views

struct PriceCard: View {
    let title: String
    let price: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 8) {
            HStack {
                Circle()
                    .fill(color.opacity(0.2))
                    .frame(width: 8, height: 8)
                Text(title)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.secondary)
                Spacer()
            }
            
            HStack {
                Text(price)
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(.primary)
                Spacer()
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(color.opacity(0.08))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(color.opacity(0.2), lineWidth: 1)
        )
    }
}

struct StatisticCard: View {
    let title: String
    let value: String
    let subtitle: String?
    let color: Color
    let icon: String
    
    init(title: String, value: String, subtitle: String? = nil, color: Color, icon: String) {
        self.title = title
        self.value = value
        self.subtitle = subtitle
        self.color = color
        self.icon = icon
    }
    
    var body: some View {
        VStack(spacing: 12) {
            HStack {
                Image(systemName: icon)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(color)
                    .frame(width: 20, height: 20)
                
                Text(title)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(.secondary)
                
                Spacer()
            }
            
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(value)
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(color)
                    Spacer()
                }
                
                if let subtitle = subtitle {
                    HStack {
                        Text(subtitle)
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(color.opacity(0.8))
                        Spacer()
                    }
                }
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(color.opacity(0.08))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(color.opacity(0.15), lineWidth: 1)
        )
    }
}

struct HoverInfoCard: View {
    let dataPoint: ChartDataPoint
    let chartData: [ChartDataPoint]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                Circle()
                    .fill(.blue)
                    .frame(width: 8, height: 8)
                Text("Price Details")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(.secondary)
            }
            
            VStack(alignment: .leading, spacing: 8) {
                Text(String(format: "%.3f €", dataPoint.price))
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(.primary)
                
                Text(formatDetailedTime(dataPoint.timestamp))
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(.secondary)
                
                if let previousPrice = getPreviousPrice(for: dataPoint, in: chartData) {
                    let change = dataPoint.price - previousPrice
                    let changePercent = (change / previousPrice) * 100
                    
                    HStack(spacing: 6) {
                        Image(systemName: change >= 0 ? "arrow.up.circle.fill" : "arrow.down.circle.fill")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(change >= 0 ? .green : .red)
                        
                        Text("\(formatPriceChange(change)) (\(String(format: "%.2f", changePercent))%)")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(change >= 0 ? .green : .red)
                    }
                }
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(.regularMaterial)
                .shadow(color: .black.opacity(0.2), radius: 10, x: 0, y: 5)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(.blue.opacity(0.3), lineWidth: 1.5)
        )
    }
    
    private func formatDetailedTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm:ss"
        return formatter.string(from: date)
    }
    
    private func formatPriceChange(_ change: Double) -> String {
        let sign = change >= 0 ? "+" : ""
        return String(format: "%@%.3f €", sign, change)
    }
    
    private func getPreviousPrice(for dataPoint: ChartDataPoint, in data: [ChartDataPoint]) -> Double? {
        guard let index = data.firstIndex(where: { $0.timestamp == dataPoint.timestamp }),
              index > 0 else { return nil }
        return data[index - 1].price
    }
}

struct DetailRow: View {
    let title: String
    let value: String
    let icon: String
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.blue)
                .frame(width: 20, height: 20)
            
            Text(title)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.secondary)
            
            Spacer()
            
            Text(value)
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(.primary)
        }
        .padding(.vertical, 4)
    }
}

struct KeyLevelRow: View {
    let plotline: Plotline
    
    var body: some View {
        HStack(spacing: 12) {
            Circle()
                .fill(.blue)
                .frame(width: 8, height: 8)
            
            Text(plotline.label)
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(.secondary)
            
            Spacer()
            
            Text(String(format: "%.3f", plotline.value))
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(.primary)
        }
        .padding(.vertical, 2)
    }
}

struct LoadingChartView: View {
    var body: some View {
        VStack(spacing: 20) {
            ProgressView()
                .scaleEffect(1.5)
            Text("Loading chart data...")
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(.secondary)
        }
        .frame(height: 250)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemGray6).opacity(0.3))
        )
    }
}

struct ErrorChartView: View {
    let message: String
    
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 40))
                .foregroundColor(.orange)
            
            Text("Chart Unavailable")
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(.primary)
            
            Text(message)
                .font(.system(size: 14))
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 20)
        }
        .frame(height: 250)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemGray6).opacity(0.3))
        )
    }
}

struct EmptyChartView: View {
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "chart.line.uptrend.xyaxis")
                .font(.system(size: 40))
                .foregroundColor(.blue.opacity(0.7))
            
            Text("No Chart Data")
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(.primary)
            
            Text("Chart data will appear here when available")
                .font(.system(size: 14))
                .foregroundColor(.secondary)
        }
        .frame(height: 250)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemGray6).opacity(0.3))
        )
    }
}

struct EmptyDataView: View {
    var body: some View {
        VStack(spacing: 16) {
            Circle()
                .stroke(.blue.opacity(0.3), lineWidth: 3)
                .frame(width: 80, height: 80)
                .overlay(
                    Image(systemName: "chart.dots.scatter")
                        .font(.system(size: 30))
                        .foregroundColor(.blue.opacity(0.7))
                )
            
            VStack(spacing: 8) {
                Text("No Data Points")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.primary)
                
                Text("No data available for the selected time period")
                    .font(.system(size: 14))
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
        }
        .frame(height: 250)
        .frame(maxWidth: .infinity)
    }
}

struct ChartDataPoint {
    let timestamp: Date
    let price: Double
}

#Preview {
    NavigationView {
        StockDetailsView_Enhanced(stock: WatchlistItem(
            wkn: "A0X8ZS",
            name: "BIGBEAR.AI HOLDINGS",
            bid: "6.001",
            ask: "6.079",
            diff: "+0.119",
            diffPercent: "+2.00%",
            time: "15:30",
            instrumentId: "2989463"
        ))
    }
}