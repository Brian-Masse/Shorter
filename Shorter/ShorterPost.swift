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
    
    @Persisted var title: String
    
    @Persisted var imageData: Data = Data()
 
    convenience init( ownerId: String = "", title: String, data: Data ) {
        self.init()
        
        self.ownerId = ownerId
        self.title = title
        self.imageData = data
        
    }
}
