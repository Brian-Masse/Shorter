//
//  ShorterPostExtension.swift
//  Shorter
//
//  Created by Brian Masse on 6/22/24.
//

import Foundation
import RealmSwift

extension ShorterPost {
    convenience init( ownerId: String = "", title: String, data: Data ) {
        self.init()
        
        self.ownerId = ownerId
        self.title = title
        self.imageData = data
        self.sharedOwnerIds = ShorterModel.shared.profile?.friendIds ?? List()
        
        ShorterModel.shared.profile?.updateRecentPost(to: self._id)
    }
    
    static func getPost(from id: ObjectId? ) -> ShorterPost? {
        if id == nil { return nil }
        return RealmManager.retrieveObject { query in
            query._id == id!
        }.first
    }
}
