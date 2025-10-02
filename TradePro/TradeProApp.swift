//
//  TradeProApp.swift
//  TradePro
//
//  Created by Sumeet Bachchas on 02.10.25.
//

import SwiftUI

@main
struct TradeProApp: App {
    let persistenceController = PersistenceController.shared

    var body: some Scene {
        WindowGroup {
            ContentView() 
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
        }
    }
}
