//
//  EmojiManager.swift
//  Shorter
//
//  Created by Brian Masse on 6/26/24.
//

import Foundation

final class Emoji: Identifiable {
    let keys: [Int]
    let isSkinToneSupport: Bool
    let searchKey: String
    let version: Double
    
    var usage: Int = 0
    var lastUsage: Date = .distantPast
    
    init( emojiKeys: [Int], isSkinToneSupport: Bool, searchKey: String, version: Double ) {
        self.keys = emojiKeys
        self.isSkinToneSupport = isSkinToneSupport
        self.searchKey = searchKey
        self.version = version
    }
}

final class EmojiCategory: Identifiable {
    
    enum EmojiCateogryType: String, Identifiable {
        var icon: String {
            switch self {
            case .frequentlyUsed:   return "clock"
            case .people:           return "person.2"
            case .nature:           return "tortoise"
            case .foodAndDrink:     return "carrot"
            case .activity:         return "figure.run"
            case .travelAndPlaces:  return "car.rear"
            case .objects:          return "lightbulb"
            case .symbols:          return "dot.viewfinder"
            case .flags:            return "flag.checkered"
            }
        }
        
        var title: String {
            switch self {
            case .frequentlyUsed:   return "frequent"
            case .people:           return "people"
            case .nature:           return "nature"
            case .foodAndDrink:     return "Food and Drink"
            case .activity:         return "activity and Fitness"
            case .travelAndPlaces:  return "Travel and places"
            case .objects:          return "objects"
            case .symbols:          return "symbols"
            case .flags:            return "flags"
            }
        }
        
        case frequentlyUsed
        case people
        case nature
        case foodAndDrink
        case activity
        case travelAndPlaces
        case objects
        case symbols
        case flags
        
        var id: String { self.rawValue }
    }
    
    let type: EmojiCateogryType
    let name: String
    var emojis: [ Emoji ]
    
    init( type: EmojiCateogryType, categoryName: String, emojis: [Emoji] ) {
        self.type = type
        self.name = categoryName
        self.emojis = emojis
    }
}
