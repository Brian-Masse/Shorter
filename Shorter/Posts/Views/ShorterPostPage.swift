//
//  ShorterPostsView.swift
//  Shorter
//
//  Created by Brian Masse on 6/23/24.
//

import Foundation
import SwiftUI
import UIUniversals
import WidgetKit

struct ShorterPostPage: View {
    
//    MARK: Vars
    let posts: [ ShorterPost ]
    
    @ObservedObject var viewModel = ShorterPostsPageViewModel.shared
    
    @State private var expanded: Bool = false
    private let compactMainContentHeight = 0.4
    private let compactPrmptHeight = 0.35
    
    @State private var showingProfileView: Bool = false
    @State private var showingSocialPageView: Bool = false
    
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
            IconButton("person.badge.plus") { Task { showingSocialPageView = true }}
            
            Spacer()
            
            IconButton("wallet.pass") { showingProfileView = true }
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
                    makeFriendsMenu()
                    
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
            
            if !viewModel.filteredPosts.isEmpty {
                StyledScrollView(height: ShorterPostPreviewView.height,
                                 cards: viewModel.filteredPosts) { post, _ in
                    
                    ShorterPostPreviewView(post: post, posts: posts)
                }
            } else {
                
                ShorterPlaceHolderView(icon: "square.grid.3x3.square",
                                       message: "When your friends post, you'll be able to view them here")
                
                Spacer()
            }
        }
        .padding()
        .background{
            RoundedRectangle(cornerRadius: Constants.UIDefaultCornerRadius)
                .foregroundStyle(.background)
        }
        .onAppear {
            WidgetCenter.shared.reloadAllTimelines()
        }
    }
    
    private func makeFriendsMenu() -> some View {
        Menu("Friends") {
            ForEach(ShorterModel.shared.profile!.friendIds) { id in
                    
                if let profile = ShorterProfile.getProfile(for: id) {
                    
                    
                    Button(profile.fullName,
                           systemImage: viewModel.ownerId == id ? "checkmark" : "minus") {
                        viewModel.toggleOwnerId(id)
                    }
                }
            }
        }
    }
    
//    MARK: PostsCarousel
    @ViewBuilder
    private func makePostsCarousel() -> some View {
        VStack {
            if !viewModel.shouldShowPrompt && !posts.isEmpty {
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
                        .padding(.horizontal)
                    
                    Spacer()
                    
                    VStack(spacing: 0) {
                        Spacer(minLength: expanded ? 0 : makeMainContentHeight(in: geo))
                        
                        makePostsView()
                    }
                }
            }
        }
        .gesture(swipeGesture)
        .fullScreenCover(isPresented: $showingProfileView) {
            ProfileView(profile: ShorterModel.shared.profile!)
        }
        .fullScreenCover(isPresented: $showingSocialPageView, content: {
            SocialPageView()
        })
        .task { await viewModel.loadAndFilterPosts(from: posts) }
        .onChange(of: posts) {
            Task { await viewModel.loadAndFilterPosts(from: posts ) }
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
    
    return ShorterPostPage(posts: posts)
}
