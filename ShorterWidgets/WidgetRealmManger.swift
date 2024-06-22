//
//  WidgetRealmManger.swift
//  ShorterWidgetsExtension
//
//  Created by Brian Masse on 6/22/24.
//

import Foundation
import Realm
import RealmSwift

class WidgetRealmManger {
    
    var realmLoaded: Bool = false
    var ownerId: String = ""
    
    static let shared: WidgetRealmManger = WidgetRealmManger()
    
//    MARK: init
    init() {
        if self.realmLoaded { return }
        
        print( "the WidgetRealmManager is being initialized" )
        
        let defaults = UserDefaults(suiteName: WidgetKeys.suiteName)!

        self.ownerId = defaults.string(forKey: WidgetKeys.ownerIdKey)!
    }
    
    private func loadRealm() async {
        if let user = await self.signIn() {
        
            let configuration = user.flexibleSyncConfiguration()
            let realm = try! await Realm(configuration: configuration)
            
            RealmManager.shared.realm = realm
            
            self.realmLoaded = true
        }
    }
    
    private func signIn() async -> RLMUser? {
        let credentials = Credentials.anonymous
        return try? await RealmManager.shared.app.login(credentials: credentials)
    }
    
//    MARK: RetrieveImageData
//    called when a widget is checking if another user might have posted
    @MainActor
    func retrieveImageData( from profileId: String ) async -> ShorterPost? {
        if !realmLoaded { await self.loadRealm() }
        
//        add a subscription to access the profile
        let _ = await RealmManager.shared.addGenericSubcriptions(name: "profile") { (query: Query<ShorterProfile>) in
            query.ownerId == profileId
        }
        
//        attempt to find the profile
        if let profile: ShorterProfile = RealmManager.retrieveObject().first {
            
            if let mostRecentPost = profile.mostRecentPost {
            
//                add a subscription to access the profiles most recent post
                let _ = await RealmManager.shared.addGenericSubcriptions(name: "post") { (query: Query<ShorterPost>) in
                    query._id == mostRecentPost
                }
                
//                attempt to find the profile
                if let post: ShorterPost = RealmManager.retrieveObject().first {
                    return post
                }
            }
        }
        
        return nil
    }
}
