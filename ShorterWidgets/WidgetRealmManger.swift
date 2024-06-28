//
//  WidgetRealmManger.swift
//  ShorterWidgetsExtension
//
//  Created by Brian Masse on 6/22/24.
//

import Foundation
import Realm
import RealmSwift

//vqMmuXuQh7xGX0bMLrn3LVU2AFpx7IDLRsejbkL1NIric9oXO4WbaiaWXHObJoNx

class WidgetRealmManger {
    
    var app: App? = nil
    var realm: Realm? = nil
    var user: User? = nil
    
//    MARK: LoadRealm
    @MainActor
    private func loadRealm() async {
        if let user = self.user {
        
            let configuration = user.flexibleSyncConfiguration()
            
            let realm = try! await Realm(configuration: configuration,
                                         downloadBeforeOpen: .never )

            self.realm = realm
        }
    }
    
    private func signIn() async {
        self.app = RealmSwift.App(id: "application-0-ecwqhth")
        let credentials = Credentials.userAPIKey("vqMmuXuQh7xGX0bMLrn3LVU2AFpx7IDLRsejbkL1NIric9oXO4WbaiaWXHObJoNx")
        let user = try! await app!.login(credentials: credentials)
        self.user = user
    }
    
//    MARK: RetrieveImageData
//    called when a widget is checking if another user might have posted
    @MainActor
    func retrieveImageData( from profileId: String ) async -> ShorterPost? {
        print("attempting to retreive image data")
//        
        await self.signIn()
        await self.loadRealm()
//        await removeSubscriptions()
//        
//        await addProfileSubscription(profileId)
//
//        if let profile: ShorterProfile = self.realm!.objects(ShorterProfile.self).first {
//            
//            if let mostRecentPost = profile.mostRecentPost {
//
//                await addPostSubscription(mostRecentPost)
//                
////                attempt to find the profile
//                if let post: ShorterPost = self.realm!.objects(ShorterPost.self).first {
//                    
//                    let newPost = ShorterPost()
//                    newPost.title = post.title
//                    newPost.emoji = post.emoji
//                    newPost.imageData = post.imageData
//                    newPost.postedDate = post.postedDate
//                    
//                    await clean()
//                    
//                    return newPost
//                }
//            }
//        }
        
        await clean()
        return nil
    }
    
//    MARK: Subscriptions
    private func addProfileSubscription(_ profileId: String) async {
        let subs = self.realm!.subscriptions
        
        try? await subs.update {
            let query: QuerySubscription<ShorterProfile> = QuerySubscription(name: "profile") { query in
                query.ownerId == profileId
            }
            subs.append(query)
        }
    }
    
    private func addPostSubscription(_ id: ObjectId) async {
        let subs = self.realm!.subscriptions
        
        try? await subs.update {
            let query: QuerySubscription<ShorterPost> = QuerySubscription(name: "posts") { query in
                query._id == id
            }
            subs.append(query)
        }
    }
    
    private func removeSubscriptions() async {
        let subs =  self.realm!.subscriptions
        
        try! await subs.update { subs.removeAll() }
    }
    
    //MARK: Clean
    
    @MainActor
    private func clean() async {
        
//        await removeSubscriptions()
        
        try! await self.user?.remove()
        try! await self.app!.currentUser?.remove()
        
        self.realm!.invalidate()
        
        self.realm = nil
        self.user = nil
        self.app = nil
    
        cleanupRealm()
    }
}

func cleanupRealm() {
    // This block ensures that all remaining references are cleaned up
    DispatchQueue.global(qos: .background).async {
        // Since we are in a background queue, we can safely perform cleanup
        autoreleasepool {
            // Ensure that the default Realm is not being held by any reference
            _ = try? Realm()
        }

        // Explicitly call for garbage collection to ensure memory is released
        DispatchQueue.main.async {
            // Optional: Trigger garbage collection
            for _ in 0..<10 {
                autoreleasepool {
                    let _ = try? Realm()
                }
            }
        }
    }
}
