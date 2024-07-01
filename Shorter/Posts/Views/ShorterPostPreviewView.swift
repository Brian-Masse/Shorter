//
//  ShortPreviewView.swift
//  Shorter
//
//  Created by Brian Masse on 6/22/24.
//

import Foundation
import SwiftUI
import UIKit


struct ShorterPostPreviewView: View {
    
    private struct LocalConstants {
        static let cardHeigt: Double = 100
    }
    
    let post: ShorterPost
    let posts: [ShorterPost]
    
    static var height: CGFloat { LocalConstants.cardHeigt }
    
    private var formattedCaption: String {
        "\(post.ownerName) on \( post.postedDate.formatted(date: .abbreviated, time: .omitted) )"
    }
    
    @State private var showingFullScreen: Bool = false
    @State private var showingHidePostAlert: Bool = false
    @State private var showingReportAndHideAlert: Bool = false
    
    private let hidePostAlertTitle: String = "Hide Post"
    private let hidePostAlertMessage: String = "You won't be able to see this post on your home feed anymore. You can undo this action later in settings. "
    
    private let reportAndHideTitle = "Report and Hide Post?"
    private let reportAndHideMessage = "If this post has innapropriate content, please let us know and we'll investigate it within 24 hours to keep Shorter safe."
    
//    MARK: ViewBuilders
    @ViewBuilder
    private func makeContent() -> some View {
        HStack {
            post.getImage()
                .resizable()
                .aspectRatio(contentMode: .fill)
                .frame(maxWidth: 150 )
                .clipped()
            
            VStack(alignment: .leading) {
                Text( post.title + " " + post.emoji )
//                    .font(.title3)
                    .bold()
                
                Text( post.notes )
                    .font(.caption)
                
                Spacer()
                
                Text( formattedCaption )
                    .font(.caption2)
                    .lineLimit(1)
            }
            .padding()
            
            Spacer()
        }
    }
    
//    MARK: Body
//    the view is formatted oddly so that a high level .frame(height) modifier can properrly
//    scale the body of the card
    var body: some View {
        
        Rectangle()
            .foregroundStyle(.ultraThinMaterial)
            .overlay { makeContent() }
            .clipShape(RoundedRectangle(cornerRadius: 25))
            .frame(maxHeight: LocalConstants.cardHeigt)
        
            .onTapGesture { showingFullScreen = true }
        
            .fullScreenCover(isPresented: $showingFullScreen) {
                ShorterPostsView(posts: ShorterPostsPageViewModel.shared.filteredPosts)
            }
        
            .contextMenu(ContextMenu(menuItems: {
                Button("Hide Post", systemImage: "square.slash") { showingHidePostAlert = true }
                Button("Report and Hide Post", systemImage: "exclamationmark.shield", role: .destructive) { showingReportAndHideAlert = true }
            }))

            .alert(hidePostAlertTitle, isPresented: $showingHidePostAlert) {
                Button("Hide post") { Task {
                    ShorterModel.shared.profile?.hidePost(post._id)
                    await ShorterPostsPageViewModel.shared.getSharedWithMePosts(from: posts)
                } }
            } message: { Text( hidePostAlertMessage ) }
        
            .alert(reportAndHideTitle, isPresented: $showingReportAndHideAlert) {
                Button("Report and Hide") { Task {
                    ShorterModel.shared.profile?.hidePost(post._id)
                    await ShorterPostsPageViewModel.shared.getSharedWithMePosts(from: posts)
                } }
                
            } message: { Text( reportAndHideMessage ) }
    }
}

