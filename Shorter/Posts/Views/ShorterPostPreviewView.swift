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
    
    static var height: CGFloat { LocalConstants.cardHeigt }
    
    private var formattedCaption: String {
        "\(post.ownerName) on \( post.postedDate.formatted(date: .abbreviated, time: .omitted) )"
    }
    
    @State private var showingFullScreen: Bool = false
    
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
        
            .sheet(isPresented: $showingFullScreen) {
                ShorterPostView(post: post)
            }
    }
}

