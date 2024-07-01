//
//  ShorterPostQuickCreationView.swift
//  Shorter
//
//  Created by Brian Masse on 6/23/24.
//

import Foundation
import SwiftUI
import UIUniversals

//@MainActor
struct ShorterPostsCarousel: View {
    
    let mostRecentFiring: Date = .now - Constants.DayTime
//    TimingManager.getPreviousFiringTime()
    
    static let coordinateSpaceName = "customCoordSpace"
    
    private struct LocalConstants {
        static let previewSize: CGFloat = 175
        static let smallPreviewSize: CGFloat = 100
        static let previewVerticalOffset: CGFloat = 0
    }
    
//    MARK: InformationNode
    private struct InformationNode<C: View>: View {
        
        
//        MARK: Line
        private struct Line: Shape {
            var x: CGFloat
            var y: CGFloat
            
            let size: CGSize
            
            private func xUnit(dx: CGFloat, _ mag: CGFloat) -> CGFloat { dx / mag }
            private func yUnit(dy: CGFloat, _ mag: CGFloat) -> CGFloat { dy / mag }
            
            let startRadius: CGFloat = 75
            
            var animatableData: AnimatablePair<CGFloat, CGFloat> {
                get { AnimatablePair(x, y) }
                set { x = newValue.first; y = newValue.second }
            }
            
//            This leaves space around the content, so the line does not overlap
            private func makeYSpacing(startY: CGFloat, y: CGFloat) -> CGFloat {
                let distance = y - startY
                let yDir = distance / abs(distance)
                
                return size.height / 2 * -yDir
            }
            
//        from the top of the geometry reader, this is where the center of the widget is
            private var verticalOffset: CGFloat {
                LocalConstants.previewVerticalOffset
            }
            
            func path(in rect: CGRect) -> Path {
                Path { path in
                    let start = CGPoint(x: rect.midX, y: rect.midY + verticalOffset)
                    
                    let dx = x
                    let dy = y + verticalOffset
                    let mag = sqrt( pow(dx, 2) + pow(dy, 2) )
                    
                    let xUnit = xUnit(dx:dx, mag)
                    let yUnit = yUnit(dy:dy, mag)
                    
                    path.move(to: .init(x: start.x + xUnit * startRadius,
                                        y: start.y + yUnit * startRadius) )
                    
                    
                    if abs(y) > abs(yUnit * startRadius) && abs(x) > abs(xUnit * startRadius) {
                        
                        let x = rect.midX + x
                        let y = rect.midY + y + makeYSpacing( startY: start.y, y: rect.midY + y )
                        
                        path.addLine(to: .init(x: x, y: y ))
                    }
                }
            }
        }
        
//        MARK: InformationNode Methods
//        from the top of the geometry reader, this is where the center of the widget is
        private var verticalOffset: CGFloat {
            ShorterPostsCarousel.LocalConstants.previewVerticalOffset
//            + ShorterPostQuickCreationView.LocalConstants.previewSize / 2
        }
        
        private func makeStartingOffset(in geo: GeometryProxy) -> CGSize {
            let globalPosition = localToGlobalCoordinates(in: geo)
            
            return .init(width: fullGeo.size.width / 2 - globalPosition.x,
                         height: fullGeo.size.height / 2 - verticalOffset - globalPosition.y )
        }
        
        private func localToGlobalCoordinates(in geo: GeometryProxy) -> CGPoint {
            let coordSpaceName = ShorterPostsCarousel.coordinateSpaceName
            
            let currentX = geo.frame(in: .named(coordSpaceName) ).midX
            let currentY = geo.frame(in: .named(coordSpaceName) ).midY
            
            return .init(x: currentX, y: currentY)
        }
        
        private var xDir: CGFloat {
            let magnitude = globalFinalOffset.width - (fullGeo.size.width / 2)
            return magnitude / abs(magnitude)
        }
        
        private var yDir: CGFloat {
            let magnitude = globalFinalOffset.height - fullGeo.size.height / 2
            return magnitude / abs(magnitude)
        }
        
        private func checkInPosition() -> Bool {
            abs(scrollPosition + (fullGeo.size.width + 8) * Double(id)) < 100
        }
        
//        MARK: InformationNode Vars
        let fullGeo: GeometryProxy
        let alignment: Alignment
        let finalOffset: CGSize
        
        let id: Int
        
        let content: C
        
        @State var expanded: Bool = true
        @State var alpha: Double = 0
        
        @State var refreshStartPosition: Bool = false
        
        @State var size: CGSize = .zero
        @State var offset: CGSize = .zero
        @Binding var scrollPosition: CGFloat
        
        @State var globalStartingOffset: CGSize = .zero
        @State var globalFinalOffset: CGSize = .zero
        
        init( geo: GeometryProxy, id: Int, alignment: Alignment, offset: CGPoint, scrollPos: Binding<CGFloat>, @ViewBuilder contentBuilder: () -> C) {
            
            self.fullGeo = geo
            self.alignment = alignment
            self.finalOffset = .init(width: offset.x, height: offset.y)
            self.offset = finalOffset
            self.id = id
            self._scrollPosition = scrollPos
            
            self.content = contentBuilder()
        }
        
//        MARK: InformationNode Body
        var body: some View {
            ZStack(alignment: alignment) {
                Rectangle()
                    .foregroundStyle(.clear)
                            
                let negativeOffset = abs( offset.width ) + (size.width / 2)
                let x = xDir * (fullGeo.size.width / 2 - negativeOffset )
                let y = yDir * (fullGeo.size.height / 2 - abs( offset.height ) - (size.height / 2) - 10)
                
                Line(x: x, y: y, size: size)
                    .stroke(lineWidth: 2)
                
                content
                    .overlay { GeometryReader { localGeo in
                        if refreshStartPosition {
                            Rectangle()
                                .foregroundStyle(.clear)
                                .onAppear {
                                    
                                    alpha = 1
                                    
                                    if !checkInPosition() { return }
                                    
                                    self.offset = makeStartingOffset(in: localGeo)
                                    self.globalStartingOffset = offset
                                    self.size = localGeo.size

                                    let globalCoords = localToGlobalCoordinates(in: localGeo)
                                    self.globalFinalOffset = .init(width: globalCoords.x,
                                                                   height: globalCoords.y)
                                    
                                    alpha = 1
                                    withAnimation { self.offset = finalOffset }
                                }
                        }
                    } }
                    .offset(offset)
                    .onAppear {
                        if checkInPosition() { refreshStartPosition = true }
                    }
                    .onChange(of: scrollPosition) {
                        if checkInPosition() { refreshStartPosition = true }
                    }
                    .onDisappear {
                        alpha = 0
                    }
            }
            .opacity(alpha)
        }
    }
    
//    MARK: InformationNodes
    @ViewBuilder
    private func makeInformationNodes(in geo: GeometryProxy, for post: ShorterPost, id: Int) -> some View {
        ZStack {
            InformationNode(geo: geo,
                            id: id,
                            alignment: .topLeading,
                            offset: .init(x: 0 , y: 20),
                            scrollPos: $scrollPosition.x) {
                Text("\(post.title) \(id)")
                    .font(.title3)
                    .bold()
            }

            InformationNode(geo: geo,
                            id: id,
                            alignment: .bottomTrailing,
                            offset: .init(x: 0, y: -15),
                            scrollPos: $scrollPosition.x) {
                VStack(alignment: .leading) {
                    Text( post.notes )
                        .font(.caption)
                        .multilineTextAlignment(.trailing)
                        .lineLimit(3, reservesSpace: true)
                }
                .frame(width: 125)
            }

            InformationNode(geo: geo,
                            id: id,
                            alignment: .bottomLeading,
                            offset: .init(x: 20, y: -30),
                            scrollPos: $scrollPosition.x) {
                Text( "\(post.postedDate.formatted(date: .abbreviated, time: .omitted))\n\(post.postedDate.formatted(date: .omitted, time: .shortened))" )
                    .font(.callout)
            }
        }
    }
    
//    MARK: CenterWidget    
    @State private var scrollPosition: CGPoint = .zero
    
    private struct ScrollOffsetPreferenceKey: PreferenceKey {
        
        static var defaultValue: CGPoint = .zero
        
        static func reduce(value: inout CGPoint, nextValue: () -> CGPoint) { }
    }
    
    @MainActor
    @ViewBuilder
    private func makeCenterWidgetWrapper() -> some View {
        ZStack {
            
            GeometryReader { geo in
                ScrollView(.horizontal, showsIndicators: false) {
                    LazyHStack {
                        ForEach( posts.indices, id: \.self ) { id in
                            let post = posts[id]
                            makeCenterWidget(from: post, id: posts.count - 1 - id, in: geo)
                                .rotationEffect(Angle(degrees: 180)).scaleEffect(x: 1.0, y: -1.0, anchor: .center)
                        }
                    }
                    .background(GeometryReader { geo in
                        Color.clear
                            .preference(key: ScrollOffsetPreferenceKey.self,
                                        value: geo.frame(in: .named(ShorterPostsCarousel.coordinateSpaceName)).origin)
                    })
                    .onPreferenceChange(ScrollOffsetPreferenceKey.self) { value in
                        self.scrollPosition = value
                        
                    }
                    .scrollTargetLayout()
                }
                .rotationEffect(Angle(degrees: 180)).scaleEffect(x: 1.0, y: -1.0, anchor: .center)
                .scrollTargetBehavior(.viewAligned)
                .coordinateSpace(name: ShorterPostsCarousel.coordinateSpaceName)
                .background {
                    posts[activePostIndex].getCompressedImage()
                        .antialiased(false)
                        .resizable()
                        .imageScale(.small)
                        .frame(height: geo.size.height)
                        .blur(radius: 100)
                }
            }
        }
    }
    
    @ViewBuilder
    private func makeCenterWidget(from post: ShorterPost, id: Int, in geo: GeometryProxy) -> some View {
        
        ZStack {
            
            post.getImage()
                .resizable()
                .clipped()
                .aspectRatio(contentMode: .fill)
                .frame(width: 200, height: 200)
            
                .clipShape(RoundedRectangle(cornerRadius: Constants.UILargeTextSize))
                .shadow(color: .black.opacity(0.3), radius: 10, y: 10)
            
                .onTapGesture { showingPostView = true }
            
            makeInformationNodes(in: geo, for: post, id: id)
        }
        .frame(width: geo.size.width)
        .contentShape(Rectangle())
        .onChange(of: scrollPosition) {
            if abs(scrollPosition.x + (geo.size.width + 8) * Double(id)) < 100 {
                withAnimation { activePostIndex = posts.count - 1 -  id }
            }
        }
    }
    
//    MARK: Vars
    
    let posts: [ShorterPost]
    
    @State var activePostIndex: Int = 0
    
    @State private var showingPostView: Bool = false
    
//    MARK: ExpandedLayout
    @MainActor
    @ViewBuilder
    private func makeExpandedLayout() -> some View {
        ZStack {
            makeCenterWidgetWrapper()
                .offset(y: LocalConstants.previewVerticalOffset)
            
            HStack {
                Image(systemName: "chevron.left")
                    .padding()
                    .opacity( 0.5 )
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .padding()
                    .opacity( 0.5 )
            }
        }
        .contentShape(Rectangle())
    }
    
    
//    MARK: Body
    var body: some View {
        
        VStack(alignment: .leading, spacing: 0) {
            ZStack(alignment: .topLeading) {
                makeExpandedLayout()
            }
        }
        .fullScreenCover(isPresented: $showingPostView) {
            ShorterPostsView(posts: posts)
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
    
    let posts = [ post, post2, post3, post2 ]
    
    return VStack {
        ShorterPostsCarousel(posts: posts)
            .frame(height: 400)
        
        Spacer()
    }
}
