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
        GeometryReader { geometry in
            ScrollView {
                VStack(alignment: .leading, spacing: 16) { // Reduced spacing from 20 to 16
                    // Stock Header Info
                    stockHeaderView
                    
                    // Chart Time Period Selector
                    timePeriodSelector
                    
                    // Stock Chart
                    stockChartView
                        .frame(maxWidth: geometry.size.width - 32) // Ensure chart container doesn't exceed screen width
                    
                    // Stock Details
                    stockDetailsView
                    
                    Spacer(minLength: 20) // Add minimum bottom spacing
                }
                .padding(.horizontal, 16) // Reduced horizontal padding from default
                .padding(.vertical, 16) // Add explicit vertical padding
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .clipped() // Prevent any content from overflowing the screen bounds
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
        VStack(alignment: .leading, spacing: 12) {
            // Get chart data points
            let chartData = getChartData(from: response)
            
            VStack(spacing: 16) {
                // Enhanced Chart Header with current price info
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Interactive Price Chart")
                            .font(.system(size: 20, weight: .bold))
                            .foregroundColor(.primary)
                        
                        if let lastPoint = chartData.last {
                            Text("Latest: \(formatPrice(lastPoint.price))")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    Spacer()
                    
                    // Time period badge
                    HStack(spacing: 6) {
                        Circle()
                            .fill(selectedTimePeriod == .intraday ? .green : .blue)
                            .frame(width: 8, height: 8)
                        Text(selectedTimePeriod.displayName)
                            .font(.system(size: 12, weight: .bold))
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(
                        Capsule()
                            .fill((selectedTimePeriod == .intraday ? Color.green : Color.blue).opacity(0.1))
                    )
                    .foregroundColor(selectedTimePeriod == .intraday ? Color.green : Color.blue)
                }
                
                if !chartData.isEmpty {
                    VStack(spacing: 8) {
                        // Add touch instruction for intraday charts
                        if selectedTimePeriod == .intraday {
                            HStack {
                                Image(systemName: "hand.point.up.left.fill")
                                    .font(.system(size: 12))
                                    .foregroundColor(.blue)
                                Text("Touch or drag on chart to see price & time details")
                                    .font(.system(size: 12, weight: .medium))
                                    .foregroundColor(.blue)
                                Spacer()
                            }
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color.blue.opacity(0.1))
                            .cornerRadius(8)
                        }
                        
                        createChart(with: chartData)
                    }
                } else {
                    // Beautiful empty state
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
                            Text("No Chart Data Available")
                                .font(.system(size: 18, weight: .semibold))
                                .foregroundColor(.primary)
                            
                            Text("Chart data for this period is currently unavailable")
                                .font(.system(size: 14))
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                        }
                    }
                    .frame(height: 250)
                    .frame(maxWidth: .infinity)
                }
                
                // Enhanced beautiful statistics cards
                LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 12) {
                    EnhancedStatCard(
                        title: "High",
                        value: response.info.textMaxValue,
                        icon: "arrow.up.circle.fill",
                        color: .green
                    )
                    EnhancedStatCard(
                        title: "Low",
                        value: response.info.textMinValue,
                        icon: "arrow.down.circle.fill",
                        color: .red
                    )
                    
                    if !chartData.isEmpty {
                        EnhancedStatCard(
                            title: "Data Points",
                            value: "\(chartData.count)",
                            icon: "chart.dots.scatter",
                            color: .blue
                        )
                        
                        if selectedTimePeriod == .intraday {
                            EnhancedStatCard(
                                title: "Price Range",
                                value: getPriceRange(from: chartData),
                                icon: "arrow.up.arrow.down.circle.fill",
                                color: .orange
                            )
                            
                            if let currentPrice = chartData.last?.price,
                               let firstPrice = chartData.first?.price {
                                let change = currentPrice - firstPrice
                                let changePercent = (change / firstPrice) * 100
                                EnhancedStatCard(
                                    title: "Day Change",
                                    value: "\(formatPriceChange(change))",
                                    subtitle: "(\(String(format: "%.2f", changePercent))%)",
                                    icon: change >= 0 ? "trending.up" : "trending.down",
                                    color: change >= 0 ? .green : .red
                                )
                            }
                        }
                    }
                }
            }
            .padding(20)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color(.systemBackground))
                    .shadow(color: .black.opacity(0.1), radius: 15, x: 0, y: 5)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 20)
                    .stroke((selectedTimePeriod == .intraday ? Color.green : Color.blue).opacity(0.15), lineWidth: 1.5)
            )
        }
    }
    
    private func createChart(with chartData: [ChartDataPoint]) -> some View {
        // Pre-calculate colors to avoid complex expressions in Chart closure
        let baseColor = selectedTimePeriod == .intraday ? Color.green : Color.blue
        let primaryColor = selectedTimePeriod == .intraday ? Color.green : Color.blue
        
        // Calculate dynamic Y-axis domain for intraday to focus on actual price range
        let (yAxisDomain, yAxisValues) = calculateYAxisConfiguration(for: chartData)
        
        return Chart(chartData, id: \.timestamp) { dataPoint in
            createAreaMark(for: dataPoint, baseColor: baseColor)
            createLineMark(for: dataPoint, primaryColor: primaryColor)
            
            if selectedTimePeriod == .intraday {
                createPointMark(for: dataPoint)
            }
            
            if let hoveredPoint = hoveredDataPoint,
               hoveredPoint.timestamp == dataPoint.timestamp {
                createHoverEffects(for: hoveredPoint, primaryColor: primaryColor)
            }
        }
        .frame(height: selectedTimePeriod == .intraday ? 280 : 250) // Reduced intraday height from 320 to 280
        .frame(maxWidth: .infinity) // Ensure chart doesn't overflow horizontally
        .clipped() // Clip any overflowing content
        .chartYScale(domain: yAxisDomain)
        .chartBackground { chartProxy in
            createChartBackground(chartProxy: chartProxy, data: chartData)
        }
        .chartXAxis {
            AxisMarks(values: .automatic(desiredCount: selectedTimePeriod == .intraday ? 6 : 4)) { value in // Reduced tick count for intraday
                AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5))
                    .foregroundStyle(.gray.opacity(0.2))
                AxisTick(stroke: StrokeStyle(lineWidth: 1))
                    .foregroundStyle(.gray.opacity(0.4))
                AxisValueLabel {
                    if let date = value.as(Date.self) {
                        Text(formatDateForAxis(date, period: selectedTimePeriod))
                            .font(.system(size: 10, weight: .medium)) // Slightly smaller font
                            .foregroundColor(.secondary)
                    }
                }
            }
        }
        .chartYAxis {
            if selectedTimePeriod == .intraday {
                // Focused Y-axis for intraday with specific values
                AxisMarks(position: .trailing, values: yAxisValues) { value in
                    AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5))
                        .foregroundStyle(.gray.opacity(0.2))
                    AxisTick(stroke: StrokeStyle(lineWidth: 1))
                        .foregroundStyle(.gray.opacity(0.4))
                    AxisValueLabel {
                        if let price = value.as(Double.self) {
                            Text(formatPriceFocused(price))
                                .font(.system(size: 10, weight: .medium)) // Smaller font for Y-axis labels
                                .foregroundColor(.secondary)
                        }
                    }
                }
            } else {
                // Standard Y-axis for other time periods
                AxisMarks(position: .trailing, values: .automatic(desiredCount: 8)) { value in
                    AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5))
                        .foregroundStyle(.gray.opacity(0.2))
                    AxisTick(stroke: StrokeStyle(lineWidth: 1))
                        .foregroundStyle(.gray.opacity(0.4))
                    AxisValueLabel {
                        if let price = value.as(Double.self) {
                            Text(formatPriceShort(price))
                                .font(.system(size: 11, weight: .medium))
                                .foregroundColor(.secondary)
                        }
                    }
                }
            }
        }
        .overlay(alignment: .topTrailing) {
            if let hoveredPoint = hoveredDataPoint {
                HoverInfoCard(
                    dataPoint: hoveredPoint,
                    chartData: chartData,
                    period: selectedTimePeriod
                )
                .padding(.trailing, 16) // Reduced padding
                .padding(.top, 16) // Reduced padding
                .frame(maxWidth: 200) // Limit hover card width
                .transition(.asymmetric(
                    insertion: .scale.combined(with: .opacity),
                    removal: .opacity
                ))
                .animation(.spring(response: 0.4, dampingFraction: 0.8), value: hoveredDataPoint?.timestamp)
            }
        }
    }
    
    // Helper function to calculate optimal Y-axis configuration
    private func calculateYAxisConfiguration(for chartData: [ChartDataPoint]) -> (ClosedRange<Double>, [Double]) {
        guard !chartData.isEmpty else {
            return (0...100, [0, 25, 50, 75, 100])
        }
        
        let prices = chartData.map { $0.price }
        let minPrice = prices.min() ?? 0
        let maxPrice = prices.max() ?? 0
        
        if selectedTimePeriod == .intraday {
            // For intraday, focus tightly on the actual price range
            let priceRange = maxPrice - minPrice
            let padding = priceRange * 0.05 // 5% padding above and below
            
            let adjustedMin = max(0, minPrice - padding)
            let adjustedMax = maxPrice + padding
            
            // Create evenly distributed Y-axis values focused on the price range
            let numberOfTicks = 6
            var yAxisValues: [Double] = []
            
            for i in 0..<numberOfTicks {
                let value = adjustedMin + (adjustedMax - adjustedMin) * Double(i) / Double(numberOfTicks - 1)
                yAxisValues.append(value)
            }
            
            return (adjustedMin...adjustedMax, yAxisValues)
        } else {
            // For other time periods, use standard scaling with more padding
            let priceRange = maxPrice - minPrice
            let padding = priceRange * 0.1 // 10% padding
            
            let adjustedMin = max(0, minPrice - padding)
            let adjustedMax = maxPrice + padding
            
            // Use automatic values for non-intraday
            return (adjustedMin...adjustedMax, [])
        }
    }
    
    // Enhanced price formatting for focused intraday view
    private func formatPriceFocused(_ price: Double) -> String {
        // Use more decimal places for tighter price ranges
        if price >= 1000 {
            return String(format: "%.1f", price)
        } else if price >= 100 {
            return String(format: "%.2f", price)
        } else if price >= 10 {
            return String(format: "%.3f", price)
        } else {
            return String(format: "%.4f", price)
        }
    }
    
    private func createChartBackground(chartProxy: ChartProxy, data: [ChartDataPoint]) -> some View {
        GeometryReader { geometry in
            Rectangle()
                .fill(Color.clear)
                .contentShape(Rectangle())
                .onTapGesture { location in
                    updateHoveredPoint(at: location, geometry: geometry, chartProxy: chartProxy, data: data)
                }
                .gesture(
                    DragGesture(minimumDistance: 0)
                        .onChanged { value in
                            updateHoveredPoint(at: value.location, geometry: geometry, chartProxy: chartProxy, data: data)
                        }
                        .onEnded { _ in
                            // Keep point visible for 5 seconds for better UX
                            DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
                                hoveredDataPoint = nil
                            }
                        }
                )
                // Add simultaneous gesture for better touch responsiveness
                .simultaneousGesture(
                    TapGesture()
                        .onEnded { _ in
                            // Handle tap gesture
                        }
                )
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
    
    private func formatPriceShort(_ price: Double) -> String {
        return String(format: "%.3f", price)
    }
    
    private func getPreviousPrice(for dataPoint: ChartDataPoint, in data: [ChartDataPoint]) -> Double? {
        guard let index = data.firstIndex(where: { $0.timestamp == dataPoint.timestamp }),
              index > 0 else { return nil }
        return data[index - 1].price
    }
    
    @ChartContentBuilder
    private func createAreaMark(for dataPoint: ChartDataPoint, baseColor: Color) -> some ChartContent {
        let gradientColors = [
            baseColor.opacity(0.4),
            baseColor.opacity(0.2),
            baseColor.opacity(0.05)
        ]
        
        AreaMark(
            x: .value("Time", dataPoint.timestamp),
            y: .value("Price", dataPoint.price)
        )
        .foregroundStyle(
            LinearGradient(
                gradient: Gradient(colors: gradientColors),
                startPoint: .top,
                endPoint: .bottom
            )
        )
    }
    
    @ChartContentBuilder
    private func createLineMark(for dataPoint: ChartDataPoint, primaryColor: Color) -> some ChartContent {
        LineMark(
            x: .value("Time", dataPoint.timestamp),
            y: .value("Price", dataPoint.price)
        )
        .foregroundStyle(primaryColor)
        .lineStyle(StrokeStyle(lineWidth: selectedTimePeriod == .intraday ? 3.5 : 2.5))
        .interpolationMethod(.catmullRom)
    }
    
    @ChartContentBuilder
    private func createPointMark(for dataPoint: ChartDataPoint) -> some ChartContent {
        PointMark(
            x: .value("Time", dataPoint.timestamp),
            y: .value("Price", dataPoint.price)
        )
        .foregroundStyle(.green)
        .symbolSize(hoveredDataPoint?.timestamp == dataPoint.timestamp ? 120 : 45)
        .opacity(hoveredDataPoint?.timestamp == dataPoint.timestamp ? 1.0 : 0.8)
    }
    
    @ChartContentBuilder
    private func createHoverEffects(for hoveredPoint: ChartDataPoint, primaryColor: Color) -> some ChartContent {
        // Outer glow effect
        PointMark(
            x: .value("Time", hoveredPoint.timestamp),
            y: .value("Price", hoveredPoint.price)
        )
        .foregroundStyle(primaryColor.opacity(0.2))
        .symbolSize(150)
        
        // White border
        PointMark(
            x: .value("Time", hoveredPoint.timestamp),
            y: .value("Price", hoveredPoint.price)
        )
        .foregroundStyle(.white)
        .symbolSize(90)
        
        // Colored center
        PointMark(
            x: .value("Time", hoveredPoint.timestamp),
            y: .value("Price", hoveredPoint.price)
        )
        .foregroundStyle(primaryColor)
        .symbolSize(60)
        
        // Enhanced reference lines
        RuleMark(
            x: .value("Time", hoveredPoint.timestamp)
        )
        .foregroundStyle(primaryColor.opacity(0.6))
        .lineStyle(StrokeStyle(lineWidth: 2, dash: [8, 4]))
        
        RuleMark(
            y: .value("Price", hoveredPoint.price)
        )
        .foregroundStyle(primaryColor.opacity(0.4))
        .lineStyle(StrokeStyle(lineWidth: 1, dash: [4, 4]))
    }
}

// MARK: - Enhanced Supporting Views

struct HoverInfoCard: View {
    let dataPoint: ChartDataPoint
    let chartData: [ChartDataPoint]
    let period: ChartTimePeriod
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                Circle()
                    .fill(period == .intraday ? .green : .blue)
                    .frame(width: 10, height: 10)
                Text("Price Details")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(.secondary)
            }
            
            VStack(alignment: .leading, spacing: 8) {
                Text(String(format: "%.3f €", dataPoint.price))
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(.primary)
                
                Text(formatDetailedTime(dataPoint.timestamp, period: period))
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(.secondary)
                
                if let previousPrice = getPreviousPrice(for: dataPoint, in: chartData) {
                    let change = dataPoint.price - previousPrice
                    let changePercent = (change / previousPrice) * 100
                    
                    HStack(spacing: 8) {
                        Image(systemName: change >= 0 ? "arrow.up.circle.fill" : "arrow.down.circle.fill")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(change >= 0 ? .green : .red)
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text(formatPriceChange(change))
                                .font(.system(size: 13, weight: .bold))
                                .foregroundColor(change >= 0 ? .green : .red)
                            
                            Text("(\(String(format: "%.2f", changePercent))%)")
                                .font(.system(size: 11, weight: .medium))
                                .foregroundColor(change >= 0 ? .green.opacity(0.8) : .red.opacity(0.8))
                        }
                    }
                }
                
                // Show position in timeline for intraday
                if period == .intraday, let index = chartData.firstIndex(where: { $0.timestamp == dataPoint.timestamp }) {
                    HStack(spacing: 4) {
                        Image(systemName: "clock.fill")
                            .font(.system(size: 10))
                            .foregroundColor(.blue)
                        Text("Point \(index + 1) of \(chartData.count)")
                            .font(.system(size: 10, weight: .medium))
                            .foregroundColor(.blue)
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
                .stroke((period == .intraday ? Color.green : Color.blue).opacity(0.3), lineWidth: 1.5)
        )
    }
    
    private func formatDetailedTime(_ date: Date, period: ChartTimePeriod) -> String {
        let formatter = DateFormatter()
        switch period {
        case .intraday:
            formatter.dateFormat = "HH:mm:ss"
        case .oneMonth:
            formatter.dateFormat = "MMM d, HH:mm"
        case .sixMonths:
            formatter.dateFormat = "MMM d, yyyy"
        }
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

struct EnhancedStatCard: View {
    let title: String
    let value: String
    let subtitle: String?
    let icon: String
    let color: Color
    
    init(title: String, value: String, subtitle: String? = nil, icon: String, color: Color) {
        self.title = title
        self.value = value
        self.subtitle = subtitle
        self.icon = icon
        self.color = color
    }
    
    var body: some View {
        VStack(spacing: 12) {
            HStack {
                Image(systemName: icon)
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(color)
                    .frame(width: 24, height: 24)
                
                Text(title)
                    .font(.system(size: 13, weight: .semibold))
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
                .stroke(color.opacity(0.2), lineWidth: 1.5)
        )
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
