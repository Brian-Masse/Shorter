//
//  ShorterPostPageViewModel.swift
//  Shorter
//
//  Created by Brian Masse on 6/26/24.
//

import Foundation
import SwiftUI

//MARK: ShorterPostsPageViewModel
class ShorterPostsPageViewModel: ObservableObject {
    
    private let maxCarouselPosts: Int = 10
    private let maxRecentlyShared: Int = 30
    
    static let shared = ShorterPostsPageViewModel()
    
    var posts: [ShorterPost] = []
    
    @Published var myPosts: [ShorterPost] = []
    @Published var filteredPosts: [ ShorterPost ] = []
    @Published var shouldShowPrompt: Bool = true
    
    @Published var allowMyPosts: Bool = false {
        didSet { Task { await getSharedWithMePosts(from: posts) } }
    }
    @Published var allowSharedPosts: Bool = true {
        didSet { Task { await getSharedWithMePosts(from: posts) } }
    }
    
    @Published var ownerId: String = ""
    
    @MainActor
    func toggleOwnerId(_ ownerId: String) {
        if self.ownerId == ownerId {
            self.ownerId = ""
            Task { await getSharedWithMePosts(from: posts) }
        }
        else {
            self.ownerId = ownerId
            Task { await filterPostsByPerson(from: posts, id: ownerId)}
        }
    }
    
    func loadAndFilterPosts( from posts: [ShorterPost] ) async {
        self.posts = posts
        
        await getMyPosts(from: posts)
        await getSharedWithMePosts(from: posts)
        await checkShouldShowPrompt()
    }
    
    @MainActor
    private func checkShouldShowPrompt() async {
        var shouldShowPrompt = true
        
        if let recentPost = myPosts.first {
            let previousFire = TimingManager.getPreviousFiringTime()
            shouldShowPrompt = !(recentPost.postedDate > previousFire)
        }
            
        self.shouldShowPrompt = shouldShowPrompt
    }
    
//    MARK: FilterPosts
    @MainActor
    func getMyPosts(from posts: [ShorterPost]) async {
        let filteredPosts = Array(posts
            .filter { post in post.ownerId == ShorterModel.ownerId }
            .sorted(by: { post1, post2 in
                post1.postedDate > post2.postedDate
            })
            .prefix(maxCarouselPosts))
        
        withAnimation { self.myPosts = filteredPosts }
    }
    
    @MainActor
    func getSharedWithMePosts(from posts: [ShorterPost]) async {
        let filteredPosts = Array(posts
            .filter { post in
                ShorterModel.shared.profile!.allowsMatureContent || !post.hasMatureContent
            }
            .filter { post in
                !ShorterModel.shared.profile!.hiddenPosts.contains(where: { id in
                    post._id == id
                })
            }
            .filter { post in
                let defaultOwnerId = ShorterModel.ownerId
                return (allowMyPosts || post.ownerId != defaultOwnerId) && (allowSharedPosts || post.ownerId == defaultOwnerId)
            }
            .sorted(by: { post1, post2 in
                post1.postedDate > post2.postedDate
            })
            .prefix(maxRecentlyShared)
        )
        
        withAnimation { self.filteredPosts = filteredPosts }
    }
    
    @MainActor
    private func filterPostsByPerson( from posts: [ShorterPost], id: String ) async {
        await getSharedWithMePosts(from: posts)
        
        let filteredPosts = filteredPosts.filter { post in
            post.ownerId == id
        }
        
        withAnimation { self.filteredPosts = filteredPosts }
    }
}
