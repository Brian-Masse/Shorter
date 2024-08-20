//
//  ShorterPostView.swift
//  Shorter
//
//  Created by Brian Masse on 6/26/24.
//

import Foundation
import SwiftUI
import UIUniversals

//MARK: ShorterPostView
struct ShorterPostView: View {
    
    @Environment(\.dismiss) var dismiss
    
//    MARK: Vars
    @State private var dismissOffset: CGFloat = 0
    
    init( post: ShorterPost) {
        self.post = post
    }
    
    let post: ShorterPost
    
    private var dissmissGesture: some Gesture {
        DragGesture(minimumDistance: 10)
            .onChanged { value in
                if value.translation.height < 0 { return }
                if value.translation.height > 200 {
                    dismiss()
                } else {
                    dismissOffset = value.translation.height
                }
            }
                
            .onEnded { value in
                if value.translation.height > 200 {
                    dismiss()
                } else {
                    withAnimation {
                        dismissOffset = 0
                    }
                }
            }
    }
    
//    MARK: Image
    @ViewBuilder
    private func makeImage(in geo: GeometryProxy) -> some View {
        
        ZStack(alignment: .top) {
            post.getImage()
                .resizable()
                .aspectRatio(contentMode: .fill)
                .frame(width: geo.size.width, height: geo.size.height * 0.5)
                .clipped()
        }
        .clipShape(  UnevenRoundedRectangle(
            cornerRadii: .init(
                               bottomLeading: Constants.UILargeTextSize,
                               bottomTrailing: Constants.UILargeTextSize)  ))
    }
    
//    MARK: Overview
    @ViewBuilder
    private func makeOverview() -> some View {
        VStack(alignment: .leading) {
            HStack {
                Text( "\(post.title) \(post.emoji)" )
                    .font(.largeTitle)
                    .bold()
                
                Spacer()
            }
            
            Text( "\(post.ownerName)  |  \(post.postedDate.formatted(date: .abbreviated, time: .omitted))" )
                .font(.title2)
                .opacity(0.75)
                .padding(.bottom)
            
            makeDateInformation()
            
            ScrollView(.vertical, showsIndicators: false) {
                Text( "\(post.notes)" )
                    .font(.callout)
                    .padding()
                    .opacity(0.6)
            }
        }
    }
    
//    MARK: DateInformation
    @ViewBuilder
    private func makeDateInformationNode( title: String, date: Date ) -> some View {
        
        HStack {
            Text( title )
            
            Spacer()
            
            Text( date.formatted(date: .omitted, time: .shortened) )
                .bold()
        }
    }
    
    @ViewBuilder
    private func makeDateInformation() -> some View {
        VStack(alignment: .leading) {
            
            makeDateInformationNode(title: "This note was shared at",
                                    date: post.postedDate)
            
            makeDateInformationNode(title: "This note was expected at",
                                    date: post.expectedDate)
        }
        .rectangularBackground(style: .transparent)
    }
    
    @ViewBuilder
    private func makeIncrementationHandle( icon: String, action: @escaping () -> Void ) -> some View {
        
        Image(systemName: icon)
            .padding()
            .onTapGesture { withAnimation { action() } }
    }
    
    
//    MARK: Body
    var body: some View {
        GeometryReader { geo in
            VStack {
                
                makeImage(in: geo)
                
                makeOverview()
                    .padding(.horizontal)
            }
        }
        .ignoresSafeArea(edges: .top)
        .offset(y: dismissOffset)
        .gesture(dissmissGesture)
    }
}


//MARK: Preview
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
    
    let posts = [ post, post2, post3, post, post2, post3 ]
    
    return ShorterPostsView(posts: posts)
}
