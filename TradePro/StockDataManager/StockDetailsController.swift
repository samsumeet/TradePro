//
//  StockDetailsController.swift
//  TradePro
//
//  Created by Sumeet Bachchas on 02.10.25.
//

import Foundation

enum ChartTimePeriod: String, CaseIterable {
    case intraday = "intraday"
    case oneMonth = "1M"
    case sixMonths = "6M"
    
    var displayName: String {
        switch self {
        case .intraday: return "Intraday"
        case .oneMonth: return "1 Month"
        case .sixMonths: return "6 Months"
        }
    }
}

class StockDetailsController: ObservableObject {
    @Published var chartResponse: ChartResponse?
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    func fetchChartData(instrumentId: String, completion: @escaping (ChartResponse?) -> Void) {
        let urlStr = "https://www.ls-tc.de/_rpc/json/instrument/chart/dataForInstrument?instrumentId=\(instrumentId)"
        guard let url = URL(string: urlStr) else {
            completion(nil)
            return
        }

        isLoading = true
        errorMessage = nil
        
        let task = URLSession.shared.dataTask(with: url) { [weak self] data, response, error in
            DispatchQueue.main.async {
                self?.isLoading = false
                
                guard let data = data, error == nil else {
                    self?.errorMessage = error?.localizedDescription ?? "Network error"
                    completion(nil)
                    return
                }

                
                do {
                    let result = try JSONDecoder().decode(ChartResponse.self, from: data)
                    //print(result)
                    self?.chartResponse = result
                    completion(result)
                } catch {
                    print("Decoding error: \(error)")
                    self?.errorMessage = "Failed to parse data"
                    completion(nil)
                }
            }
        }
        task.resume()
    }
}

// Legacy function for backward compatibility
func fetchChartData(completion: @escaping (ChartResponse?) -> Void) {
    let controller = StockDetailsController()
    controller.fetchChartData(instrumentId: "2989463", completion: completion)
}
