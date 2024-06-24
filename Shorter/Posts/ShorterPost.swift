//
//  ShorterPost.swift
//  Shorter
//
//  Created by Brian Masse on 6/21/24.
//

import Foundation
import SwiftUI
import RealmSwift

final class ShorterPost: Object, Identifiable {
    
    @Persisted( primaryKey: true ) var _id: ObjectId
    
    @Persisted var ownerId: String = ""
    @Persisted var sharedOwnerIds: RealmSwift.List<String> = List()
    @Persisted var ownerName: String        = ""
    
    @Persisted var expectedDate: Date = .now
    @Persisted var postedDate: Date =   .now
    
    @Persisted var fullTitle: String    = ""
    @Persisted var title: String        = ""
    @Persisted var emoji: String        = "🫥"
    @Persisted var notes: String        = ""
    
    @Persisted var imageData: Data = Data()
    internal var image: Image? = nil
}
