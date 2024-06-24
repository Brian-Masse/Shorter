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
    
//    MARK: ViewBuilders
    @ViewBuilder
    private func makeHeader() -> some View {
        HStack {
            IconButton("gear") { }
            
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
    }
    
//    MARK: Body
    var body: some View {
        VStack(alignment: .leading) {
            
            makeHeader()
                .padding(.horizontal)
            
            if let post = ShorterPost.getPost(from: ShorterModel.shared.profile?.mostRecentPost) {
                ShorterPostQuickCreationView(mostRecentPost: post)
                    .background {
                        RoundedRectangle(cornerRadius: Constants.UIDefaultCornerRadius)
                            .opacity(0.1)
                            .padding(.vertical, 60)
                    }
            }
            
            makePostsView()
        }
        .padding(.horizontal)
        .sheet(isPresented: $showingCreatePostView) {
            CreatePostView()
        }
    }
}
