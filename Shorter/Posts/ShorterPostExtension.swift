//
//  ShorterPostExtension.swift
//  Shorter
//
//  Created by Brian Masse on 6/22/24.
//

import Foundation
import RealmSwift
import SwiftUI

extension ShorterPost {
    
    @MainActor
    convenience init( ownerId: String = "",
                      authorName: String = "",
                      fullTitle: String,
                      title: String,
                      emoji: String,
                      notes: String,
                      shareList: [String] = [],
                      data: Data ) {
        self.init()
        
        self.ownerId = ownerId
        self.ownerName = authorName
        
        self.fullTitle = fullTitle
        self.title = title
        self.emoji = emoji
        self.notes = notes
        
        self.imageData = data
        
        let sharedOwnerIds = RealmSwift.List<String>()
        for id in shareList { sharedOwnerIds.append(id) }
        
        self.sharedOwnerIds = sharedOwnerIds
        
        self.postedDate = .now
        
        if ShorterModel.realmManager.authenticationState != .complete { return }
        
        Task {
            let expectedDate = await self.getExpectedDate()
            RealmManager.updateObject(self) { thawed in
                thawed.expectedDate = expectedDate
            }
        }
        
        ShorterModel.shared.profile?.updateRecentPost(to: self._id)
    }
    
//    MARK: Convenience Functions
    static func getPost(from id: ObjectId? ) -> ShorterPost? {
        if id == nil { return nil }
        return RealmManager.retrieveObject { query in
            query._id == id!
        }.first
    }
    
    @MainActor
    private func getExpectedDate() async -> Date {
        if ShorterModel.realmManager.authenticationState == .complete {
            return TimingManager.getFiringTime(for: self.postedDate)
        }
        return .now
    }
    
//    MARK: Class Functions
    private func loadImage() -> Image? {
        
        let uiImage = PhotoManager.decodeUIImage(from: self.imageData)
        
        if self.imageData.count < 600000 {
            if let uiImage = uiImage {
                self.image = Image(uiImage: uiImage)
                return self.image
            }
        }

        let data = PhotoManager.encodeImage(uiImage)
        self.image = PhotoManager.decodeImage(from: data)
        
        return image
    }
    
    func getImage() -> Image {
        if self.image == nil {
            if let image = self.loadImage() {
                return image
            }
        }
        
        return self.image ?? Image("BigSur")
    }
    
//    when a user deletes the most recent post on a profile this function ensures that
//    the second most recent post is stored, to be properly displayed on receiving widgets
    @MainActor
    private func updateProfileMostRecentPost() async {
        let posts: [ShorterPost] = RealmManager.retrieveObjects { query in
            query.postedDate < self.postedDate
        }.sorted { post1, post2 in
            post1.postedDate > post2.postedDate
        }
        
        ShorterModel.shared.profile?.updateRecentPost(to: posts.first?._id ?? nil)
    }
    
    @MainActor
    private func removeFromRealm() {
        RealmManager.deleteObject(self) { post in
            post._id == self._id
        }
    }
    
    @MainActor
    func delete() async {
        let profile = ShorterModel.shared.profile!
        if profile.mostRecentPost == self._id {
            await self.updateProfileMostRecentPost()
        }
        
        self.removeFromRealm()
    }
}

