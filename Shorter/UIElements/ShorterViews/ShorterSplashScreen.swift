//
//  ShorterSplashScreen.swift
//  Shorter
//
//  Created by Brian Masse on 6/25/24.
//

import Foundation
import SwiftUI
import UIUniversals

struct ShorterSplashScreen: View {

    @Environment(\.colorScheme) var colorScheme
    
    @State private var showingStartPage: Bool = false
    
    let firstString: String
    let secondString: String
    let boldString: String
    
    init( _ text: String, highlighting highlighted: String ) {
        let range = text.range(of: highlighted)

        var subString: String = ""
        var subString2: String = ""
        
        if let range = range {
           let index = text.distance(from: text.startIndex, to: range.lowerBound)
           
            subString = String(text[ text.startIndex...text.index(text.startIndex, offsetBy: index - 1) ])
            subString2 = String(text[ text.index(text.startIndex, offsetBy: index + highlighted.count)...text.index(before: text.endIndex) ])
        }
        
        self.firstString = subString
        self.secondString = subString2
        self.boldString = highlighted
    }
    
    var body: some View {
        VStack {
            if showingStartPage {
                VStack {
                    Spacer()
                    
                    Text(firstString)
                        .bold()
                        .font(.largeTitle)
                        .multilineTextAlignment(.center)
                    
                    HStack(spacing: 0) {
                        Text(boldString)
                            .bold()
                            .font(.largeTitle)
                            .foregroundStyle(Colors.getAccent(from: colorScheme))
                            .shadow(color: Colors.getAccent(from: colorScheme).opacity(0.6),
                                    radius: 20 )
                        
                        Text(secondString)
                            .bold()
                            .font(.largeTitle)
                            .multilineTextAlignment(.center)
                    }
                    
                    Spacer()
                }
                .transition( .asymmetric(insertion: .scale, removal: .push(from: .trailing)) )
            }
        }.onAppear { withAnimation { showingStartPage = true } }
        
    }
}
