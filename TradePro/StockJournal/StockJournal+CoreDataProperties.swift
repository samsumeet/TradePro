//
//  StockJournal+CoreDataProperties.swift
//  TradePro
//
//  Created by Sumeet Bachchas on 03.10.25.
//
//

import Foundation
import CoreData


extension StockJournal {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<StockJournal> {
        return NSFetchRequest<StockJournal>(entityName: "StockJournal")
    }

    @NSManaged public var date: Date?
    @NSManaged public var instrumentID: String?
    @NSManaged public var profit: Float
    @NSManaged public var stockName: String?
    @NSManaged public var timestamp: Date?
    @NSManaged public var id: UUID?
    @NSManaged public var tradeType: String? 

}

extension StockJournal : Identifiable {

}
