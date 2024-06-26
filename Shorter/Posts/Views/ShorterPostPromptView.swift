//
//  ShorterPostPromptView.swift
//  Shorter
//
//  Created by Brian Masse on 6/26/24.
//

import Foundation
import SwiftUI
import UIUniversals

struct ShorterPostPromptView: View {
    
    @State private var showingCreatPostView: Bool = false
    
//    MARK: Body
    var body: some View {
        
        VStack {
            UniversalButton {
                VStack {
                    Image(systemName: "plus.viewfinder")
                        .font(.title)
                        .padding(.bottom, 7)
                    
                    Text( "Add your status" )
                        .font(.title3)
                        .bold()
                }
                .frame(width: 200, height: 200)
                .rectangularBackground(style: .secondary)
                
            } action: { showingCreatPostView = true }
        }
        .fullScreenCover(isPresented: $showingCreatPostView) {
            ShorterPostCreationView()
        }
        
    }
}

#Preview {
    ShorterPostPromptView()
}
