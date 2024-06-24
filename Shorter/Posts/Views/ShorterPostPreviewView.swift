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
                Text( post.fullTitle + " " + post.emoji )
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
    }
}

struct TestView: View {
    @State private var value: Double = 150
    @State private var test: Bool = false
    
    var body: some View {
        VStack {
            let uiImage = UIImage(named: "BigSur")
            let imageData = PhotoManager.encodeImage(uiImage)
            
            let post = ShorterPost(ownerId: "test",
                                   authorName: "Brian Masse",
                                   fullTitle: "Full Title",
                                   title: "Title",
                                   emoji: "🫡",
                                   notes: "notes",
                                   data: imageData)
            Spacer()
            
            Text("\(value)")
            Slider(value: $value, in: 60...150)
                .padding()
            
            Spacer()
            
            ShorterPostPreviewView(post: post)
            
            Spacer()
        }
    }
}

#Preview {
   TestView()
}

