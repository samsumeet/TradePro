//
//  ContentView.swift
//  TradePro
//
//  Created by Sumeet Bachchas on 02.10.25.
//

import SwiftUI
import CoreData

struct ContentView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @State private var watchlistItems: [WatchlistItem] = []
    @State private var isLoading = false
    @State private var errorMessage = ""
    @State private var showError = false
    @State private var searchText = ""
    @State private var selectedFilter: StockFilter = .all
    
    private let scraper = WatchlistScraper()
    
    var filteredItems: [WatchlistItem] {
        var items = watchlistItems
        
        // Apply search filter
        if !searchText.isEmpty {
            items = items.filter { item in
                item.name.localizedCaseInsensitiveContains(searchText) ||
                item.wkn.localizedCaseInsensitiveContains(searchText)
            }
        }
        
        // Apply performance filter
        switch selectedFilter {
        case .all:
            break
        case .gainers:
            items = items.filter { $0.diff.hasPrefix("+") }
        case .losers:
            items = items.filter { $0.diff.hasPrefix("-") }
        }
        
        return items
    }

    var body: some View {
        NavigationView {
            ZStack {
                // Premium background
                Color(.systemGroupedBackground)
                    .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Search and Filter Bar
                    if !watchlistItems.isEmpty {
                        searchFilterBar
                            .padding(.horizontal, 16)
                            .padding(.top, 8)
                            .padding(.bottom, 12)
                            .background(Color(.systemGroupedBackground))
                    }
                    
                    ScrollView {
                        LazyVStack(spacing: 12) {
                            if isLoading {
                                loadingView
                            } else if watchlistItems.isEmpty && !errorMessage.isEmpty {
                                ErrorCardView(errorMessage: errorMessage) {
                                    fetchWatchlist()
                                }
                                .padding(.top, 40)
                            } else if watchlistItems.isEmpty {
                                EmptyStateCardView {
                                    fetchWatchlist()
                                }
                                .padding(.top, 40)
                            } else if filteredItems.isEmpty {
                                noResultsView
                                    .padding(.top, 40)
                            } else {
                                // Summary Stats Card
                                marketSummaryCard
                                    .padding(.top, 8)
                                
                                // Stock Cards
                                ForEach(filteredItems, id: \.wkn) { item in
                                    NavigationLink(destination: StockDetailsView(stock: item)) {
                                        ModernStockCard(item: item)
                                    }
                                    .buttonStyle(CardButtonStyle())
                                }
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.bottom, 20)
                    }
                    .refreshable {
                        await performRefresh()
                    }
                }
            }
            .navigationTitle("Watchlist")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: fetchWatchlist) {
                        HStack(spacing: 6) {
                            Image(systemName: "arrow.clockwise")
                                .font(.system(size: 15, weight: .semibold))
                            if !watchlistItems.isEmpty {
                                Text("\(watchlistItems.count)")
                                    .font(.system(size: 13, weight: .bold))
                                    .foregroundColor(.white)
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 2)
                                    .background(Capsule().fill(Color.blue))
                            }
                        }
                    }
                    .disabled(isLoading)
                }
            }
            .onAppear {
                if watchlistItems.isEmpty {
                    fetchWatchlist()
                }
            }
            .alert("Error", isPresented: $showError) {
                Button("OK") { }
            } message: {
                Text(errorMessage)
            }
        }
        .navigationViewStyle(.stack)
    }
    
    // MARK: - Search and Filter Bar
    private var searchFilterBar: some View {
        VStack(spacing: 12) {
            // Search Bar
            HStack(spacing: 12) {
                Image(systemName: "magnifyingglass")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.secondary)
                
                TextField("Search stocks or WKN...", text: $searchText)
                    .font(.system(size: 15))
                    .autocorrectionDisabled()
                    .textInputAutocapitalization(.never)
                
                if !searchText.isEmpty {
                    Button(action: { searchText = "" }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 16))
                            .foregroundColor(.secondary)
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(.systemBackground))
                    .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
            )
            
            // Filter Chips
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    ForEach(StockFilter.allCases, id: \.self) { filter in
                        FilterChip(
                            title: filter.title,
                            icon: filter.icon,
                            isSelected: selectedFilter == filter,
                            count: filter == .all ? watchlistItems.count :
                                   filter == .gainers ? watchlistItems.filter { $0.diff.hasPrefix("+") }.count :
                                   watchlistItems.filter { $0.diff.hasPrefix("-") }.count
                        ) {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                selectedFilter = filter
                            }
                        }
                    }
                }
            }
        }
    }
    
    // MARK: - Market Summary Card
    private var marketSummaryCard: some View {
        let gainers = watchlistItems.filter { $0.diff.hasPrefix("+") }.count
        let losers = watchlistItems.filter { $0.diff.hasPrefix("-") }.count
        let neutral = watchlistItems.count - gainers - losers
        
        return HStack(spacing: 0) {
            MarketStatItem(
                title: "Gainers",
                count: gainers,
                color: .green,
                icon: "arrow.up.circle.fill"
            )
            
            Divider()
                .frame(height: 40)
                .padding(.horizontal, 12)
            
            MarketStatItem(
                title: "Losers",
                count: losers,
                color: .red,
                icon: "arrow.down.circle.fill"
            )
            
            Divider()
                .frame(height: 40)
                .padding(.horizontal, 12)
            
            MarketStatItem(
                title: "Neutral",
                count: neutral,
                color: .orange,
                icon: "minus.circle.fill"
            )
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.06), radius: 8, x: 0, y: 3)
        )
    }
    
    // MARK: - Loading View
    private var loadingView: some View {
        VStack(spacing: 24) {
            ZStack {
                Circle()
                    .stroke(Color.blue.opacity(0.2), lineWidth: 4)
                    .frame(width: 60, height: 60)
                
                Circle()
                    .trim(from: 0, to: 0.7)
                    .stroke(
                        LinearGradient(
                            colors: [.blue, .blue.opacity(0.3)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        style: StrokeStyle(lineWidth: 4, lineCap: .round)
                    )
                    .frame(width: 60, height: 60)
                    .rotationEffect(.degrees(-90))
                    .animation(
                        .linear(duration: 1.0).repeatForever(autoreverses: false),
                        value: isLoading
                    )
            }
            
            VStack(spacing: 8) {
                Text("Loading Market Data")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.primary)
                
                Text("Please wait while we fetch the latest prices")
                    .font(.system(size: 14))
                    .foregroundColor(.secondary)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 60)
    }
    
    // MARK: - No Results View
    private var noResultsView: some View {
        VStack(spacing: 20) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 50))
                .foregroundColor(.secondary.opacity(0.5))
            
            VStack(spacing: 8) {
                Text("No Results Found")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(.primary)
                
                Text("Try adjusting your search or filter")
                    .font(.system(size: 14))
                    .foregroundColor(.secondary)
            }
            
            Button(action: {
                searchText = ""
                selectedFilter = .all
            }) {
                Text("Clear Filters")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(.blue)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 10)
                    .background(
                        RoundedRectangle(cornerRadius: 10)
                            .fill(Color.blue.opacity(0.1))
                    )
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
    }
    
    // MARK: - Helper Functions
    private func fetchWatchlist() {
        isLoading = true
        errorMessage = ""
        
        scraper.fetchWatchlist { items, error in
            DispatchQueue.main.async {
                withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                    isLoading = false
                }
                
                if let error = error {
                    errorMessage = error.localizedDescription
                    showError = true
                } else if let items = items {
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                        watchlistItems = items
                    }
                } else {
                    errorMessage = "No data received"
                    showError = true
                }
            }
        }
    }
    
    private func performRefresh() async {
        await withCheckedContinuation { continuation in
            fetchWatchlist()
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                continuation.resume()
            }
        }
    }
}

// MARK: - Modern Stock Card
struct ModernStockCard: View {
    let item: WatchlistItem
    @State private var isPressed = false
    
    var body: some View {
        HStack(spacing: 16) {
            // Stock Icon/Initial
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [diffColor.opacity(0.2), diffColor.opacity(0.1)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 56, height: 56)
                
                Text(String(item.name.prefix(1)))
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(diffColor)
            }
            
            // Stock Info
            VStack(alignment: .leading, spacing: 6) {
                Text(item.name)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.primary)
                    .lineLimit(1)
                
                HStack(spacing: 8) {
                    HStack(spacing: 4) {
                    
                    }
                    .foregroundColor(.secondary)
                    
                    Circle()
                        .fill(Color.secondary.opacity(0.3))
                        .frame(width: 3, height: 3)
                    
                    Text("Time: "+item.time)
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
            
            // Price and Performance
            VStack(alignment: .trailing, spacing: 6) {
                Text(item.bid)
                    .font(.system(size: 18, weight: .bold, design: .rounded))
                    .foregroundColor(.primary)
                
                HStack(spacing: 4) {
                    Image(systemName: performanceIcon)
                        .font(.system(size: 10, weight: .bold))
                    Text(item.diffPercent)
                        .font(.system(size: 13, weight: .semibold))
                }
                .foregroundColor(diffColor)
                .padding(.horizontal, 10)
                .padding(.vertical, 4)
                .background(
                    Capsule()
                        .fill(diffColor.opacity(0.12))
                )
            }
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(isPressed ? 0.12 : 0.06), radius: isPressed ? 12 : 8, x: 0, y: isPressed ? 6 : 3)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(
                    LinearGradient(
                        colors: [diffColor.opacity(0.1), diffColor.opacity(0.05)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1
                )
        )
        .scaleEffect(isPressed ? 0.98 : 1.0)
    }
    
    private var diffColor: Color {
        if item.diff.hasPrefix("+") {
            return .green
        } else if item.diff.hasPrefix("-") {
            return .red
        } else {
            return .orange
        }
    }
    
    private var performanceIcon: String {
        if item.diff.hasPrefix("+") {
            return "arrow.up"
        } else if item.diff.hasPrefix("-") {
            return "arrow.down"
        } else {
            return "minus"
        }
    }
}

// MARK: - Supporting Views
struct FilterChip: View {
    let title: String
    let icon: String
    let isSelected: Bool
    let count: Int
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 13, weight: .semibold))
                Text(title)
                    .font(.system(size: 14, weight: .semibold))
                
                if count > 0 {
                    Text("\(count)")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(isSelected ? .white : .secondary)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(
                            Capsule()
                                .fill(isSelected ? Color.white.opacity(0.25) : Color(.systemGray5))
                        )
                }
            }
            .foregroundColor(isSelected ? .white : .primary)
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(
                Capsule()
                    .fill(isSelected ? Color.blue : Color(.systemGray6))
            )
            .shadow(color: isSelected ? .blue.opacity(0.3) : .clear, radius: 8, x: 0, y: 4)
        }
        .buttonStyle(ScaleButtonStyle())
    }
}

struct MarketStatItem: View {
    let title: String
    let count: Int
    let color: Color
    let icon: String
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 20, weight: .medium))
                .foregroundColor(color)
            
            Text("\(count)")
                .font(.system(size: 22, weight: .bold, design: .rounded))
                .foregroundColor(.primary)
            
            Text(title)
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
    }
}

struct CardButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.97 : 1.0)
            .opacity(configuration.isPressed ? 0.9 : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.6), value: configuration.isPressed)
    }
}

struct ScaleButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: configuration.isPressed)
    }
}

// MARK: - Filter Enum
enum StockFilter: CaseIterable {
    case all, gainers, losers
    
    var title: String {
        switch self {
        case .all: return "All"
        case .gainers: return "Gainers"
        case .losers: return "Losers"
        }
    }
    
    var icon: String {
        switch self {
        case .all: return "list.bullet"
        case .gainers: return "arrow.up.circle.fill"
        case .losers: return "arrow.down.circle.fill"
        }
    }
}

// MARK: - Error and Empty States
struct ErrorCardView: View {
    let errorMessage: String
    let onRetry: () -> Void
    
    var body: some View {
        VStack(spacing: 24) {
            ZStack {
                Circle()
                    .fill(Color.orange.opacity(0.1))
                    .frame(width: 80, height: 80)
                
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.system(size: 36))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.orange, .orange.opacity(0.7)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            }
            
            VStack(spacing: 10) {
                Text("Unable to Load Data")
                    .font(.system(size: 22, weight: .bold))
                    .foregroundColor(.primary)
                
                Text(errorMessage)
                    .font(.system(size: 15))
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .lineLimit(3)
                    .padding(.horizontal, 30)
            }
            
            Button(action: onRetry) {
                HStack(spacing: 10) {
                    Image(systemName: "arrow.clockwise")
                        .font(.system(size: 15, weight: .semibold))
                    Text("Try Again")
                        .font(.system(size: 16, weight: .semibold))
                }
                .foregroundColor(.white)
                .padding(.horizontal, 28)
                .padding(.vertical, 14)
                .background(
                    Capsule()
                        .fill(
                            LinearGradient(
                                colors: [.blue, .blue.opacity(0.8)],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .shadow(color: .blue.opacity(0.4), radius: 12, x: 0, y: 6)
                )
            }
            .buttonStyle(ScaleButtonStyle())
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 50)
        .padding(.horizontal, 20)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.06), radius: 12, x: 0, y: 4)
        )
    }
}

struct EmptyStateCardView: View {
    let onRefresh: () -> Void
    
    var body: some View {
        VStack(spacing: 24) {
            ZStack {
                Circle()
                    .fill(Color.blue.opacity(0.1))
                    .frame(width: 100, height: 100)
                
                Image(systemName: "chart.line.uptrend.xyaxis")
                    .font(.system(size: 44))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.blue, .blue.opacity(0.6)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            }
            
            VStack(spacing: 10) {
                Text("Your Watchlist is Empty")
                    .font(.system(size: 22, weight: .bold))
                    .foregroundColor(.primary)
                
                Text("Add stocks to your watchlist to track their performance")
                    .font(.system(size: 15))
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 30)
            }
            
            Button(action: onRefresh) {
                HStack(spacing: 10) {
                    Image(systemName: "arrow.clockwise")
                        .font(.system(size: 15, weight: .semibold))
                    Text("Refresh")
                        .font(.system(size: 16, weight: .semibold))
                }
                .foregroundColor(.white)
                .padding(.horizontal, 28)
                .padding(.vertical, 14)
                .background(
                    Capsule()
                        .fill(
                            LinearGradient(
                                colors: [.blue, .blue.opacity(0.8)],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .shadow(color: .blue.opacity(0.4), radius: 12, x: 0, y: 6)
                )
            }
            .buttonStyle(ScaleButtonStyle())
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 50)
        .padding(.horizontal, 20)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.06), radius: 12, x: 0, y: 4)
        )
    }
}

#Preview {
    ContentView().environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
}
