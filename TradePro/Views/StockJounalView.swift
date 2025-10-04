//
//  StockJounalView.swift
//  TradePro
//
//  Created by Sumeet Bachchas on 03.10.25.
//

import SwiftUI
import CoreData

struct StockJounalView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \StockJournal.timestamp, ascending: false)],
        animation: .default)
    private var journalEntries: FetchedResults<StockJournal>
    
    @State private var stocks: [Stock] = []
    @State private var selectedStock: Stock?
    @State private var searchText = ""
    @State private var profit: String = ""
    @State private var selectedDate = Date()
    @State private var showingAlert = false
    @State private var alertMessage = ""
    @State private var showingDropdown = false
    
    var filteredStocks: [Stock] {
        print(stocks[0].name)
        if searchText.isEmpty {
            return stocks
        } else {
            return stocks.filter { stock in
                stock.name.localizedCaseInsensitiveContains(searchText) ||
                stock.wkn.localizedCaseInsensitiveContains(searchText)
            }
        }
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                // Header
                HStack {
                    Text("Stock Journal")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                    
                    Spacer()
                    
                    NavigationLink(destination: StockHeatMapView()) {
                        HStack(spacing: 4) {
                            Image(systemName: "chart.bar.fill")
                            Text("Heatmap")
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                    }
                }
                .padding(.top)
                
                // Form Section
                VStack(spacing: 15) {
                    // Stock Selection Dropdown
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Select Stock")
                            .font(.headline)
                            .foregroundColor(.primary)
                        
                        VStack {
                            Button(action: {
                                showingDropdown.toggle()
                            }) {
                                HStack {
                                    Text(selectedStock?.name ?? "Choose a stock...")
                                        .foregroundColor(selectedStock != nil ? .primary : .secondary)
                                    Spacer()
                                    Image(systemName: "chevron.down")
                                        .foregroundColor(.secondary)
                                        .rotationEffect(.degrees(showingDropdown ? 180 : 0))
                                }
                                .padding()
                                .background(Color(.systemGray6))
                                .cornerRadius(10)
                            }
                            
                            if showingDropdown {
                                VStack {
                                    // Search Field
                                    TextField("Search stocks...", text: $searchText)
                                        .textFieldStyle(RoundedBorderTextFieldStyle())
                                        .padding(.horizontal)
                                    
                                    ScrollView {
                                        LazyVStack(spacing: 0) {
                                            ForEach(filteredStocks.prefix(10), id: \.wkn) { stock in
                                                Button(action: {
                                                    selectedStock = stock
                                                    showingDropdown = true
                                                    searchText = ""
                                                }) {
                                                    VStack(alignment: .leading, spacing: 4) {
                                                        Text(stock.name)
                                                            .font(.body)
                                                            .foregroundColor(.primary)
                                                        Text("WKN: \(stock.wkn)")
                                                            .font(.caption)
                                                            .foregroundColor(.secondary)
                                                    }
                                                    .frame(maxWidth: .infinity, alignment: .leading)
                                                    .padding()
                                                }
                                                .background(Color(.systemBackground))
                                                
                                                Divider()
                                            }
                                        }
                                    }
                                    .frame(maxHeight: 200)
                                }
                                .background(Color(.systemGray6))
                                .cornerRadius(10)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 10)
                                        .stroke(Color(.systemGray4), lineWidth: 1)
                                )
                            }
                        }
                    }
                    
                    // Profit Field
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Profit/Loss")
                            .font(.headline)
                            .foregroundColor(.primary)
                        
                        TextField("Enter profit/loss amount", text: $profit)
                            .keyboardType(.decimalPad)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                    }
                    
                    // Date Picker
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Date")
                            .font(.headline)
                            .foregroundColor(.primary)
                        
                        DatePicker("Select Date", selection: $selectedDate, displayedComponents: .date)
                            .datePickerStyle(CompactDatePickerStyle())
                    }
                    
                    // Save Button
                    Button(action: saveJournalEntry) {
                        Text("Save Entry")
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.blue)
                            .cornerRadius(10)
                    }
                    .disabled(selectedStock == nil || profit.isEmpty)
                }
                .padding()
                .background(Color(.systemBackground))
                .cornerRadius(15)
                .shadow(radius: 2)
                
                // Journal Entries List
                VStack(alignment: .leading, spacing: 10) {
                    Text("Recent Entries")
                        .font(.headline)
                        .padding(.horizontal)
                    
                    if journalEntries.isEmpty {
                        Text("No journal entries yet")
                            .foregroundColor(.secondary)
                            .frame(maxWidth: .infinity, alignment: .center)
                            .padding()
                    } else {
                        ScrollView {
                            LazyVStack(spacing: 8) {
                                ForEach(journalEntries) { entry in
                                    JournalEntryRow(entry: entry)
                                }
                            }
                            .padding(.horizontal)
                        }
                    }
                }
                
                Spacer()
            }
            .padding()
            .onAppear {
                loadStocks()
            }
            .alert("Journal Entry", isPresented: $showingAlert) {
                Button("OK") { }
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
              let profitValue = Float(profit) else {
            alertMessage = "Please fill in all fields correctly"
            showingAlert = true
            return
        }
        
        let newEntry = StockJournal(context: viewContext)
        newEntry.id = UUID()
        newEntry.stockName = selectedStock.name
        newEntry.instrumentID = selectedStock.instrument_id
        newEntry.profit = profitValue
        newEntry.date = selectedDate
        newEntry.timestamp = Date()
        
        do {
            try viewContext.save()
            
            // Reset form and dropdown states
            self.selectedStock = nil
            self.profit = ""
            self.selectedDate = Date()
            self.showingDropdown = false
            self.searchText = ""
            
            alertMessage = "Journal entry saved successfully!"
            showingAlert = true
        } catch {
            alertMessage = "Error saving entry: \(error.localizedDescription)"
            showingAlert = true
        }
    }
}

struct JournalEntryRow: View {
    let entry: StockJournal
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(entry.stockName ?? "Unknown Stock")
                    .font(.headline)
                Spacer()
                Text(entry.profit >= 0 ? "+$\(entry.profit, specifier: "%.2f")" : "-$\(abs(entry.profit), specifier: "%.2f")")
                    .font(.headline)
                    .foregroundColor(entry.profit >= 0 ? .green : .red)
            }
            
            HStack {
                Spacer()
                if let date = entry.date {
                    Text(date, style: .date)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(8)
    }
}

#Preview {
    StockJounalView()
        .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
}
