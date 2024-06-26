//
//  MainView.swift
//  Shorter
//
//  Created by Brian Masse on 6/21/24.
//

import Foundation
import SwiftUI
import RealmSwift
import WidgetKit
import UIUniversals

//MARK: MainView
struct MainView: View {
    
    @State private var showingCreatePostView: Bool = false
    
    @ObservedResults( ShorterPost.self ) var posts
    
//    MARK: Body
    var body: some View {
        ZStack(alignment: .top) {
            Text( "Shorter" )
                .font(.title2)
                .bold()
                .padding(.top, 7)
            
            ShorterPostsView(posts: Array( posts ))
            
        }
        .emojiPresenter()
        .task {
            await NotificationManager.shared.loadStatus()
        }
    }
}

#Preview {
    MainView()
        .padding()
}
