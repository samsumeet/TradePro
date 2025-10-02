//
//  WatchlistScraper.swift
//  TradePro
//
//  Created by Sumeet Bachchas on 02.10.25.
//

import Foundation
import SwiftSoup

class WatchlistScraper {
    private let url = URL(string: "https://www.ls-tc.de/en/watchlist")!
    
    // Your cookie string
    private let cookieHeader = "disclaimer=2015040809; baukasten=n5im0cad0p5rvm4j6ptg3ob86g; watchlist=A3C8TH%2CA0JDRR%2CA1CX3T%2CA2QHR0%2CA0LC2W%2C918422"
    
    func fetchWatchlist(completion: @escaping ([WatchlistItem]?, Error?) -> Void) {
        var request = URLRequest(url: url)
        request.setValue(cookieHeader, forHTTPHeaderField: "Cookie")
        request.setValue("Mozilla/5.0 (iOS) Safari", forHTTPHeaderField: "User-Agent")
        
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                completion(nil, error)
                return
            }
            
            guard let data = data, let html = String(data: data, encoding: .utf8) else {
                completion(nil, NSError(domain: "Scraper", code: 0, userInfo: [NSLocalizedDescriptionKey: "No HTML"]))
                return
            }
            
            do {
                let doc: Document = try SwiftSoup.parse(html)
                
                // The table rows inside the watchlist table
                let rows = try doc.select("tbody").select("tr")
                var items: [WatchlistItem] = []
                
                for row in rows { // skip header row
                    
                    let cols = try row.select("td")
                    if cols.size() >= 7 {
                        print(cols)
                        let item = WatchlistItem(
                            wkn: try cols.get(0).text(),
                            name: try cols.get(1).text(),
                            bid: try cols.get(2).text(),
                            ask: try cols.get(3).text(),
                            diff: try cols.get(4).text(),
                            diffPercent: try cols.get(5).text(),
                            time: try cols.get(6).text()
                        )
                        items.append(item)
                    }
                }
                
                completion(items, nil)
            } catch {
                completion(nil, error)
            }
        }
        task.resume()
    }
}
