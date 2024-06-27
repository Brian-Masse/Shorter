//
//  CardTemplateView.swift
//  ScrollingCardsDemo
//
//  Created by Brian Masse on 5/27/24.
//

import Foundation
import SwiftUI

//  MARK: Constants
struct LocalConstants {
    static let smallHeight: CGFloat = 60
    static let spacing: CGFloat = 10
}

//MARK: CardTemplate
struct ScrollingCardWrapper<Content: View>: View {
    
    let height: CGFloat
    let index: Int
    
    let content: (Binding<Bool>) -> Content
    
    @Binding var scrollPosition: CGFloat
    
    @State var showingFullCard = true
    @State var scaleModifier: CGFloat = 0
    @State var scale: CGFloat = 1
    @State var alpha: CGFloat = 1
    
    init( height: CGFloat, index: Int, scrollPosition: Binding<CGFloat>, content: @escaping (Binding<Bool>) -> Content ) {
        self.height = height
        self.index = index
        self._scrollPosition = scrollPosition
        self.content = content
    }
    
//    MARK: Struct Methods
    private func makeScale(in geo: GeometryProxy) {
        let invertedDistance = -distanceFromStart(in: geo)
        
        if checkOutOfScrollViewBounds(in: geo) {
            let input = (1/500) * -invertedDistance
            withAnimation {
                self.alpha = 1 + (input * 2)
            }
            self.scale = 1 + (input)
        } else {
            withAnimation {
                self.scale = 1
                self.alpha = 1
            }
        }
    }
    
    private func checkHalfContentToggle(in geo: GeometryProxy) {
        let distance = distanceFromStart(in: geo)
        
        if -distance > height * 0.55 {
            withAnimation { if showingFullCard { showingFullCard = false }}
        } else {
            withAnimation { if !showingFullCard { showingFullCard = true }}
        }
    }
    
    private func distanceFromStart(in geo: GeometryProxy) -> CGFloat {
        geo.frame(in: .named("scroll")).minY
    }
    
    private func checkOutOfScrollViewBounds(in geo: GeometryProxy) -> Bool {
        distanceFromStart(in: geo) <= 0 && distanceFromStart(in: geo) > -height * 2
    }
    
    private func makeHeight(in geo: GeometryProxy) -> CGFloat {
        let proposedHeight = height + distanceFromStart(in: geo)
        let height = min(max(proposedHeight, LocalConstants.smallHeight), height)

        
        return height
    }
    
    private func makeOffset(in geo: GeometryProxy) -> CGFloat {
        let selfOutOfView = checkOutOfScrollViewBounds(in: geo)
        
        if selfOutOfView {
            return -distanceFromStart(in: geo)
        } else {
            return 0
        }
    }
    
//    MARK: Body
    var body: some View {
        GeometryReader { geo in
            let height = makeHeight(in: geo)
            self.content( $showingFullCard )
                .frame(height: height)
                .shadow(color: .black.opacity(0.5), radius: 0.3, x: 0.5, y: 0.5)
                .shadow(color: .white.opacity(0.2), radius: 0.3, x: -1, y: -1)
            
                .animation( .easeInOut(duration: 0.2), value: scaleModifier)
            
                .onAppear { makeScale(in: geo) }
                .onChange(of: scrollPosition) {
                    makeScale(in: geo)
                    checkHalfContentToggle(in: geo)
                }
                .offset(y: makeOffset(in: geo))
                .scaleEffect( scale + scaleModifier, anchor: .bottom )
                .padding(1)
        }
        .frame(height: height)
        .opacity(alpha)
    }
}
