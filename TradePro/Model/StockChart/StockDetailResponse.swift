//
//  ChartResponse.swift
//  TradePro
//
//  Created by Sumeet Bachchas on 02.10.25.
//

import Foundation

struct ChartResponse: Codable {
    let info: ChartInfo
    let container: String?
    let series: Series
}

struct ChartInfo: Codable {
    let isin: String
    let chartType: String
    let textMaxValue: String
    let textMinValue: String
    let plotlines: [Plotline]
    let maxRange: Int?
}

struct Plotline: Codable {
    let label: String
    let value: Double
    let align: String
    let y: Int
    let id: String
    let color: String
}

struct Series: Codable {
    let intraday: ChartSeries?
    let history: ChartSeries?
}

struct ChartSeries: Codable {
    let id: String
    let data: [[Double]]
    let timeline: String
    let name: String
    let color: String
    let dataGrouping: DataGrouping?
}

struct DataGrouping: Codable {
    let enabled: Bool
    let forced: Bool?
    let approximation: String?
}
