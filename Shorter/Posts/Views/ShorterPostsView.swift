//
//  ShorterPostsView.swift
//  Shorter
//
//  Created by Brian Masse on 6/23/24.
//

import Foundation
import SwiftUI
import UIUniversals

struct ShorterPostsView: View {
    
//    MARK: Vars
    let posts: [ ShorterPost ]
    
    @State var showingCreatePostView: Bool = false
    @State private var expanded: Bool = false
    
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
    
//    MARK: ViewBuilders
    @ViewBuilder
    private func makeHeader() -> some View {
        HStack {
            IconButton("gear") { Task { await ShorterModel.realmManager.logoutUser() }}
            
            Spacer()
            
            IconButton("wallet.pass") { showingCreatePostView = true }
        }
    }
    
    @ViewBuilder
    private func makePostsView() -> some View {
        VStack(alignment: .leading) {
            
            HStack {
                Text( "Recently shared" )
                    .font(.title2)
                    .bold()
                
                Spacer()
                
                IconButton("line.3.horizontal.decrease") { }
            }
            
            let posts = posts.sorted { post1, post2 in
                post1.postedDate > post2.postedDate
            }
            
            StyledScrollView(height: ShorterPostPreviewView.height,
                             cards: posts) { post, _ in
                
                ShorterPostPreviewView(post: post)
            }
        }
        .background{
            RoundedRectangle(cornerRadius: Constants.UIDefaultCornerRadius)
                .foregroundStyle(.background)
        }
    }
    
//    MARK: Body
    var body: some View {
        GeometryReader { geo in
            VStack(alignment: .leading) {
                makeHeader()
                    .padding(.horizontal)
                
                ZStack(alignment: .top) {
                    
                    //                if let post = ShorterPost.getPost(from: ShorterModel.shared.profile?.mostRecentPost) {
                    if posts.count > 0 {
                        ShorterPostQuickCreationView(posts: posts)
                            .frame(height: geo.size.height * 0.5)
                        //                }
                    }
                    
                    Spacer()
                    
                    VStack(spacing: 0) {
                        Spacer(minLength: expanded ? 0 : geo.size.height * 0.5)
                        
                        makePostsView()
                    }
                }
            }
        }
        .gesture(swipeGesture)
        .padding(.horizontal)
        .sheet(isPresented: $showingCreatePostView) {
            CreatePostView()
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
    
    let post = ShorterPost(ownerId: "test",
                           authorName: "Brian Masse",
                           fullTitle: "Working on Shorter",
                           title: "Coding",
                           emoji: "😶",
                           notes: "I had a blast because after a lot of infastructure code yesterday, I finally get to focus on the UI!",
                           data: imageData)
    
    let post2 = ShorterPost(ownerId: "test2",
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
