//
//  ShorterExtensions.swift
//  Shorter
//
//  Created by Brian Masse on 6/27/24.
//

import Foundation
import SwiftUI

struct CardWithDepth: ViewModifier {
    
    let shadow: Bool
    
    func body(content: Content) -> some View {
        content
            .shadow(color: .black.opacity(0.2), radius: 0.3, x: 0.5, y: 0.5)
            .shadow(color: .white.opacity(0.2), radius: 0.3, x: -0.5, y: -0.5)
            .shadow(color: .black.opacity(shadow ? 0.1 : 0), radius: 5, y: 2)
    }
}

extension View {
    
    func cardWithDepth(shadow: Bool = false) -> some View {
        modifier(CardWithDepth(shadow: shadow))
    }
    
}
