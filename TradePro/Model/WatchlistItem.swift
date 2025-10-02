//
//  WatchlistItem.swift
//  TradePro
//
//  Created by Sumeet Bachchas on 02.10.25.
//

import Foundation
struct WatchlistItem: Identifiable {
    let id = UUID()
    let wkn: String
    let name: String
    let bid: String
    let ask: String
    let diff: String
    let diffPercent: String
    let time: String
}
