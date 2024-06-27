//
//  ShorterProfile.swift
//  Shorter
//
//  Created by Brian Masse on 6/21/24.
//

import Foundation
import RealmSwift
import SwiftUI

final class ShorterProfile: Object, Identifiable {
    
    @Persisted( primaryKey: true ) var _id: ObjectId
    
    @Persisted var ownerId: String = ""
    @Persisted var dateJoined: Date = .now
    
    @Persisted var firstName: String = ""
    @Persisted var lastName: String = ""
    
    @Persisted var phoneNumber: Int = 0
    @Persisted var email: String = ""
    
    @Persisted var imageData: Data = Data()
    
    @Persisted var friendIds: RealmSwift.List<String> = List()
    
    @Persisted var mostRecentPost: ObjectId? = nil
    
    convenience init( ownerId: String, email: String ) {
        self.init()
        
        self.ownerId = ownerId
        self.email = email
        self.dateJoined = .now
    }
    
    var profileImage: Image? = nil
}

