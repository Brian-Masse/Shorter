//
//  LoadingBlur.swift
//  Shorter
//
//  Created by Brian Masse on 6/25/24.
//

import Foundation
import SwiftUI

//MARK: BurredBackground
struct BlurredBackground: View {
    
    @Environment(\.colorScheme) var colorScheme
    
    struct BlurComponent: View {
        
        let geo: GeometryProxy
        let radius: CGFloat
        
        @State var animating: Bool = true
        @State var horizontalOffset: CGFloat = 0
        @State var verticalOffset: CGFloat = 0
        
        let animationDuration: Double
        
        @Binding var holding: Bool
        let color: Color
        
        private var duration: CGFloat {
            animationDuration * (self.holding ? 0.3 : 1 )
        }
        
        @MainActor
        private func runAnimation() {
            if !animating { return }
            
            let width = Double.random(in: 0...geo.size.width)
            let height = Double.random(in: 0...geo.size.height)
            
            withAnimation( .easeInOut(duration: duration) ) {
                self.horizontalOffset = width
                self.verticalOffset = height
            }
        }
        
        
        var body: some View {
            Circle()
                .offset(x: horizontalOffset - radius,
                        y: verticalOffset - radius)
                .frame(width: radius * 2, height: radius * 2)
                .foregroundStyle(color)
                .saturation(3)
            
                .onChange(of: horizontalOffset, {
                    DispatchQueue.main.asyncAfter(deadline: .now() + duration) {
                        runAnimation()
                    }
                })
            
                .onAppear {
                    let width = Double.random(in: 0...geo.size.width)
                    let height = Double.random(in: 0...geo.size.height)
                    
                    self.horizontalOffset = width
                    self.verticalOffset = height
                    runAnimation()
                }
        }
    }
    
//    MARK: Vars
    @State var holding: Bool = false
    @State var colors: [Color]
    
    private var holdGesture: some Gesture {
        DragGesture(minimumDistance: 0)
            .onChanged { value in self.holding = true }
            .onEnded { value in self.holding = false }
    }
    
//    MARK: Body
    var body: some View {
        
        GeometryReader { geo in
            ZStack(alignment: .topTrailing) {
                ForEach( 0...15, id: \.self ) { i in
                    let radius = Double.random(in: 100...350)
                    let animationDuration = Double.random(in: 3...7)
                    
                    let index = (i % (colors.count))
                    let color = colors[index]
                    
                    BlurComponent(geo: geo,
                                  radius: radius,
                                  animationDuration: animationDuration,
                                  holding: $holding,
                                  color: color)
                }
            }
            .frame(width: geo.size.width, height: geo.size.height)
            .blur(radius: 100)
            .clipShape(Rectangle())
            
            Rectangle()
                .foregroundStyle(.background)
                .opacity(colorScheme == .dark ? 0.8 : 0.7)
            
//            Image("noise")
//                .resizable()
//                .frame(height: geo.size.height)
//                .aspectRatio(contentMode: .fit)
//                .clipped()
//                .blendMode(.overlay)
//                .opacity(0.1)
//                .scaleEffect(1.2)
            
            
        }
        .allowsHitTesting(false)
    }
}
