//
//  StyledScrollView.swift
//  ScrollingCardsDemo
//
//  Created by Brian Masse on 5/26/24.
//

import Foundation
import SwiftUI
import UIUniversals

//MARK: StyledScrollView
struct StyledScrollView<C: View, T: Identifiable>: View{
    
    let height: CGFloat
    let cards: [T]
    
    @ViewBuilder var contentBuilder: (T, Binding<Bool>) -> C
    
    init( height: CGFloat, cards: [T], contentBuilder: @escaping (T, Binding<Bool>) -> C ) {
        self.height = height
        self.cards = cards
        self.contentBuilder = contentBuilder
    }
    
    let coordinateSpaceName = "scroll"
    
    @State var scrollPosition: CGPoint = .zero
    
    var body: some View {
        VStack {
            GeometryReader { geo in
                ScrollView(showsIndicators: false) {
                    VStack(spacing: LocalConstants.spacing) {
                        ForEach( cards.indices, id: \.self ) { i in
                            let card = cards[i]

                            ScrollingCardWrapper(height: height, index: i, scrollPosition: $scrollPosition.y) { showingFullCard in
                                contentBuilder( card, showingFullCard )
                            }
                        }
                        
                        Rectangle()
                            .foregroundStyle(.clear)
                            .frame(height: 50)
                    }
                    
                    .background(GeometryReader { geo in
                        Color.clear
                            .preference(key: ScrollOffsetPreferenceKey.self,
                                        value: geo.frame(in: .named(coordinateSpaceName)).origin)
                    })
                    .onPreferenceChange(ScrollOffsetPreferenceKey.self) { value in
                        self.scrollPosition = value
                    }
                }
                .coordinateSpace(name: coordinateSpaceName)
                .clipShape( RoundedRectangle(cornerRadius: Constants.UIDefaultCornerRadius) )
            }
        }
    }
}

//MARK: PreferenceKey
private struct ScrollOffsetPreferenceKey: PreferenceKey {
    
    static var defaultValue: CGPoint = .zero
    
    static func reduce(value: inout CGPoint, nextValue: () -> CGPoint) { }
}

