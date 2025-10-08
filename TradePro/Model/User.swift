//
//  User.swift
//  TradePro
//
//  Created by Sumeet Bachchas on 05.10.25.
//

import Foundation

struct User: Identifiable, Codable {
    let id: UUID
    var fullName: String
    var email: String
    var joinDate: Date
    var isPremium: Bool
    var photoURL: String?
    
    var initials: String {
        let components = fullName.components(separatedBy: " ")
        let initials = components.map { String($0.prefix(1)) }.joined()
        return initials.uppercased()
    }
    
    init(id: UUID = UUID(), fullName: String, email: String, joinDate: Date = Date(), isPremium: Bool = false, photoURL: String? = nil) {
        self.id = id
        self.fullName = fullName
        self.email = email
        self.joinDate = joinDate
        self.isPremium = isPremium
        self.photoURL = photoURL
    }
}
