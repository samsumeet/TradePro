//
//  StockAnalysisService.swift
//  TradePro
//
//  Created by Sumeet Bachchas on 06.10.25.
//

import Foundation

enum APIError: Error, LocalizedError {
    case invalidURL
    case networkError(Error)
    case decodingError(Error)
    case noData
    case serverError(Int)
    
    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid URL"
        case .networkError(let error):
            return "Network error: \(error.localizedDescription)"
        case .decodingError(let error):
            return "Failed to decode data: \(error.localizedDescription)"
        case .noData:
            return "No data received from server"
        case .serverError(let code):
            return "Server error with code: \(code)"
        }
    }
}

class StockAnalysisService: ObservableObject {
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var stockDataList: [StockData] = []
    
    private let baseURL = "https://us-central1-tradepro-81292.cloudfunctions.net/api"
    
    // Fetch all stock analysis
    func fetchStockAnalysis() async throws -> StockAnalysisResponse {
        isLoading = true
        errorMessage = nil
        
        defer { isLoading = false }
        
        guard let url = URL(string: "\(baseURL)/stock-analysis") else {
            throw APIError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                throw APIError.noData
            }
            
            guard (200...299).contains(httpResponse.statusCode) else {
                throw APIError.serverError(httpResponse.statusCode)
            }
            
            let decoder = JSONDecoder()
            let stockResponse = try decoder.decode(StockAnalysisResponse.self, from: data)
            
            await MainActor.run {
                self.stockDataList = stockResponse.data
            }
            
            return stockResponse
            
        } catch let error as DecodingError {
            throw APIError.decodingError(error)
        } catch {
            throw APIError.networkError(error)
        }
    }
    
    // Fetch specific stock by symbol
    func fetchStock(symbol: String) async throws -> StockData? {
        let response = try await fetchStockAnalysis()
        return response.data.first { $0.stockSymbol == symbol }
    }
    
    // Fetch with completion handler (for backward compatibility)
    func fetchStockAnalysis(completion: @escaping (Result<StockAnalysisResponse, APIError>) -> Void) {
        Task {
            do {
                let response = try await fetchStockAnalysis()
                completion(.success(response))
            } catch let error as APIError {
                completion(.failure(error))
            } catch {
                completion(.failure(.networkError(error)))
            }
        }
    }
}
