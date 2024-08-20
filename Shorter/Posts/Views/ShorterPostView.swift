//
//  ShorterPostView.swift
//  Shorter
//
//  Created by Brian Masse on 6/26/24.
//

import Foundation
import SwiftUI
import UIUniversals

//MARK: ShorterPostsView
struct ShorterPostsView: View {
    
    @State private var currentPostIndex: Int = 0 {
        willSet {
            currentPostIndex = min( newValue, posts.count - 1 )
        }
    }
    
    private let initialIndex: Int
    let posts: [ShorterPost]
    
    init( posts: [ShorterPost], initialIndex: Int = 0 ) {
        self.initialIndex = initialIndex
        self.posts = posts
    }
    
    var body: some View {
            
        GeometryReader { geo in
            ScrollViewReader { proxy in
                ScrollView(.horizontal, showsIndicators: false) {
                    
                    LazyHStack {
                        ForEach(posts.indices, id: \.self) { i in
                            let post = posts[i]
                            
                            ShorterPostView(post: post,
                                            inScrollView: true,
                                            currentPostIndex: $currentPostIndex)
                            .frame(width: geo.size.width)
                            .rotationEffect(Angle(degrees: 180)).scaleEffect(x: 1.0, y: -1.0, anchor: .center)
                            .id(i)
                        }
                    }
                    .scrollTargetLayout()
                }
                .scrollTargetBehavior(.viewAligned)
                .onAppear {
                    proxy.scrollTo(initialIndex)
                }
                .rotationEffect(Angle(degrees: 180)).scaleEffect(x: 1.0, y: -1.0, anchor: .center)
            }
        }
        .ignoresSafeArea(edges: .top)
    }
}

#Preview(body: {
    ShorterPostsView(posts: [])
})

struct ShorterPostView: View {
    
    @Environment(\.dismiss) var dismiss
    
//    MARK: Vars
    @State private var showDeleteAlert: Bool = false
    private let alertTitle = "Delete This Status?"
    private let alertMessage = "You can only reupload a new status for a limitted time."
    
    private let inScrollView: Bool
    
    @Binding var currentPostIndex: Int
    
    @State private var dismissOffset: CGFloat = 0
    
    init( post: ShorterPost, inScrollView: Bool = false, currentPostIndex: Binding<Int> = .init { 0 } set: { _ in } ) {
        self.inScrollView = inScrollView
        self.post = post
        self._currentPostIndex = currentPostIndex
    }
    
    let post: ShorterPost
    
    private var dissmissGesture: some Gesture {
        DragGesture(minimumDistance: 10)
            .onChanged { value in
                if value.translation.height < 0 { return }
                if value.translation.height > 200 {
                    dismiss()
                }
                dismissOffset = value.translation.height
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
    
//    MARK: Struct Methods
    private func incrementPostIndex() { withAnimation {
            currentPostIndex = currentPostIndex + 1
    } }
    
    private func decrementPostIndex() { withAnimation {
        currentPostIndex = max(0, currentPostIndex - 1)
    } }
    
//    MARK: Header
    @ViewBuilder
    private func makeHeader() -> some View {
        HStack {
            IconButton("chevron.down") { dismiss() }
            
            Spacer()
            
            makeIncrementationHandle(icon: "chevron.left") {
                self.incrementPostIndex()
            }
            
            Text( "Status" )
                .bold()
                .opacity(0.5)
            
            makeIncrementationHandle(icon: "chevron.right") {
                self.decrementPostIndex()
            }
            
            Spacer()
            
            if post.ownerId == ShorterModel.ownerId {
                IconButton("trash") { showDeleteAlert = true }
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
                .allowsHitTesting(false)
        }
        .clipShape(  UnevenRoundedRectangle(
            cornerRadii: .init(topLeading: Constants.UILargeTextSize,
                               bottomLeading: Constants.UILargeTextSize,
                               bottomTrailing: Constants.UILargeTextSize,
                               topTrailing: Constants.UILargeTextSize ))  )
        .animation(nil, value: currentPostIndex)
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
            
            Text( "\(post.fullTitle)  |  \(post.postedDate.formatted(date: .abbreviated, time: .omitted))" )
                .font(.title2)
                .opacity(0.75)
            
            Text( "\(post.ownerName)" )
                .font(.callout)
                .opacity(0.6)
                .padding(.bottom)
            
            ScrollView(.vertical, showsIndicators: false) {
                Text( "\(post.notes)" )
                    .font(.callout)
                    .padding([.horizontal, .bottom])
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
                
                VStack {
                    makeOverview()
                    
                    Divider(strokeWidth: 1)
                        .opacity(0.2)
                        .padding(.vertical)
                    
                    makeDateInformation()
                    
                    Spacer()
                    
                    makeHeader()
                        
                }
                .padding(.horizontal)
            }
        }
        .ignoresSafeArea(edges: .top)
        .offset(y: dismissOffset)
        .gesture(dissmissGesture)
        
        .alert(alertTitle,
               isPresented: $showDeleteAlert) {
            
            Button("delete", role: .destructive) {
                Task { await post.delete() }
                dismiss()
            }
            
        } message: { Text( alertMessage ) }
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
    
    let posts = [ post, post2, post3 ]
    
    return ShorterPostsView(posts: posts)
}
