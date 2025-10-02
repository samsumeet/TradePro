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
            VStack {
                if isLoading {
                    ProgressView("Loading stocks...")
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if watchlistItems.isEmpty && !errorMessage.isEmpty {
                    VStack {
                        Image(systemName: "exclamationmark.triangle")
                            .font(.system(size: 50))
                            .foregroundColor(.orange)
                        Text("Failed to load stocks")
                            .font(.headline)
                        Text(errorMessage)
                            .font(.caption)
                            .multilineTextAlignment(.center)
                            .padding()
                        Button("Retry") {
                            fetchWatchlist()
                        }
                        .buttonStyle(.borderedProminent)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if watchlistItems.isEmpty {
                    VStack {
                        Image(systemName: "chart.line.uptrend.xyaxis")
                            .font(.system(size: 50))
                            .foregroundColor(.blue)
                        Text("No stocks available")
                            .font(.headline)
                        Text("Pull to refresh or tap the refresh button")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    List(watchlistItems, id: \.wkn) { item in
                        NavigationLink(destination: StockDetailsView(stock: item)) {
                            StockRowView(item: item)
                        }
                    }
                    .refreshable {
                        fetchWatchlist()
                    }
                }
            }
            .navigationTitle("Stock Watchlist")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: fetchWatchlist) {
                        Image(systemName: "arrow.clockwise")
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
}

struct StockRowView: View {
    let item: WatchlistItem
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(item.name)
                        .font(.headline)
                        .lineLimit(1)
                    Text("WKN: \(item.wkn)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 2) {
                    HStack(spacing: 4) {
                        Text(item.diff)
                            .font(.caption)
                            .foregroundColor(diffColor)
                        Text("(\(item.diffPercent))")
                            .font(.caption)
                            .foregroundColor(diffColor)
                    }
                    Text(item.time)
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
            
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Bid")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                    Text(item.bid)
                        .font(.subheadline)
                        .fontWeight(.medium)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 2) {
                    Text("Ask")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                    Text(item.ask)
                        .font(.subheadline)
                        .fontWeight(.medium)
                }
            }
        }
        .padding(.vertical, 4)
    }
    
    private var diffColor: Color {
        if item.diff.hasPrefix("+") {
            return .green
        } else if item.diff.hasPrefix("-") {
            return .red
        } else {
            return .primary
        }
    }
}

#Preview {
    ContentView().environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
}