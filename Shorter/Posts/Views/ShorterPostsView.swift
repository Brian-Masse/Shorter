//
//  ShorterPostsView.swift
//  Shorter
//
//  Created by Brian Masse on 8/20/24.
//

import Foundation
import SwiftUI

private struct ScrollOffsetPreferenceKey: PreferenceKey {
    
    static var defaultValue: CGPoint = .zero
    
    static func reduce(value: inout CGPoint, nextValue: () -> CGPoint) { }
}

//MARK: ShorterPostsView
struct ShorterPostsView: View {
    
    @Environment(\.dismiss) var dismiss
    
    private let coordinateSpaceName = "swipe"
    
    @State private var showDeleteAlert: Bool = false
    private let alertTitle = "Delete This Status?"
    private let alertMessage = "You can only reupload a new status for a limitted time."
    
    @State private var currentPostIndex: Int
    private let initialIndex: Int
    private let posts: [ShorterPost]
    
    init( posts: [ShorterPost], initialIndex: Int = 0 ) {
        self.initialIndex = initialIndex
        self.currentPostIndex = initialIndex
        self.posts = posts
    }
    
//    takes in the current scroll position of the modal, and returns the current post index the user is viewing
    private func setCurrentPostIndex(from scrollPosition: CGPoint, in geo: GeometryProxy) {
        let proposedIndex = Int(floor(abs(scrollPosition.x) / abs(geo.size.width + 15)))
        let index = min(max(proposedIndex, 0), posts.count - 1)
        
        self.currentPostIndex = posts.count - 1 - index
    }
    
    private func incrementPostIndex(by increment: Int, proxy: ScrollViewProxy) {
        
        let proposedIndex = self.currentPostIndex - increment
        let index = min(max(proposedIndex, 0), posts.count - 1)
        
        withAnimation {
            self.currentPostIndex = index
            proxy.scrollTo(index)
        }
    }
    
//    MARK: Header
    @ViewBuilder
    private func makeHeader() -> some View {
        HStack {
            IconButton("chevron.down") { dismiss() }
            
            Spacer()
            
            IconButton("trash") { showDeleteAlert = true }
                .opacity(posts[currentPostIndex].ownerId == ShorterModel.ownerId ? 1 : 0)
        }
        .padding(.horizontal, 40)
        .padding(.top, 20)
    }
    
//    MARK: Footer
    @ViewBuilder
    private func makeIncrementationHandle(increment: Int, icon: String, proxy: ScrollViewProxy) -> some View {
        Image(systemName: icon)
            .onTapGesture {
                incrementPostIndex(by: -1, proxy: proxy)
            }
    }
    
    @ViewBuilder
    private func makeFooter(proxy: ScrollViewProxy) -> some View {
        HStack {
            Spacer()
            
            makeIncrementationHandle(increment: -1, icon: "chevron.left", proxy: proxy)

            Text( posts[currentPostIndex].postedDate.formatted(date: .numeric, time: .omitted) )
                .padding(.horizontal)
            
            makeIncrementationHandle(increment: 1, icon: "chevron.right", proxy: proxy)
            
            Spacer()
        }
        .bold()
        .opacity(0.5)
    }
    
//    MARK: Body
    var body: some View {
            
        GeometryReader { geo in
            ScrollViewReader { proxy in
                ScrollView(.horizontal, showsIndicators: false) {
                    
                    LazyHStack(spacing: 15) {
                        ForEach(posts.indices, id: \.self) { i in
                            let post = posts[i]
//
                            ShorterPostView(post: post)
                            .frame(width: geo.size.width)
                            .rotationEffect(Angle(degrees: 180)).scaleEffect(x: 1.0, y: -1.0, anchor: .center)
                            .id(i)
                        }
                    }
                    .scrollTargetLayout()
                    .background(GeometryReader { geo in
                        Color.clear
                            .preference(key: ScrollOffsetPreferenceKey.self,
                                        value: geo.frame(in: .named(coordinateSpaceName)).origin)
                    })
                    .onPreferenceChange(ScrollOffsetPreferenceKey.self) { value in
                        setCurrentPostIndex(from: value, in: geo)
                    }
                }
                .scrollTargetBehavior(.viewAligned)
                .onAppear { proxy.scrollTo(initialIndex) }
                .rotationEffect(Angle(degrees: 180)).scaleEffect(x: 1.0, y: -1.0, anchor: .center)
                .overlay {
                    VStack {
                        makeHeader()
                        
                        Spacer()
                        
                        makeFooter(proxy: proxy)
                    }
                }
            }
        }
        .statusBarHidden()
        .coordinateSpace(name: coordinateSpaceName)
        .ignoresSafeArea(edges: .top)
        .alert(alertTitle,
               isPresented: $showDeleteAlert) {
            
            Button("delete", role: .destructive) {
                Task { await posts[currentPostIndex].delete() }
                dismiss()
            }
            
        } message: { Text( alertMessage ) }
    }
}

#Preview(body: {
    ShorterPostsView(posts: [])
})
