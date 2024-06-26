//
//  ShorterPostsView.swift
//  Shorter
//
//  Created by Brian Masse on 6/23/24.
//

import Foundation
import SwiftUI
import UIUniversals

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
}

struct ShorterPostsView: View {
    
//    MARK: Vars
    let posts: [ ShorterPost ]
    
    @ObservedObject var viewModel = ShorterPostsPageViewModel.shared
    
    @State private var expanded: Bool = false
    private let compactMainContentHeight = 0.4
    private let compactPrmptHeight = 0.35
    
    
    private func makeMainContentHeight(in geo: GeometryProxy) -> CGFloat {
        geo.size.height * (viewModel.shouldShowPrompt ? compactPrmptHeight : compactMainContentHeight)
    }
    
//    MARK: Getsures
    private var swipeGesture: some Gesture {
        DragGesture(minimumDistance: 30)
            .onChanged { value in
                if value.translation.height < -30 {
                    withAnimation { expanded = true }
                } else if value.translation.height > 30 {
                    withAnimation { expanded = false }
                }
            }
    }
    
//    MARK: Header
    @ViewBuilder
    private func makeHeader() -> some View {
        HStack {
            IconButton("gear") { Task { ShorterModel.realmManager.logoutUser() }}
            
            Spacer()
            
            IconButton("wallet.pass") {  }
        }
    }
    
//    MARK: PostsView
    @ViewBuilder
    private func makePostsView() -> some View {
        VStack(alignment: .leading) {
            
            HStack {
                Text( "Recently shared" )
                    .font(.title2)
                    .bold()
                
                Spacer()
                
                Menu {
                    Button(action: { viewModel.allowMyPosts.toggle() }, label: {
                        Label("my posts", systemImage: viewModel.allowMyPosts ? "checkmark" : "minus")
                    })
                    
                    Button(action: { viewModel.allowSharedPosts.toggle() }, label: {
                        Label("Shared posts", systemImage: viewModel.allowSharedPosts ? "checkmark" : "minus")
                    })
                    
                } label: {
                    IconButton("line.3.horizontal.decrease") { }
                }.menuActionDismissBehavior(.disabled)
            }
            
            StyledScrollView(height: ShorterPostPreviewView.height,
                             cards: viewModel.filteredPosts) { post, _ in
                
                ShorterPostPreviewView(post: post)
            }
        }
        .background{
            RoundedRectangle(cornerRadius: Constants.UIDefaultCornerRadius)
                .foregroundStyle(.background)
        }
    }
    
//    MARK: PostsCarousel
    @ViewBuilder
    private func makePostsCarousel() -> some View {
        VStack {
            if !viewModel.shouldShowPrompt {
                ShorterPostsCarousel(posts: viewModel.myPosts)
            } else {
                ShorterPostPromptView()
                    .padding()
            }
        }
    }
    
//    MARK: Body
    var body: some View {
        GeometryReader { geo in
            VStack(alignment: .leading) {
                makeHeader()
                    .padding(.horizontal)
                
                ZStack(alignment: .top) {
                    makePostsCarousel()
                        .frame(height: makeMainContentHeight(in: geo))
                    
                    Spacer()
                    
                    VStack(spacing: 0) {
                        Spacer(minLength: expanded ? 0 : makeMainContentHeight(in: geo))
                        
                        makePostsView()
                    }
                }
                
                Text( ShorterModel.ownerId )
            }
        }
        .gesture(swipeGesture)
        .padding(.horizontal)
        .task {
            await viewModel.loadAndFilterPosts(from: posts)
        }
    }
}

#Preview {
    let uiImage = UIImage(named: "BigSur")
    let imageData = PhotoManager.encodeImage(uiImage)
    
    let uiImage2 = UIImage(named: "JTree")
    let imageData2 = PhotoManager.encodeImage(uiImage2)
    
    let uiImage3 = UIImage(named: "Goats")
    let imageData3 = PhotoManager.encodeImage(uiImage3)
    
    let post = ShorterPost(ownerId: "66759d000ae4d97657a322dd",
                           authorName: "Brian Masse",
                           fullTitle: "Working on Shorter",
                           title: "Coding",
                           emoji: "😶",
                           notes: "I had a blast because after a lot of infastructure code yesterday, I finally get to focus on the UI!",
                           data: imageData)
    
    let post2 = ShorterPost(ownerId: "66759d000ae4d97657a322dd",
                           authorName: "Brian Masse",
                           fullTitle: "Testing a Card",
                           title: "Testing",
                           emoji: "😶",
                           notes: "I had a blast because after a lot of infastructure code yesterday, I finally get to focus on the UI!",
                           data: imageData2)
    
    let post3 = ShorterPost(ownerId: "test2",
                           authorName: "Brian Masse",
                           fullTitle: "Testing a Card",
                           title: "Testing",
                           emoji: "😶",
                           notes: "I had a blast because after a lot of infastructure code yesterday, I finally get to focus on the UI!",
                           data: imageData3)
    
    let posts = [ post, post2, post3, post2, post, post2, post3, post2 ]
    
    return ShorterPostsView(posts: posts)
}
