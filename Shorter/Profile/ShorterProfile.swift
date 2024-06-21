//
//  ShorterProfile.swift
//  Shorter
//
//  Created by Brian Masse on 6/21/24.
//

import Foundation
import RealmSwift

final class ShorterProfile: Object, Identifiable {
    
    @Persisted( primaryKey: true ) var _id: ObjectId
    
    @Persisted var ownerId: String = ""
    
    @Persisted var firstName: String = ""
    @Persisted var lastName: String = ""
    
    @Persisted var phoneNumber: Int = 0
    @Persisted var email: String = ""
    
    @Persisted var imageData: Data = Data()
    
    @Persisted var friendIds: RealmSwift.List<String> = List()
    
    convenience init( ownerId: String, email: String ) {
        self.init()
        
        self.ownerId = ownerId
        self.email = email
    }
    
    func fillProfile( firstName: String, lastName: String, phoneNumber: Int, friendIds: [String], imageData: Data ) {
        RealmManager.updateObject(self) { thawed in
            thawed.firstName = firstName
            thawed.lastName = lastName
            thawed.phoneNumber = phoneNumber
            thawed.imageData = imageData
            
            var friendList: RealmSwift.List<String> = List()
            
            for friendId in friendIds {
                friendList.append(friendId)
            }
            
            thawed.friendIds = friendList
            
            
        }
    }
    
    var isComplete: Bool {
        !self.firstName.isEmpty &&
        !self.lastName.isEmpty &&
        "\(phoneNumber)".count >= 11
    }
    
//    MARK: Convenience Functions
//    This compounds all the string properties into one searchale string
    var searchableField: String {
        "\(firstName).\(lastName)"
    }
    
    static func getProfile(for id: String) -> ShorterProfile? {
        let profile: ShorterProfile? =  RealmManager.retrieveObject { query in
            query.ownerId == id
        }.first
        
        return profile
    }
}
