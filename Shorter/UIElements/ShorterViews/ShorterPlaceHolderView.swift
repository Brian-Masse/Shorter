//
//  ShorterPlaceHolderView.swift
//  Shorter
//
//  Created by Brian Masse on 6/26/24.
//

import Foundation
import SwiftUI
import UIUniversals

struct ShorterPlaceHolderView: View {
    
    let icon: String
    let message: String
    
    var body: some View {
        
        VStack {
           
            Image(systemName: icon)
                .font(.title)
                .padding(.bottom, 7)
            
            Text( message )
                .font(.headline)
                .padding(.horizontal, 40)
                .multilineTextAlignment(.center)
            
            HStack { Spacer() }
        }
        .opacity(0.8)
        .rectangularBackground(style: .transparent)
    }
}

#Preview {
    ShorterPlaceHolderView(icon: "plus.viewfinder", message: "This is a great test of a place holder view")
}
