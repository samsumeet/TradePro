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
    
    private let scraper = WatchlistScraper()

    var body: some View {
        NavigationView {
            ZStack {
                // Background gradient
                LinearGradient(
                    gradient: Gradient(colors: [Color(.systemBackground), Color(.systemGray6).opacity(0.3)]),
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()
                
                ScrollView {
                    LazyVStack(spacing: 16) {
                        if isLoading {
                            VStack(spacing: 20) {
                                ProgressView()
                                    .scaleEffect(1.2)
                                Text("Loading stocks...")
                                    .font(.headline)
                                    .foregroundColor(.secondary)
                            }
                            .frame(maxWidth: .infinity)
                            .frame(height: 200)
                        } else if watchlistItems.isEmpty && !errorMessage.isEmpty {
                            ErrorCardView(errorMessage: errorMessage) {
                                fetchWatchlist()
                            }
                        } else if watchlistItems.isEmpty {
                            EmptyStateCardView {
                                fetchWatchlist()
                            }
                        } else {
                            ForEach(watchlistItems, id: \.wkn) { item in
                                NavigationLink(destination: StockDetailsView(stock: item)) {
                                    StockCardView(item: item)
                                }
                                .buttonStyle(PlainButtonStyle())
                            }
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 20)
                }
                .refreshable {
                    await performRefresh()
                }
            }
            .navigationTitle("Stock Watchlist")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: fetchWatchlist) {
                        Image(systemName: "arrow.clockwise")
                            .font(.system(size: 16, weight: .medium))
                    }
                    .disabled(isLoading)
                }
            }
            .onAppear {
                fetchWatchlist()
            }
            .alert("Error", isPresented: $showError) {
                Button("OK") { }
            } message: {
                Text(errorMessage)
            }
        }
    }
    
    private func fetchWatchlist() {
        isLoading = true
        errorMessage = ""
        
        scraper.fetchWatchlist { items, error in
            DispatchQueue.main.async {
                isLoading = false
                
                if let error = error {
                    errorMessage = error.localizedDescription
                    showError = true
                } else if let items = items {
                    watchlistItems = items
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
            continuation.resume()
        }
    }
}

struct StockCardView: View {
    let item: WatchlistItem
    
    var body: some View {
        VStack(spacing: 0) {
            // Header with stock name and change
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(item.name)
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.primary)
                        .lineLimit(1)
                    
                    Text("WKN: \(item.wkn)")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    HStack(spacing: 6) {
                        Text(item.diff)
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(diffColor)
                        
                        Text("(\(item.diffPercent))")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(diffColor)
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(
                        Capsule()
                            .fill(diffColor.opacity(0.1))
                    )
                    
                    Text(item.time)
                        .font(.system(size: 10, weight: .medium))
                        .foregroundColor(.secondary)
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 20)
            .padding(.bottom, 16)
            
            // Divider
            Rectangle()
                .fill(Color(.systemGray5))
                .frame(height: 1)
                .padding(.horizontal, 20)
            
            // Bid/Ask section
            HStack(spacing: 0) {
                // Bid section
                VStack(spacing: 8) {
                    HStack {
                        Circle()
                            .fill(.green.opacity(0.2))
                            .frame(width: 8, height: 8)
                        Text("Bid")
                            .font(.system(size: 11, weight: .medium))
                            .foregroundColor(.secondary)
                        Spacer()
                    }
                    
                    HStack {
                        Text(item.bid)
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.primary)
                        Spacer()
                    }
                }
                .frame(maxWidth: .infinity)
                
                // Vertical divider
                Rectangle()
                    .fill(Color(.systemGray5))
                    .frame(width: 1, height: 40)
                
                // Ask section
                VStack(spacing: 8) {
                    HStack {
                        Spacer()
                        Text("Ask")
                            .font(.system(size: 11, weight: .medium))
                            .foregroundColor(.secondary)
                        Circle()
                            .fill(.red.opacity(0.2))
                            .frame(width: 8, height: 8)
                    }
                    
                    HStack {
                        Spacer()
                        Text(item.ask)
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.primary)
                    }
                }
                .frame(maxWidth: .infinity)
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
        }
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemBackground))
                .shadow(
                    color: Color.black.opacity(0.08),
                    radius: 8,
                    x: 0,
                    y: 2
                )
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color(.systemGray6), lineWidth: 0.5)
        )
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
}

struct ErrorCardView: View {
    let errorMessage: String
    let onRetry: () -> Void
    
    var body: some View {
        VStack(spacing: 20) {
            VStack(spacing: 12) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.system(size: 40))
                    .foregroundColor(.orange)
                
                Text("Failed to load stocks")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(.primary)
                
                Text(errorMessage)
                    .font(.system(size: 14))
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 20)
            }
            
            Button(action: onRetry) {
                HStack(spacing: 8) {
                    Image(systemName: "arrow.clockwise")
                        .font(.system(size: 14, weight: .medium))
                    Text("Retry")
                        .font(.system(size: 16, weight: .semibold))
                }
                .foregroundColor(.white)
                .padding(.horizontal, 24)
                .padding(.vertical, 12)
                .background(
                    RoundedRectangle(cornerRadius: 25)
                        .fill(.blue)
                )
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemBackground))
                .shadow(
                    color: Color.black.opacity(0.08),
                    radius: 8,
                    x: 0,
                    y: 2
                )
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color(.systemGray6), lineWidth: 0.5)
        )
    }
}

struct EmptyStateCardView: View {
    let onRefresh: () -> Void
    
    var body: some View {
        VStack(spacing: 20) {
            VStack(spacing: 12) {
                Image(systemName: "chart.line.uptrend.xyaxis")
                    .font(.system(size: 50))
                    .foregroundColor(.blue)
                
                Text("No stocks available")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(.primary)
                
                Text("Pull to refresh or tap the refresh button to load your watchlist")
                    .font(.system(size: 14))
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 20)
            }
            
            Button(action: onRefresh) {
                HStack(spacing: 8) {
                    Image(systemName: "arrow.clockwise")
                        .font(.system(size: 14, weight: .medium))
                    Text("Refresh")
                        .font(.system(size: 16, weight: .semibold))
                }
                .foregroundColor(.white)
                .padding(.horizontal, 24)
                .padding(.vertical, 12)
                .background(
                    RoundedRectangle(cornerRadius: 25)
                        .fill(.blue)
                )
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemBackground))
                .shadow(
                    color: Color.black.opacity(0.08),
                    radius: 8,
                    x: 0,
                    y: 2
                )
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color(.systemGray6), lineWidth: 0.5)
        )
    }
}

#Preview {
    ContentView().environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
}
