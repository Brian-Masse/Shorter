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
    static var description = IntentDescription( "Selects the friend you want to see daily photos from" )
    
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
    static func retreiveFriends() async -> [FriendDetail] {
        var details: [FriendDetail] = []
        
        if let defaults = UserDefaults(suiteName: WidgetKeys.suiteName) {
            let count = max( 0, defaults.integer(forKey: WidgetKeys.totalFriendsKey) )
            
            for i in 0..<count {
                let ownerId = defaults.string(forKey: WidgetKeys.friendOwnerIdBaseKey + "\(i)") ?? ""
                let firstName = defaults.string(forKey: WidgetKeys.friendFirstNameBaseKey + "\(i)") ?? ""
                let lastName = defaults.string(forKey: WidgetKeys.friendLastNameBaseKey + "\(i)") ?? ""
                            
                if !ownerId.isEmpty {
                    details.append( FriendDetail(id: ownerId,
                                                 firstName: firstName,
                                                 lastName: lastName) )
                }
            }
        }
        
        return details
    }
}

//MARK: FriendQuery
struct FriendQuery: EntityQuery {
    
    func entities(for identifiers: [FriendDetail.ID]) async throws -> [FriendDetail] {
        let friends = await FriendDetail.retreiveFriends()
        return friends.filter { identifiers.contains($0.id) }
    }
    
    func suggestedEntities() async throws -> [FriendDetail] {
        await FriendDetail.retreiveFriends()
    }
    
    func defaultResult() async -> FriendDetail? {
        try? await suggestedEntities().first
    }
    
    
}
