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
                      data: Data ) {
        self.init()
        
        self.ownerId = ownerId
        self.ownerName = authorName
        
        self.fullTitle = fullTitle
        self.title = title
        self.emoji = emoji
        self.notes = notes
        
        self.imageData = data
        self.sharedOwnerIds = ShorterModel.shared.profile?.friendIds ?? List()
        
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
    
    private func getExpectedDate() async -> Date {
        if ShorterModel.realmManager.authenticationState == .complete {
            return await TimingManager.getFiringTime(for: self.postedDate)
        }
        return .now
    }
    
//    MARK: Class Functions
    private func loadImage() -> Image? {
        self.image = PhotoManager.decodeImage(from: self.imageData)
        return self.image
    }
    
    func getImage() -> Image {
        if self.image == nil {
            if let image = self.loadImage() {
                return image
            }
        }
        
        return self.image ?? Image("BigSur")
    }
}

