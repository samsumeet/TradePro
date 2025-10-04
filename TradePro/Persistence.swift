//
//  Persistence.swift
//  TradePro
//
//  Created by Sumeet Bachchas on 02.10.25.
//

import CoreData

struct PersistenceController {
    static let shared = PersistenceController()
       
       let container: NSPersistentContainer
       
       init(inMemory: Bool = false) {
           container = NSPersistentContainer(name: "TradePro") // Match your .xcdatamodeld name
           
           if inMemory {
               container.persistentStoreDescriptions.first?.url = URL(fileURLWithPath: "/dev/null")
           }
           
           container.loadPersistentStores { description, error in
               if let error = error {
                   fatalError("Core Data failed to load: \(error.localizedDescription)")
               }
           }
           
           container.viewContext.automaticallyMergesChangesFromParent = true
       }
       
       // For SwiftUI Previews
       static var preview: PersistenceController = {
           let controller = PersistenceController(inMemory: true)
           let viewContext = controller.container.viewContext
           
           // Add sample data for preview
           for i in 0..<5 {
               let stock = StockJournal(context: viewContext)
               stock.stockName = "Sample Stock \(i)"
               stock.profit = 50.0
               stock.date =  Date()
               stock.instrumentID = "123456"
           }
           
           try? viewContext.save()
           return controller
       }()
   }

