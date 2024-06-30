//
//  SelectFriendIntent.swift
//  Shorter
//
//  Created by Brian Masse on 6/22/24.
//

import Foundation
import WidgetKit
import AppIntents
import RealmSwift

//MARK: SelectedFriendIntent
struct SelectFriendIntent: WidgetConfigurationIntent {
    
    static var title: LocalizedStringResource = "Select a Friend"
    static var description = IntentDescription( "Select the friend's posts you want to display" )
    
    @Parameter(title: "Friend" )
    var friend: FriendDetail
    
    init( friend: FriendDetail ) {
        self.friend = friend
    }
    
    init() { }
}

//MARK: FriendDetail
struct FriendDetail: AppEntity {
    
    let id: String
    let ownerId: String
    let firstName: String
    let lastName: String
    
    static var typeDisplayRepresentation: TypeDisplayRepresentation = "Friend"
    static var defaultQuery = FriendQuery()
    
    var displayRepresentation: DisplayRepresentation {
        DisplayRepresentation( title: "\(firstName) \(lastName)" )
    }
    
//    This looks into the shared userDefaults and attempts to find a list of the users friends
//    if it does, it maps the fetched data into the FriendDetail
    @MainActor
    static func retreiveFriends(_ currentId: String = "\(0)") -> [FriendDetail] {
        var details: [FriendDetail] = []
        
        if let defaults = UserDefaults(suiteName: WidgetKeys.suiteName) {
            let count = max( 0, defaults.integer(forKey: WidgetKeys.totalFriendsKey) )
            
            for i in 0..<count {
                let ownerId = defaults.string(forKey: WidgetKeys.friendOwnerIdBaseKey + "\(i)") ?? ""
                let firstName = defaults.string(forKey: WidgetKeys.friendFirstNameBaseKey + "\(i)") ?? ""
                let lastName = defaults.string(forKey: WidgetKeys.friendLastNameBaseKey + "\(i)") ?? ""
                            
                if !ownerId.isEmpty {
                    details.append( FriendDetail(id: "\(i)",
                                                 ownerId: ownerId,
                                                 firstName: firstName,
                                                 lastName: lastName) )
                }
            }
            
            if count == 0 {
                details.append( FriendDetail(id: currentId,
                                             ownerId: WidgetKeys.signInKey,
                                             firstName: "-",
                                             lastName: "") )
            }
        }
        
        return details
    }
}

//MARK: FriendQuery
struct FriendQuery: EntityQuery {
    
    func entities(for identifiers: [FriendDetail.ID]) async throws -> [FriendDetail] {
        let friends = await FriendDetail.retreiveFriends(identifiers.first ?? "")
        
        return friends
    }
    
    func suggestedEntities() async throws -> [FriendDetail] {
        await FriendDetail.retreiveFriends()
    }
    
    func defaultResult() async -> FriendDetail? {
        let result = try? await suggestedEntities().first
        return result
    }
    
    
}
