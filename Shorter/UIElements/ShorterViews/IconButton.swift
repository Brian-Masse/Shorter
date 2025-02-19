//
//  IconButton.swift
//  Shorter
//
//  Created by Brian Masse on 6/23/24.
//

import Foundation
import SwiftUI
import UIUniversals

struct IconButton: View {
    
    @Environment(\.colorScheme) var colorScheme
    
    let title: String
    let icon: String
    let action: () -> Void
    
    init( _ icon: String, title: String = "", action: @escaping () -> Void ) {
        self.icon = icon
        self.title = title
        self.action = action
    }
    
    var body: some View {
        
        Button(action: {
            withAnimation { self.action() }
        }, label: {
            HStack {
                if !title.isEmpty {
                    Text( title )
                }
                Image( systemName: self.icon )
                    .renderingMode(.template)
                    .frame(width: 15, height: 15)
            }
                .foregroundStyle(Colors.getAccent(from: colorScheme))
                .padding(10)
                .background( .ultraThinMaterial )
                .clipShape(RoundedRectangle(cornerRadius: 100))
            
                .cardWithDepth(shadow: true)
            
                .tint(.blue)
        }).buttonStyle(PlainButtonStyle())
    }
}

#Preview {
    IconButton("arrow.forward") {
        print( "hello world" )
    }
}
