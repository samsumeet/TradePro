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
    @StateObject private var authManager = AuthenticationManager()
    @State private var showLaunchScreen = true

    var body: some Scene {
        WindowGroup {
            if showLaunchScreen {
                LaunchScreenView()
                    .onAppear {
                        // Hide launch screen after 3 seconds
                        DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
                            withAnimation(.easeInOut(duration: 0.5)) {
                                showLaunchScreen = false
                            }
                        }
                    }
            } else {
                MainTabView()
                    .environment(\.managedObjectContext, persistenceController.container.viewContext)
                    .environmentObject(authManager)
            }
        }
    }
}
