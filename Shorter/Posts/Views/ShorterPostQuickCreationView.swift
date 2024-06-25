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
struct ShorterPostQuickCreationView: View {
    
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
            ShorterPostQuickCreationView.LocalConstants.previewVerticalOffset
//            + ShorterPostQuickCreationView.LocalConstants.previewSize / 2
        }
        
        private func makeStartingOffset(in geo: GeometryProxy) -> CGSize {
            let globalPosition = localToGlobalCoordinates(in: geo)
            
            return .init(width: fullGeo.size.width / 2 - globalPosition.x,
                         height: fullGeo.size.height / 2 - verticalOffset - globalPosition.y )
        }
        
        private func localToGlobalCoordinates(in geo: GeometryProxy) -> CGPoint {
            let coordSpaceName = ShorterPostQuickCreationView.coordinateSpaceName
            
            let currentX = geo.frame(in: .named(coordSpaceName) ).midX
            let currentY = geo.frame(in: .named(coordSpaceName) ).midY
            
            return .init(x: currentX, y: currentY)
        }
        
        private var xDir: CGFloat {
            let magnitude = globalFinalOffset.width - fullGeo.size.width / 2
            return magnitude / abs(magnitude)
        }
        
        private var yDir: CGFloat {
            let magnitude = globalFinalOffset.height - fullGeo.size.height / 2
            return magnitude / abs(magnitude)
        }
        
        private func toggleExpansion( _ value: Bool ) {
            withAnimation( .easeInOut(duration: 0.45) ) {
                if value {
                    self.offset = finalOffset
                    self.alpha = 1
                } else {
                    self.offset = globalStartingOffset
                    self.alpha = 0
                }
            }
        }
        
//        MARK: InformationNode Vars
        let fullGeo: GeometryProxy
        let alignment: Alignment
        let finalOffset: CGSize
        
        let content: C
        
        @Binding var expanded: Bool
        @State var alpha: Double = 0
        
        @State var size: CGSize = .zero
        @State var offset: CGSize = .zero
        
        @State var globalStartingOffset: CGSize = .zero
        @State var globalFinalOffset: CGSize = .zero
        
        init( geo: GeometryProxy, alignment: Alignment, offset: CGPoint, binding: Binding<Bool>, @ViewBuilder contentBuilder: () -> C) {
            
            self.fullGeo = geo
            self.alignment = alignment
            self.finalOffset = .init(width: offset.x, height: offset.y)
            self.offset = finalOffset
            
            self._expanded = binding
            self.content = contentBuilder()
        }
        
//        MARK: InformationNode Body
        var body: some View {
            ZStack(alignment: alignment) {
                Rectangle()
                    .foregroundStyle(.clear)
                            
                let x = xDir * (fullGeo.size.width / 2 - abs( offset.width ) - (size.width / 2))
                let y = yDir * (fullGeo.size.height / 2 - abs( offset.height ) - (size.height / 2) - 10)
                
                Line(x: x, y: y, size: size)
                    .stroke(lineWidth: 2)
                
                content
                    .overlay { GeometryReader { localGeo in
                        Rectangle()
                            .foregroundStyle(.clear)
                            .onAppear {
                                self.offset = makeStartingOffset(in: localGeo)
                                self.globalStartingOffset = offset
                                self.size = localGeo.size
                                
                                let globalCoords = localToGlobalCoordinates(in: localGeo)
                                self.globalFinalOffset = .init(width: globalCoords.x,
                                                               height: globalCoords.y)
                                
                                toggleExpansion(expanded)
                            }
                    } }
                    .opacity(alpha)
                    .offset(offset)
                    .onChange(of: expanded) { oldValue, newValue in
                        toggleExpansion(newValue)
                    }
            }
        }
    }
    
//    MARK: ViewBuilders
    @ViewBuilder
    private func makeInformationNodes(in geo: GeometryProxy) -> some View {
        ZStack {
            InformationNode(geo: geo,
                            alignment: .topLeading,
                            offset: .init(x: 20 , y: 20),
                            binding: $expanded) {
                Text("\(activePost.title) \(activePost.emoji)")
                    .font(.title3)
                    .bold()
            }

            InformationNode(geo: geo, alignment: .bottomTrailing, offset: .init(x: 0, y: -15), binding: $expanded ) {
                VStack(alignment: .leading) {
                    Text( activePost.notes )
                        .font(.caption)
                        .multilineTextAlignment(.trailing)
                        .lineLimit(4)
                }
                .frame(width: 125)
            }

            InformationNode(geo: geo,
                            alignment: .bottomLeading,
                            offset: .init(x: 20, y: -30),
                            binding: $expanded) {
                Text( "\(activePost.postedDate.formatted(date: .abbreviated, time: .omitted))\n\(activePost.postedDate.formatted(date: .omitted, time: .shortened))" )
                    .font(.callout)
            }
        }
    }
    
    @ViewBuilder
    private func makeSharedWithInformation() -> some View {
        VStack {
            ForEach( ShorterModel.shared.profile!.friendIds, id: \.self ) { id in
            
                if let profile = ShorterProfile.getProfile(for: id) {
                    ProfilePreviewView(profile: profile)
                }
            }
        }
    }
    
//    MARK: CenterWidget
    @State private var nextPostOffset: CGFloat = -300
    @State private var currentPostOffset: CGFloat = 0
    @State private var previousPostOffset: CGFloat = 300
    
    @ViewBuilder
    private func makeCenterWidgetWrapper() -> some View {
        ZStack {
            
            makeCenterWidget( from: previousPost )
                .offset(x: nextPostOffset)
            
            makeCenterWidget( from: activePost )
                .offset(x: currentPostOffset)
                .scaleEffect( 1 - abs(currentPostOffset) / 600 )
            
            makeCenterWidget( from: nextPost )
                .offset(x: previousPostOffset)
        }
        .onChange(of: activePostIndex) { oldValue, newValue in
            let direction: Double = newValue > oldValue ? -1 : 1
            
            currentPostOffset = direction * 300
            withAnimation { currentPostOffset = 0 }
            
            if direction == -1 {
                previousPostOffset = 0
                withAnimation { previousPostOffset = 300 }
            } else {
                nextPostOffset = 0
                withAnimation { nextPostOffset = -300 }
            }
        }
    }
    
    @ViewBuilder
    private func makeCenterWidget(from post: ShorterPost) -> some View {
        Rectangle()
            .aspectRatio(1, contentMode: .fit)
            .overlay {
                post.getImage()
                    .resizable()
                    .scaledToFill()
                    .clipped()
            }
            .clipShape(RoundedRectangle(cornerRadius: Constants.UIDefaultCornerRadius))
            .shadow(color: .black.opacity(0.3), radius: 10, y: 10)
            .onTapGesture { toggleExpansion() }
    }
    
    private let widgetId = "WidgetId"
    private let informationNodeId = "InformationNodeId"
    
//    MARK: Vars
    private func toggleExpansion() {
        withAnimation {
            self.expanded.toggle()
        }
    }
    
    @Namespace var shorterPostCreationViewNameSpace
    
    let posts: [ShorterPost]
    
    private var activePost: ShorterPost { posts[activePostIndex] }
    private var previousPost: ShorterPost { posts[incrementIndex()] }
    private var nextPost: ShorterPost { posts[decrementIndex()] }
    
    @State var activePostIndex: Int = 0
    @State var expanded: Bool = true
    
    private func incrementIndex() -> Int { min(activePostIndex + 1, posts.count - 1) }
    private func decrementIndex() -> Int { max(activePostIndex - 1, 0) }
    
    private var swipeGesture: some Gesture {
        DragGesture(minimumDistance: 20)
            .onEnded { value in
                let direction = value.translation.width / abs( value.translation.width )
                self.activePostIndex = direction == 1 ? incrementIndex() : decrementIndex()
            }
    }
 
//    MARK: RegularLayout
    @ViewBuilder
    private func makeRegularLayout() -> some View {
        VStack(alignment: .leading) {
            HStack {
             
                VStack() {
                    makeCenterWidgetWrapper()
                        .matchedGeometryEffect(id: widgetId, in: shorterPostCreationViewNameSpace)
                        .frame(width: expanded ? LocalConstants.previewSize : LocalConstants.smallPreviewSize)
                        .padding(.vertical)
                    
                    Spacer()
                }
                
                VStack(alignment: .leading) {
//                    makeSharedWithInformation()
                    
                    Spacer()
                }
            }
        }
    }
    
//    MARK: ExpandedLayout
    @ViewBuilder
    private func makeExpandedLayout(in geo: GeometryProxy) -> some View {
        ZStack {
            makeCenterWidgetWrapper()
                .matchedGeometryEffect(id: widgetId, in: shorterPostCreationViewNameSpace)
                .frame(width: expanded ? LocalConstants.previewSize : LocalConstants.smallPreviewSize)
                .offset(y: LocalConstants.previewVerticalOffset)
            
            makeInformationNodes(in: geo)
            
            HStack {
                Image(systemName: "chevron.left")
                    .padding()
                    .onTapGesture { activePostIndex = incrementIndex() }
                    .opacity( activePostIndex < posts.count - 1 ? 1 : 0.5 )
//            }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .padding()
                    .onTapGesture { activePostIndex = decrementIndex() }
                    .opacity( activePostIndex > 0 ? 1 : 0.5 )
            }
        }
        .contentShape(Rectangle())
        .gesture(swipeGesture)
    }
    
    
//    MARK: Body
    var body: some View {
        
        VStack(alignment: .leading, spacing: 0) {
            ZStack(alignment: .topLeading) {
                GeometryReader { geo in
                    ZStack(alignment: .center) {
                        if expanded {
                            makeExpandedLayout(in: geo)
                        } else {
                            makeRegularLayout()
                        }
                    }
                }
                .coordinateSpace(name: ShorterPostQuickCreationView.coordinateSpaceName)
            }
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
        ShorterPostQuickCreationView(posts: posts)
            .frame(height: 400)
            .border(.red)
        
        Spacer()
    }
}
