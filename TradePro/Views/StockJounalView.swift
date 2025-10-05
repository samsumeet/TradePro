//
//  StockJounalView.swift
//  TradePro
//
//  Created by Sumeet Bachchas on 03.10.25.
//

import SwiftUI
import CoreData

enum TradeType: String, CaseIterable, Identifiable, Codable {
    case profit = "Profit"
    case loss = "Loss"
    
    var id: String { self.rawValue }
    
    var color: Color {
        switch self {
        case .profit: return Color(red: 0.16, green: 0.82, blue: 0.65) // Emerald Green
        case .loss: return Color(red: 0.98, green: 0.31, blue: 0.35) // Professional Red
        }
    }
    
    var icon: String {
        switch self {
        case .profit: return "arrow.up.circle.fill"
        case .loss: return "arrow.down.circle.fill"
        }
    }
}

struct StockJounalView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \StockJournal.timestamp, ascending: false)],
        animation: .default)
    private var journalEntries: FetchedResults<StockJournal>
    
    @State private var stocks: [Stock] = []
    @State private var selectedStock: Stock?
    @State private var searchText = ""
    @State private var amount: String = ""
    @State private var selectedTradeType: TradeType = .profit
    @State private var selectedDate = Date()
    @State private var showingAlert = false
    @State private var alertMessage = ""
    @State private var showingDropdown = false
    @State private var isSuccessAlert = false
    
    // Professional Trading App Colors
    private let primaryBackground = Color(red: 0.07, green: 0.09, blue: 0.12) // Dark Navy #121820
    private let secondaryBackground = Color(red: 0.10, green: 0.12, blue: 0.16) // Slate #1A1F28
    private let cardBackground = Color(red: 0.13, green: 0.15, blue: 0.19) // Card Dark #212730
    private let accentBlue = Color(red: 0.20, green: 0.51, blue: 0.98) // Financial Blue #3483FA
    private let textPrimary = Color(red: 0.95, green: 0.96, blue: 0.97) // Off White #F2F4F7
    private let textSecondary = Color(red: 0.60, green: 0.63, blue: 0.68) // Gray #999FAD
    private let borderColor = Color(red: 0.18, green: 0.21, blue: 0.26) // Border #2E3542
    
    var filteredStocks: [Stock] {
    
        if searchText.isEmpty {
            return stocks
        } else {
            return stocks.filter { stock in
                stock.name.localizedCaseInsensitiveContains(searchText) ||
                stock.wkn.localizedCaseInsensitiveContains(searchText)
            }
        }
        
    }
    func exportToJSONManually() {
        let context = PersistenceController.shared.container.viewContext
        let fetchRequest: NSFetchRequest<StockJournal> = StockJournal.fetchRequest()
        
        do {
            let journals = try context.fetch(fetchRequest)
            
            var jsonArray: [[String: Any]] = []
            
            for journal in journals {
                var dict: [String: Any] = [:]
                dict["id"] = journal.id?.uuidString
                dict["stockName"] = journal.stockName
                dict["instrumentID"] = journal.instrumentID
                dict["profit"] = journal.profit
                dict["date"] = journal.date?.ISO8601Format()
                dict["timestamp"] = journal.timestamp?.ISO8601Format()
                dict["tradeType"] = journal.tradeType
                
                jsonArray.append(dict)
            }
            
            // Convert to JSON
            let jsonData = try JSONSerialization.data(withJSONObject: jsonArray, options: .prettyPrinted)
            
            if let jsonString = String(data: jsonData, encoding: .utf8) {
                print("📊 Core Data as JSON:")
                print(jsonString)
            }
            
        } catch {
            print("❌ Error: \(error)")
        }
    }

    var body: some View {
        NavigationView {
            ZStack {
                // Professional Dark Background
                primaryBackground
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 24) {
                        // Header with Heatmap Link
                        HStack(alignment: .center) {
                            VStack(alignment: .leading, spacing: 6) {
                                Text("Trading Journal")
                                    .font(.system(size: 28, weight: .bold, design: .rounded))
                                    .foregroundColor(textPrimary)
                                Text("Track your performance")
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundColor(textSecondary)
                            }
                            
                            Spacer()
                            
                            NavigationLink(destination: StockHeatMapView()) {
                                HStack(spacing: 6) {
                                    Image(systemName: "chart.bar.fill")
                                        .font(.system(size: 13, weight: .semibold))
                                    Text("Heatmap")
                                        .font(.system(size: 13, weight: .semibold))
                                }
                                .padding(.horizontal, 16)
                                .padding(.vertical, 10)
                                .background(accentBlue)
                                .foregroundColor(.white)
                                .cornerRadius(10)
                                .shadow(color: accentBlue.opacity(0.3), radius: 8, x: 0, y: 4)
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.top, 12)
                        
                        // Form Card
                        VStack(spacing: 18) {
                            // Stock Selection
                            VStack(alignment: .leading, spacing: 10) {
                                HStack(spacing: 6) {
                                    Image(systemName: "chart.line.uptrend.xyaxis")
                                        .font(.system(size: 13, weight: .semibold))
                                        .foregroundColor(accentBlue)
                                    Text("Select Stock")
                                        .font(.system(size: 14, weight: .semibold))
                                        .foregroundColor(textPrimary)
                                }
                                
                                Button(action: {
                                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                        showingDropdown.toggle()
                                    }
                                }) {
                                    HStack {
                                        if let selected = selectedStock {
                                            VStack(alignment: .leading, spacing: 3) {
                                                Text(selected.name)
                                                    .font(.system(size: 15, weight: .medium))
                                                    .foregroundColor(textPrimary)
                                                Text("WKN: \(selected.wkn)")
                                                    .font(.system(size: 12))
                                                    .foregroundColor(textSecondary)
                                            }
                                        } else {
                                            Text("Choose a stock...")
                                                .font(.system(size: 15))
                                                .foregroundColor(textSecondary)
                                        }
                                        Spacer()
                                        Image(systemName: "chevron.down")
                                            .font(.system(size: 12, weight: .semibold))
                                            .foregroundColor(textSecondary)
                                            .rotationEffect(.degrees(showingDropdown ? 180 : 0))
                                            .animation(.spring(response: 0.3), value: showingDropdown)
                                    }
                                    .padding(14)
                                    .background(secondaryBackground)
                                    .cornerRadius(10)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 10)
                                            .stroke(showingDropdown ? accentBlue : borderColor, lineWidth: 1.5)
                                    )
                                }
                            }
                            
                            // Trade Type Picker (Profit/Loss)
                            VStack(alignment: .leading, spacing: 10) {
                                HStack(spacing: 6) {
                                    Image(systemName: "arrow.up.arrow.down.circle")
                                        .font(.system(size: 13, weight: .semibold))
                                        .foregroundColor(accentBlue)
                                    Text("Trade Type")
                                        .font(.system(size: 14, weight: .semibold))
                                        .foregroundColor(textPrimary)
                                }
                                
                                HStack(spacing: 12) {
                                    ForEach(TradeType.allCases) { type in
                                        Button(action: {
                                            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                                selectedTradeType = type
                                            }
                                        }) {
                                            HStack(spacing: 8) {
                                                Image(systemName: type.icon)
                                                    .font(.system(size: 14, weight: .semibold))
                                                Text(type.rawValue)
                                                    .font(.system(size: 14, weight: .semibold))
                                            }
                                            .frame(maxWidth: .infinity)
                                            .padding(.vertical, 12)
                                            .background(
                                                selectedTradeType == type
                                                    ? type.color.opacity(0.15)
                                                    : secondaryBackground
                                            )
                                            .foregroundColor(
                                                selectedTradeType == type
                                                    ? type.color
                                                    : textSecondary
                                            )
                                            .cornerRadius(10)
                                            .overlay(
                                                RoundedRectangle(cornerRadius: 10)
                                                    .stroke(
                                                        selectedTradeType == type
                                                            ? type.color
                                                            : borderColor,
                                                        lineWidth: 1.5
                                                    )
                                            )
                                        }
                                    }
                                }
                            }
                            
                            // Amount Field
                            VStack(alignment: .leading, spacing: 10) {
                                HStack(spacing: 6) {
                                    Image(systemName: "dollarsign.circle")
                                        .font(.system(size: 13, weight: .semibold))
                                        .foregroundColor(accentBlue)
                                    Text("Amount")
                                        .font(.system(size: 14, weight: .semibold))
                                        .foregroundColor(textPrimary)
                                }
                                
                                HStack(spacing: 10) {
                                    Image(systemName: selectedTradeType.icon)
                                        .foregroundColor(selectedTradeType.color)
                                        .font(.system(size: 18, weight: .semibold))
                                    
                                    TextField("0.00", text: $amount)
                                        .keyboardType(.decimalPad)
                                        .font(.system(size: 16, weight: .medium))
                                        .foregroundColor(textPrimary)
                                }
                                .padding(14)
                                .background(secondaryBackground)
                                .cornerRadius(10)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 10)
                                        .stroke(borderColor, lineWidth: 1.5)
                                )
                            }
                            
                            // Date Picker
                            VStack(alignment: .leading, spacing: 10) {
                                HStack(spacing: 6) {
                                    Image(systemName: "calendar")
                                        .font(.system(size: 13, weight: .semibold))
                                        .foregroundColor(accentBlue)
                                    Text("Trade Date")
                                        .font(.system(size: 14, weight: .semibold))
                                        .foregroundColor(textPrimary)
                                }
                                
                                DatePicker("", selection: $selectedDate, displayedComponents: .date)
                                    .datePickerStyle(.compact)
                                    .colorScheme(.dark)
                                    .padding(12)
                                    .background(secondaryBackground)
                                    .cornerRadius(10)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 10)
                                            .stroke(borderColor, lineWidth: 1.5)
                                    )
                            }
                            
                            // Save Button
                            Button(action: saveJournalEntry) {
                                HStack(spacing: 10) {
                                    Image(systemName: "checkmark.circle.fill")
                                        .font(.system(size: 16, weight: .bold))
                                    Text("Save Entry")
                                        .font(.system(size: 16, weight: .bold))
                                }
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 16)
                                .background(
                                    selectedStock == nil || amount.isEmpty
                                        ? Color.gray.opacity(0.3)
                                        : selectedTradeType.color
                                )
                                .foregroundColor(.white)
                                .cornerRadius(10)
                                .shadow(
                                    color: selectedStock == nil || amount.isEmpty
                                        ? Color.clear
                                        : selectedTradeType.color.opacity(0.4),
                                    radius: 12, x: 0, y: 6
                                )
                            }
                            .disabled(selectedStock == nil || amount.isEmpty)
                        }
                        .padding(20)
                        .background(cardBackground)
                        .cornerRadius(16)
                        .shadow(color: Color.black.opacity(0.3), radius: 15, x: 0, y: 8)
                        .padding(.horizontal, 20)
                        
                        // Journal Entries Section with Scrolling
                        VStack(alignment: .leading, spacing: 16) {
                            HStack {
                                HStack(spacing: 6) {
                                    Image(systemName: "list.bullet.clipboard.fill")
                                        .font(.system(size: 16, weight: .bold))
                                        .foregroundColor(accentBlue)
                                    Text("Recent Entries")
                                        .font(.system(size: 20, weight: .bold, design: .rounded))
                                        .foregroundColor(textPrimary)
                                }
                                Spacer()
                                if !journalEntries.isEmpty {
                                    Text("\(journalEntries.count)")
                                        .font(.system(size: 13, weight: .bold))
                                        .foregroundColor(textPrimary)
                                        .padding(.horizontal, 10)
                                        .padding(.vertical, 5)
                                        .background(secondaryBackground)
                                        .cornerRadius(8)
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 8)
                                                .stroke(borderColor, lineWidth: 1)
                                        )
                                }
                            }
                            .padding(.horizontal, 20)
                            
                            if journalEntries.isEmpty {
                                VStack(spacing: 16) {
                                    Image(systemName: "chart.line.text.clipboard")
                                        .font(.system(size: 48, weight: .light))
                                        .foregroundColor(textSecondary.opacity(0.5))
                                    
                                    VStack(spacing: 6) {
                                        Text("No journal entries yet")
                                            .font(.system(size: 16, weight: .semibold))
                                            .foregroundColor(textPrimary)
                                        Text("Start tracking your trades to see them here")
                                            .font(.system(size: 13))
                                            .foregroundColor(textSecondary)
                                    }
                                }
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 50)
                                .background(cardBackground)
                                .cornerRadius(16)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 16)
                                        .stroke(borderColor, lineWidth: 1)
                                )
                                .padding(.horizontal, 20)
                            } else {
                                // Scrollable entries container
                                ScrollView(.vertical, showsIndicators: true) {
                                    LazyVStack(spacing: 12) {
                                        ForEach(journalEntries) { entry in
                                            JournalEntryRow(
                                                entry: entry,
                                                cardBg: cardBackground,
                                                textPrimary: textPrimary,
                                                textSecondary: textSecondary,
                                                borderColor: borderColor
                                            )
                                        }
                                    }
                                    .padding(.horizontal, 20)
                                    .padding(.bottom, 20)
                                }
                                .frame(height: 400) // Fixed height for scrollable area
                                .background(
                                    RoundedRectangle(cornerRadius: 16)
                                        .fill(primaryBackground.opacity(0.5))
                                )
                            }
                        }
                        .padding(.top, 8)
                    }
                    .padding(.bottom, 30)
                }
                
                // Dropdown Overlay
                if showingDropdown {
                    Color.black.opacity(0.6)
                        .ignoresSafeArea()
                        .onTapGesture {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                showingDropdown = false
                            }
                        }
                    
                    VStack(spacing: 0) {
                        // Search Bar
                        HStack(spacing: 10) {
                            Image(systemName: "magnifyingglass")
                                .foregroundColor(textSecondary)
                                .font(.system(size: 14))
                            TextField("Search stocks...", text: $searchText)
                                .textFieldStyle(PlainTextFieldStyle())
                                .font(.system(size: 15))
                                .foregroundColor(textPrimary)
                        }
                        .padding(14)
                        .background(secondaryBackground)
                        .cornerRadius(10)
                        .overlay(
                            RoundedRectangle(cornerRadius: 10)
                                .stroke(borderColor, lineWidth: 1.5)
                        )
                        .padding()
                        
                        Divider()
                            .background(borderColor)
                        
                        if filteredStocks.isEmpty {
                            VStack(spacing: 12) {
                                Image(systemName: "magnifyingglass")
                                    .font(.system(size: 38))
                                    .foregroundColor(textSecondary.opacity(0.5))
                                Text("No results found")
                                    .font(.system(size: 15, weight: .medium))
                                    .foregroundColor(textSecondary)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 40)
                        } else {
                            ScrollView {
                                LazyVStack(spacing: 0) {
                                    ForEach(filteredStocks.prefix(10), id: \.wkn) { stock in
                                        Button(action: {
                                            selectedStock = stock
                                            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                                showingDropdown = false
                                            }
                                            searchText = ""
                                            UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
                                        }) {
                                            HStack {
                                                VStack(alignment: .leading, spacing: 4) {
                                                    Text(stock.name)
                                                        .font(.system(size: 15, weight: .medium))
                                                        .foregroundColor(textPrimary)
                                                    Text("WKN: \(stock.wkn)")
                                                        .font(.system(size: 12))
                                                        .foregroundColor(textSecondary)
                                                }
                                                Spacer()
                                                Image(systemName: "chevron.right")
                                                    .font(.system(size: 11, weight: .semibold))
                                                    .foregroundColor(textSecondary.opacity(0.5))
                                            }
                                            .padding(.vertical, 14)
                                            .padding(.horizontal, 16)
                                        }
                                        
                                        if stock.wkn != filteredStocks.prefix(10).last?.wkn {
                                            Divider()
                                                .background(borderColor)
                                                .padding(.leading, 16)
                                        }
                                    }
                                }
                            }
                            .frame(maxHeight: 300)
                        }
                    }
                    .background(cardBackground)
                    .cornerRadius(16)
                    .shadow(color: Color.black.opacity(0.4), radius: 25, x: 0, y: 15)
                    .padding(.horizontal, 20)
                    .frame(maxHeight: .infinity, alignment: .top)
                    .padding(.top, 100)
                    .transition(.scale(scale: 0.95).combined(with: .opacity))
                }
            }
            .navigationBarHidden(true)
            .preferredColorScheme(.dark)
            .onAppear {
                if stocks.isEmpty {
                    loadStocks()
                }
            }
            .alert(isSuccessAlert ? "Success" : "Error", isPresented: $showingAlert) {
                Button("OK") {
                    isSuccessAlert = false
                }
            } message: {
                Text(alertMessage)
            }
        }
    }
    
    private func loadStocks() {
        guard let url = Bundle.main.url(forResource: "stocks", withExtension: "json") else {
            print("Could not find stocks.json file")
            return
        }
        
        do {
            let data = try Data(contentsOf: url)
            stocks = try JSONDecoder().decode([Stock].self, from: data)
        } catch {
            print("Error loading stocks: \(error)")
        }
    }
    
    private func saveJournalEntry() {
        guard let selectedStock = selectedStock,
              let amountValue = Float(amount) else {
            alertMessage = "Please fill in all fields correctly"
            isSuccessAlert = false
            showingAlert = true
            return
        }
        
        let newEntry = StockJournal(context: viewContext)
        newEntry.id = UUID()
        newEntry.stockName = selectedStock.name
        newEntry.instrumentID = selectedStock.instrument_id
        newEntry.profit = selectedTradeType == .profit ? amountValue : -amountValue
        newEntry.tradeType = selectedTradeType.rawValue
        newEntry.date = selectedDate
        newEntry.timestamp = Date()
        
        do {
            try viewContext.save()
            
            withAnimation {
                self.selectedStock = nil
                self.amount = ""
                self.selectedTradeType = .profit
                self.selectedDate = Date()
                self.showingDropdown = false
                self.searchText = ""
            }
            
            alertMessage = "Journal entry saved successfully!"
            isSuccessAlert = true
            showingAlert = true
        } catch {
            alertMessage = "Error saving entry: \(error.localizedDescription)"
            isSuccessAlert = false
            showingAlert = true
        }
    }
}

struct JournalEntryRow: View {
    let entry: StockJournal
    let cardBg: Color
    let textPrimary: Color
    let textSecondary: Color
    let borderColor: Color
    
    private var tradeType: TradeType {
        TradeType(rawValue: entry.tradeType ?? "Profit") ?? .profit
    }
    
    private var isProfit: Bool {
        entry.profit >= 0
    }
    
    var body: some View {
        HStack(spacing: 0) {
            // Profit/Loss Indicator Bar
            Rectangle()
                .fill(tradeType.color)
                .frame(width: 4)
            
            VStack(alignment: .leading, spacing: 10) {
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 6) {
                        Text(entry.stockName ?? "Unknown Stock")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(textPrimary)
                        
                        HStack(spacing: 10) {
                            if let date = entry.date {
                                HStack(spacing: 4) {
                                    Image(systemName: "calendar")
                                        .font(.system(size: 11))
                                    Text(date, style: .date)
                                        .font(.system(size: 12))
                                }
                                .foregroundColor(textSecondary)
                            }
                            
                            // Trade Type Badge
                            HStack(spacing: 4) {
                                Image(systemName: tradeType.icon)
                                    .font(.system(size: 10))
                                Text(tradeType.rawValue)
                                    .font(.system(size: 11, weight: .semibold))
                            }
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(tradeType.color.opacity(0.15))
                            .foregroundColor(tradeType.color)
                            .cornerRadius(6)
                        }
                    }
                    
                    Spacer()
                    
                    VStack(alignment: .trailing, spacing: 4) {
                        Text("€\(abs(entry.profit), specifier: "%.2f")")
                            .font(.system(size: 20, weight: .bold, design: .rounded))
                            .foregroundColor(tradeType.color)
                        
                        HStack(spacing: 4) {
                            Image(systemName: isProfit ? "arrow.up.right" : "arrow.down.right")
                                .font(.system(size: 10, weight: .bold))
                            Text(isProfit ? "Profit" : "Loss")
                                .font(.system(size: 11, weight: .semibold))
                        }
                        .foregroundColor(tradeType.color)
                    }
                }
            }
            .padding(16)
        }
        .background(cardBg)
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(borderColor, lineWidth: 1)
        )
        .shadow(color: Color.black.opacity(0.2), radius: 8, x: 0, y: 4)
    }
}

#Preview {
    StockJounalView()
        .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
}
