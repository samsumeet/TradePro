//
//  StockAnalysisModels.swift
//  TradePro
//

import Foundation

// MARK: - API Response
struct StockAnalysisResponse: Codable {
    let count: Int
    let data: [StockData]
    let nextCursor: String?
    
    enum CodingKeys: String, CodingKey {
        case count
        case data
        case nextCursor = "next_cursor"
    }
}

// MARK: - Stock Data
struct StockData: Codable, Identifiable {
    let id: String
    let stockSymbol: String
    let companyName: String
    let dataRetrieved: String
    let currentStockInfo: CurrentStockInfo
    let analystRatings: AnalystRatings
    let newsArticles: [NewsArticle]
    let financialPerformance: FinancialPerformance
    let insiderActivity: [InsiderActivity]
    let strategicInitiatives: StrategicInitiatives
    let risks: [String]
    let marketContext: MarketContext
    let analystActions: [AnalystAction]?
    let storedAt: StoredAt?
    
    enum CodingKeys: String, CodingKey {
        case id
        case stockSymbol = "stock_symbol"
        case companyName = "company_name"
        case dataRetrieved = "data_retrieved"
        case currentStockInfo = "current_stock_info"
        case analystRatings = "analyst_ratings"
        case newsArticles = "news_articles"
        case financialPerformance = "financial_performance"
        case insiderActivity = "insider_activity"
        case strategicInitiatives = "strategic_initiatives"
        case risks
        case marketContext = "market_context"
        case analystActions = "analyst_actions"
        case storedAt = "stored_at"
    }
}

// MARK: - Current Stock Info
struct CurrentStockInfo: Codable {
    let currentPrice: Double
    let currency: String
    let lastUpdated: String
    let changePercent: Double
    let weekRange52: WeekRange
    let yearToDateChange: String
    let oneYearChange: String
    let marketCapBillions: Double
    let beta: Double
    let averageVolume: Int
    
    enum CodingKeys: String, CodingKey {
        case currentPrice = "current_price"
        case currency
        case lastUpdated = "last_updated"
        case changePercent = "change_percent"
        case weekRange52 = "52_week_range"
        case yearToDateChange = "year_to_date_change"
        case oneYearChange = "one_year_change"
        case marketCapBillions = "market_cap_billions"
        case beta
        case averageVolume = "average_volume"
    }
}

struct WeekRange: Codable {
    let low: Double
    let high: Double
}

// MARK: - Analyst Ratings
struct AnalystRatings: Codable {
    let consensus: String
    let targetPrice: Double
    let median12MonthTarget: Double
    let potentialUpsideDownside: String
    
    enum CodingKeys: String, CodingKey {
        case consensus
        case targetPrice = "target_price"
        case median12MonthTarget = "median_12_month_target"
        case potentialUpsideDownside = "potential_upside_downside"
    }
}

// MARK: - News Article (ALL OPTIONAL except required fields)
struct NewsArticle: Codable, Identifiable {
    var id: String { "\(date)_\(headline)" }
    
    let date: String
    let time: String?
    let headline: String
    let summary: String
    let sentiment: String
    let source: String
    let url: String?
    let keyData: [String: FlexibleValue]?
    let keyMetrics: [String: FlexibleValue]?
    let priceMovement: [String: FlexibleValue]?
    let keyDrivers: [String]?
    let closingPrice: Double?
    let product: String?
    let location: String?
    let comparison: String?
    let eventDetails: [String: FlexibleValue]?
    let analystRating: String?
    let potentialUpsidePercent: Double?
    let keyProducts: [String]?
    
    enum CodingKeys: String, CodingKey {
        case date, time, headline, summary, sentiment, source, url
        case keyData = "key_data"
        case keyMetrics = "key_metrics"
        case priceMovement = "price_movement"
        case keyDrivers = "key_drivers"
        case closingPrice = "closing_price"
        case product, location, comparison
        case eventDetails = "event_details"
        case analystRating = "analyst_rating"
        case potentialUpsidePercent = "potential_upside_percent"
        case keyProducts = "key_products"
    }
}

// MARK: - Flexible Value Type
enum FlexibleValue: Codable {
    case string(String)
    case int(Int)
    case double(Double)
    case bool(Bool)
    case array([FlexibleValue])
    case dictionary([String: FlexibleValue])
    
    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        
        if let string = try? container.decode(String.self) {
            self = .string(string)
        } else if let int = try? container.decode(Int.self) {
            self = .int(int)
        } else if let double = try? container.decode(Double.self) {
            self = .double(double)
        } else if let bool = try? container.decode(Bool.self) {
            self = .bool(bool)
        } else if let array = try? container.decode([FlexibleValue].self) {
            self = .array(array)
        } else if let dict = try? container.decode([String: FlexibleValue].self) {
            self = .dictionary(dict)
        } else {
            throw DecodingError.typeMismatch(
                FlexibleValue.self,
                DecodingError.Context(codingPath: decoder.codingPath, debugDescription: "Cannot decode FlexibleValue")
            )
        }
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        
        switch self {
        case .string(let value): try container.encode(value)
        case .int(let value): try container.encode(value)
        case .double(let value): try container.encode(value)
        case .bool(let value): try container.encode(value)
        case .array(let value): try container.encode(value)
        case .dictionary(let value): try container.encode(value)
        }
    }
    
    var stringValue: String? {
        if case .string(let value) = self { return value }
        return nil
    }
    
    var doubleValue: Double? {
        switch self {
        case .double(let value): return value
        case .int(let value): return Double(value)
        default: return nil
        }
    }
}

// MARK: - Financial Performance
struct FinancialPerformance: Codable {
    let q2_2025: FinancialData?
    let fy2025: FinancialData?
    let projections: FinancialData?
    let projections2028: FinancialData?
    
    enum CodingKeys: String, CodingKey {
        case q2_2025
        case fy2025
        case projections
        case projections2028 = "projections_2028"
    }
    
    // Custom decoder to handle flexible JSON
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        q2_2025 = try? container.decode(FinancialData.self, forKey: .q2_2025)
        fy2025 = try? container.decode(FinancialData.self, forKey: .fy2025)
        projections = try? container.decode(FinancialData.self, forKey: .projections)
        projections2028 = try? container.decode(FinancialData.self, forKey: .projections2028)
    }
}

struct FinancialData: Codable {
    let data: [String: FlexibleValue]
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: DynamicKey.self)
        var dict: [String: FlexibleValue] = [:]
        
        for key in container.allKeys {
            if let value = try? container.decode(FlexibleValue.self, forKey: key) {
                dict[key.stringValue] = value
            }
        }
        data = dict
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: DynamicKey.self)
        for (key, value) in data {
            if let dynamicKey = DynamicKey(stringValue: key) {
                try container.encode(value, forKey: dynamicKey)
            }
        }
    }
}

// MARK: - Insider Activity
struct InsiderActivity: Codable, Identifiable {
    var id: String { "\(date ?? "unknown")_\(person ?? "unknown")" }
    
    let date: String?
    let person: String?
    let title: String?
    let transactionType: String?
    let shares: Int?
    let pricePerShare: Double?
    let totalValue: Double?
    let ownershipChangePercent: Double?
    let activityType: String?
    let note: String?
    let insider: String?
    let action: String?
    let value: String?
    
    enum CodingKeys: String, CodingKey {
        case date, person, title, shares, value, insider, action, note
        case transactionType = "transaction_type"
        case pricePerShare = "price_per_share"
        case totalValue = "total_value"
        case ownershipChangePercent = "ownership_change_percent"
        case activityType = "activity_type"
    }
}

// MARK: - Strategic Initiatives
struct StrategicInitiatives: Codable {
    let data: [String: FlexibleValue]
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: DynamicKey.self)
        var dict: [String: FlexibleValue] = [:]
        
        for key in container.allKeys {
            if let value = try? container.decode(FlexibleValue.self, forKey: key) {
                dict[key.stringValue] = value
            }
        }
        data = dict
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: DynamicKey.self)
        for (key, value) in data {
            if let dynamicKey = DynamicKey(stringValue: key) {
                try container.encode(value, forKey: dynamicKey)
            }
        }
    }
}

// MARK: - Market Context
struct MarketContext: Codable {
    let data: [String: FlexibleValue]
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: DynamicKey.self)
        var dict: [String: FlexibleValue] = [:]
        
        for key in container.allKeys {
            if let value = try? container.decode(FlexibleValue.self, forKey: key) {
                dict[key.stringValue] = value
            }
        }
        data = dict
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: DynamicKey.self)
        for (key, value) in data {
            if let dynamicKey = DynamicKey(stringValue: key) {
                try container.encode(value, forKey: dynamicKey)
            }
        }
    }
}

// MARK: - Analyst Action
struct AnalystAction: Codable, Identifiable {
    var id: String { "\(firm ?? "unknown")_\(rating ?? "unknown")" }
    
    let firm: String?
    let rating: String?
    let target: Double?
    let rationale: String?
    let previousRating: String?
    let position: String?
    let concern: String?
    let impact: String?
    
    enum CodingKeys: String, CodingKey {
        case firm, rating, target, rationale, position, concern, impact
        case previousRating = "previous_rating"
    }
}

// MARK: - Stored At
struct StoredAt: Codable {
    let seconds: Int
    let nanoseconds: Int
    
    enum CodingKeys: String, CodingKey {
        case seconds = "_seconds"
        case nanoseconds = "_nanoseconds"
    }
}

// MARK: - Dynamic Key
struct DynamicKey: CodingKey {
    var stringValue: String
    var intValue: Int?
    
    init?(stringValue: String) {
        self.stringValue = stringValue
        self.intValue = nil
    }
    
    init?(intValue: Int) {
        self.stringValue = "\(intValue)"
        self.intValue = intValue
    }
}

// MARK: - Extensions
extension StockData {
    var isPriceIncreasing: Bool {
        currentStockInfo.changePercent > 0
    }
    
    var formattedMarketCap: String {
        "$\(String(format: "%.2f", currentStockInfo.marketCapBillions))B"
    }
    
    var formattedPrice: String {
        "$\(String(format: "%.2f", currentStockInfo.currentPrice))"
    }
}
