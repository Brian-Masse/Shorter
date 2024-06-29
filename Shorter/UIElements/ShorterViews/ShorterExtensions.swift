//
//  ShorterExtensions.swift
//  Shorter
//
//  Created by Brian Masse on 6/27/24.
//

import Foundation
import SwiftUI
import UIUniversals

struct CardWithDepth: ViewModifier {
    
    let shadow: Bool
    
    func body(content: Content) -> some View {
        content
            .shadow(color: .black.opacity(0.2), radius: 0.3, x: 0.5, y: 0.5)
            .shadow(color: .white.opacity(0.2), radius: 0.3, x: -0.5, y: -0.5)
            .shadow(color: .black.opacity(shadow ? 0.1 : 0), radius: 5, y: 2)
    }
}

//MARK: View Extension
extension View {
    func cardWithDepth(shadow: Bool = false) -> some View {
        modifier(CardWithDepth(shadow: shadow))
    }
}

extension Constants {
    
    static var secondaryTextAlpha: Double = 0.75
    static var tertiaryTextAlpha: Double = 0.5
    
    static var subPadding: Double = 7
}


//MARK: ShorterTitle
struct ShorterTitle: View {
    
    let title: String
    let icon: String
    
    init( title: String, icon: String = "" ) {
        self.title = title
        self.icon = icon
    }
    
    var body: some View {
        HStack {
            Text( title )
            
            if !icon.isEmpty {
                Image(systemName: icon)
            }
        }
        .bold()
        .opacity(Constants.tertiaryTextAlpha)
    }
}

//MARK: ShorterHeader
struct ShorterHeader: View {
    
    let icon1: String
    let icon2: String
    
    let title: String
    
    let action1: () -> Void
    let action2: () -> Void
    
    init( leftIcon: String, title: String, rightIcon: String, action1: @escaping () -> Void, action2: @escaping () -> Void ) {
        self.icon1 = leftIcon
        self.icon2 = rightIcon
        self.title = title
        self.action1 = action1
        self.action2 = action2
    }
    
    var body: some View {
        HStack {
         
            IconButton(icon1) { action1() }
            
            Spacer()
            
            ShorterTitle(title: title)
            
            Spacer()
            
            IconButton(icon2) { action2() }
        }
    }
}
