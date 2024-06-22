//
//  ShorterProfileExtension.swift
//  Shorter
//
//  Created by Brian Masse on 6/22/24.
//

import Foundation
import SwiftUI
import RealmSwift

extension ShorterProfile {
    
//    MARK: Initialization
    func fillProfile( firstName: String, lastName: String, phoneNumber: Int, friendIds: [String], imageData: Data ) {
        RealmManager.updateObject(self) { thawed in
            thawed.firstName = firstName
            thawed.lastName = lastName
            thawed.phoneNumber = phoneNumber
            thawed.imageData = imageData
        }
        
        self.addFriends(friendIds)
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
    
    func updateRecentPost(to id: ObjectId) {
        RealmManager.updateObject(self) { thawed in
            thawed.mostRecentPost = id
        }
    }
    
    static func getProfile(for id: String) -> ShorterProfile? {
        let profile: ShorterProfile? =  RealmManager.retrieveObject { query in
            query.ownerId == id
        }.first
        
        return profile
    }
    
//    MARK: Social Functions
    func addFriends( _ ids: [String] ) {
        for id in ids {
            addFriend(id)
        }
    }
    
    func addFriend( _ id: String ) {
        if let friend = ShorterProfile.getProfile(for: id) {
            RealmManager.updateObject(self) { thawed in
                thawed.friendIds.append(id)
            }
            RealmManager.updateObject(friend) { thawed in
                thawed.friendIds.append(ShorterModel.ownerId)
            }
        }
    }
    
//    MARK: ClassMethods
    func logout() {
        self.clearFriendListFromDefaults()
    }
    
//    Goes throuhg all friends in the profile and saves certain information to userDefaults
//    that is accessible to the widgets
    func saveFriendListToDefaults() {
        if let defaults = UserDefaults(suiteName: WidgetKeys.suiteName) {
            
            defaults.set(self.friendIds.count, forKey: WidgetKeys.totalFriendsKey)
            
            for i in 0..<friendIds.count {
                
                if let friend: ShorterProfile = RealmManager.retrieveObject(where: { query in
                    query.ownerId == self.friendIds[i]
                }).first {
                    
                    var imageData = Data()
                    if let post = ShorterPost.getPost(from: friend.mostRecentPost) {
                        let uiImage = PhotoManager.decodeUIImage(from: post.imageData)
                        imageData = PhotoManager.encodeImage(uiImage, compressionQuality: 0.5)
                    }
                    
                    defaults.set(friend.ownerId,
                                 forKey: WidgetKeys.friendOwnerIdBaseKey + "\(i)")
                    defaults.set(friend.firstName,
                                 forKey: WidgetKeys.friendFirstNameBaseKey + "\(i)")
                    defaults.set(friend.lastName,
                                 forKey: WidgetKeys.friendLastNameBaseKey + "\(i)")
                    defaults.set(imageData,
                                 forKey: WidgetKeys.friendRecentImageDataBaseKey + "\(i)")
                }
            }
        }
    }
    
    private func clearFriendListFromDefaults() {
        if let defaults = UserDefaults(suiteName: WidgetKeys.suiteName) {
            for i in 0..<friendIds.count {
                defaults.removeObject(forKey: WidgetKeys.friendOwnerIdBaseKey + "\(i)")
                defaults.removeObject(forKey: WidgetKeys.friendFirstNameBaseKey + "\(i)")
                defaults.removeObject(forKey: WidgetKeys.friendLastNameBaseKey + "\(i)")
                defaults.removeObject(forKey: WidgetKeys.friendRecentImageDataBaseKey + "\(i)")
            }
        }
    }
    
}
