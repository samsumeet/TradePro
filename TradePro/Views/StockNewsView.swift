//
//  NewsView.swift
//  TradePro
//
//  Created by Sumeet Bachchas on 06.10.25.
//

import SwiftUI

struct StockNewsView: View {
    @StateObject private var service = StockAnalysisService()
       @State private var selectedStock: StockData?
       
       // Professional Trading App Colors
       private let primaryBackground = Color(red: 0.07, green: 0.09, blue: 0.12)
       private let cardBackground = Color(red: 0.13, green: 0.15, blue: 0.19)
       private let accentBlue = Color(red: 0.20, green: 0.51, blue: 0.98)
       private let textPrimary = Color(red: 0.95, green: 0.96, blue: 0.97)
       private let textSecondary = Color(red: 0.60, green: 0.63, blue: 0.68)
       private let borderColor = Color(red: 0.18, green: 0.21, blue: 0.26)
       
       var body: some View {
           NavigationView {
               ZStack {
                   primaryBackground.ignoresSafeArea()
                   
                   ScrollView {
                       VStack(spacing: 16) {
                           if service.isLoading {
                               loadingView
                           } else if let error = service.errorMessage {
                               errorView(message: error)
                           } else if service.stockDataList.isEmpty {
                               emptyStateView
                           } else {
                               ForEach(service.stockDataList) { stock in
                                   StockAnalysisCard(stock: stock)
                                       .onTapGesture {
                                           selectedStock = stock
                                       }
                               }
                           }
                       }
                       .padding()
                   }
                   .refreshable {
                       await loadData()
                   }
               }
               .navigationTitle("Stock News Analysis")
               .navigationBarTitleDisplayMode(.large)
               .toolbar {
                   ToolbarItem(placement: .navigationBarTrailing) {
                       Button(action: { Task { await loadData() } }) {
                           Image(systemName: "arrow.clockwise")
                               .foregroundColor(accentBlue)
                       }
                       .disabled(service.isLoading)
                   }
               }
               .sheet(item: $selectedStock) { stock in
                   StockDetailSheet(stock: stock)
               }
           }
           .preferredColorScheme(.dark)
           .task {
               await loadData()
           }
       }
       
       private func loadData() async {
           do {
               _ = try await service.fetchStockAnalysis()
           } catch {
               await MainActor.run {
                   service.errorMessage = error.localizedDescription
               }
           }
       }
       
       // MARK: - Loading View
       private var loadingView: some View {
           VStack(spacing: 20) {
               ProgressView()
                   .scaleEffect(1.5)
                   .tint(accentBlue)
               
               Text("Loading stock data...")
                   .font(.system(size: 16, weight: .medium))
                   .foregroundColor(textSecondary)
           }
           .frame(maxWidth: .infinity, maxHeight: .infinity)
           .padding(.top, 100)
       }
       
       // MARK: - Error View
       private func errorView(message: String) -> some View {
           VStack(spacing: 20) {
               Image(systemName: "exclamationmark.triangle")
                   .font(.system(size: 50))
                   .foregroundColor(.red)
               
               Text("Error Loading Data")
                   .font(.system(size: 20, weight: .bold))
                   .foregroundColor(textPrimary)
               
               Text(message)
                   .font(.system(size: 14))
                   .foregroundColor(textSecondary)
                   .multilineTextAlignment(.center)
                   .padding(.horizontal)
               
               Button(action: { Task { await loadData() } }) {
                   Text("Retry")
                       .font(.system(size: 16, weight: .semibold))
                       .foregroundColor(.white)
                       .padding(.horizontal, 32)
                       .padding(.vertical, 12)
                       .background(accentBlue)
                       .cornerRadius(10)
               }
           }
           .frame(maxWidth: .infinity)
           .padding(.top, 100)
       }
       
       // MARK: - Empty State
       private var emptyStateView: some View {
           VStack(spacing: 20) {
               Image(systemName: "chart.bar.doc.horizontal")
                   .font(.system(size: 50))
                   .foregroundColor(textSecondary)
               
               Text("No Stock Data Available")
                   .font(.system(size: 20, weight: .bold))
                   .foregroundColor(textPrimary)
               
               Text("Pull to refresh")
                   .font(.system(size: 14))
                   .foregroundColor(textSecondary)
           }
           .frame(maxWidth: .infinity)
           .padding(.top, 100)
       }
   }

   // MARK: - Stock Analysis Card
   struct StockAnalysisCard: View {
       let stock: StockData
       
       private let cardBackground = Color(red: 0.13, green: 0.15, blue: 0.19)
       private let textPrimary = Color(red: 0.95, green: 0.96, blue: 0.97)
       private let textSecondary = Color(red: 0.60, green: 0.63, blue: 0.68)
       private let borderColor = Color(red: 0.18, green: 0.21, blue: 0.26)
       
       var body: some View {
           VStack(alignment: .leading, spacing: 16) {
               // Header
               HStack {
                   VStack(alignment: .leading, spacing: 4) {
                       Text(stock.stockSymbol)
                           .font(.system(size: 24, weight: .bold))
                           .foregroundColor(textPrimary)
                       
                       Text(stock.companyName)
                           .font(.system(size: 14))
                           .foregroundColor(textSecondary)
                           .lineLimit(1)
                   }
                   
                   Spacer()
                   
                   VStack(alignment: .trailing, spacing: 4) {
                       Text("$\(String(format: "%.2f", stock.currentStockInfo.currentPrice))")
                           .font(.system(size: 24, weight: .bold, design: .rounded))
                           .foregroundColor(textPrimary)
                       
                       HStack(spacing: 4) {
                           Image(systemName: stock.isPriceIncreasing ? "arrow.up" : "arrow.down")
                               .font(.system(size: 12, weight: .bold))
                           Text(String(format: "%.2f%%", abs(stock.currentStockInfo.changePercent)))
                               .font(.system(size: 14, weight: .semibold))
                       }
                       .foregroundColor(stock.isPriceIncreasing ? .green : .red)
                   }
               }
               
               Divider()
                   .background(borderColor)
               
               // Stats
               HStack(spacing: 20) {
                   statItem(title: "Market Cap", value: stock.formattedMarketCap)
                   statItem(title: "Target", value: "$\(String(format: "%.0f", stock.analystRatings.targetPrice))")
                   statItem(title: "Rating", value: stock.analystRatings.consensus)
               }
               
               // News Count
               HStack {
                   Image(systemName: "newspaper")
                       .font(.system(size: 14))
                       .foregroundColor(textSecondary)
                   Text("\(stock.newsArticles.count) news articles")
                       .font(.system(size: 13))
                       .foregroundColor(textSecondary)
                   
                   Spacer()
                   
                   Text("Tap for details")
                       .font(.system(size: 12))
                       .foregroundColor(.blue)
               }
           }
           .padding(20)
           .background(cardBackground)
           .cornerRadius(16)
           .overlay(
               RoundedRectangle(cornerRadius: 16)
                   .stroke(borderColor, lineWidth: 1)
           )
           .shadow(color: Color.black.opacity(0.2), radius: 10, x: 0, y: 5)
       }
       
       private func statItem(title: String, value: String) -> some View {
           VStack(alignment: .leading, spacing: 4) {
               Text(title)
                   .font(.system(size: 11))
                   .foregroundColor(textSecondary)
               Text(value)
                   .font(.system(size: 14, weight: .semibold))
                   .foregroundColor(textPrimary)
           }
       }
   }

   // MARK: - Stock Detail Sheet
   struct StockDetailSheet: View {
       let stock: StockData
       @Environment(\.dismiss) var dismiss
       
       private let cardBackground = Color(red: 0.13, green: 0.15, blue: 0.19)
       private let textPrimary = Color(red: 0.95, green: 0.96, blue: 0.97)
       private let textSecondary = Color(red: 0.60, green: 0.63, blue: 0.68)
       
       var body: some View {
           NavigationView {
               ScrollView {
                   VStack(alignment: .leading, spacing: 20) {
                       // Price Header
                       HStack {
                           VStack(alignment: .leading) {
                               Text(stock.stockSymbol)
                                   .font(.system(size: 32, weight: .bold))
                               Text(stock.companyName)
                                   .font(.system(size: 16))
                                   .foregroundColor(textSecondary)
                           }
                           
                           Spacer()
                           
                           VStack(alignment: .trailing) {
                               Text("$\(String(format: "%.2f", stock.currentStockInfo.currentPrice))")
                                   .font(.system(size: 28, weight: .bold))
                               Text(String(format: "%.2f%%", stock.currentStockInfo.changePercent))
                                   .foregroundColor(stock.isPriceIncreasing ? .green : .red)
                           }
                       }
                       .padding()
                       
                       // News Articles
                       Text("Recent News")
                           .font(.system(size: 20, weight: .bold))
                           .padding(.horizontal)
                       
                       ForEach(stock.newsArticles) { article in
                           NewsArticleRow(article: article)
                       }
                       
                       // Risks
                       if !stock.risks.isEmpty {
                           Text("Risks")
                               .font(.system(size: 20, weight: .bold))
                               .padding(.horizontal)
                           
                           ForEach(Array(stock.risks.enumerated()), id: \.offset) { index, risk in
                               Text("• \(risk.description)")
                                   .font(.system(size: 14))
                                   .foregroundColor(textSecondary)
                                   .padding(.horizontal)
                           }
                       }
                   }
                   .padding(.bottom, 30)
               }
               .background(Color(red: 0.07, green: 0.09, blue: 0.12))
               .navigationTitle("Details")
               .navigationBarTitleDisplayMode(.inline)
               .toolbar {
                   ToolbarItem(placement: .navigationBarTrailing) {
                       Button("Done") {
                           dismiss()
                       }
                   }
               }
           }
           .preferredColorScheme(.dark)
       }
   }

   struct NewsArticleRow: View {
       let article: NewsArticle
       
       var body: some View {
           VStack(alignment: .leading, spacing: 8) {
               Text(article.headline)
                   .font(.system(size: 16, weight: .semibold))
               
               Text(article.summary)
                   .font(.system(size: 14))
                   .foregroundColor(.secondary)
                   .lineLimit(3)
               
               HStack {
                   Text(article.source)
                       .font(.system(size: 12))
                       .foregroundColor(.blue)
                   
                   Spacer()
                   
                   Text(article.date)
                       .font(.system(size: 12))
                       .foregroundColor(.secondary)
               }
           }
           .padding()
           .background(Color(red: 0.13, green: 0.15, blue: 0.19))
           .cornerRadius(12)
           .padding(.horizontal)
       }
   }


#Preview {
    StockNewsView()
}
