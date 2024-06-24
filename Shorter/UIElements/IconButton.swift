//
//  IconButton.swift
//  Shorter
//
//  Created by Brian Masse on 6/23/24.
//

import Foundation
import SwiftUI

struct IconButton: View {
    
    let icon: String
    let action: () -> Void
    
    init( _ icon: String, action: @escaping () -> Void ) {
        self.icon = icon
        self.action = action
    }
    
    var body: some View {
        
        Button(action: {
            withAnimation { self.action() }
        }, label: {
            Image( systemName: self.icon )
                .renderingMode(.none)
                .padding(10)
                .background( .ultraThinMaterial )
                .clipShape(Circle())
            
                .shadow(color: .black.opacity(0.3), radius: 0.3, x: 0.5, y: 0.5)
                .shadow(color: .white.opacity(0.3), radius: 0.3, x: -0.5, y: -0.5)
                .shadow(color: .black.opacity(0.1), radius: 5, y: 2)
            
                .tint(.blue)
        }).buttonStyle(.plain)
    }
}

#Preview {
    IconButton("pencil") {
        print( "hello world" )
    }
}
