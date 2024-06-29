//
//  SocialPageView.swift
//  Shorter
//
//  Created by Brian Masse on 6/27/24.
//

import Foundation
import SwiftUI
import UIUniversals

struct FriendList: View {
    
    @ObservedObject var profile: ShorterProfile
    
    var body: some View {
        VStack(alignment: .leading) {
            if !profile.isInvalidated {
                if profile.friendIds.count > 0 {
                    ForEach( profile.friendIds ) { id in
                        
                        if let profile = ShorterProfile.getProfile(for: id) {
                            ProfilePreviewView(profile: profile)
                        }
                    }
                } else {
                    ShorterPlaceHolderView(icon: "person.line.dotted.person",
                                           message: "Connect with friends on Shortes")
                }
            }
        }
    }
}

struct SocialPageView: View {
    
    @Environment(\.dismiss) var dismiss
    
    @State private var showingProfileView: Bool = false
    
    @ObservedObject var profile = ShorterModel.shared.profile!
    
//    MARK: Body
    var body: some View {
        GeometryReader { geo in
            VStack(alignment: .leading) {
                
                ShorterHeader(leftIcon: "chevron.down", title: "Social", rightIcon: "person", action1: {
                    dismiss()
                }, action2: { showingProfileView = true })
                    .padding(.bottom)
                
                ScrollView(.vertical, showsIndicators: false) {
                    VStack(alignment: .leading) {
                        SearchView(directlyAddFriends: true)
                            .padding(.vertical)
                        
                        Text( "My Friends" )
                            .font(.title3)
                            .bold()
                        
                        FriendList( profile: profile )
                    }
                    .clipShape(RoundedRectangle(cornerRadius: Constants.UIDefaultCornerRadius ))
                    .padding(.bottom, Constants.subPadding)
                    
                    Spacer()
                }
            }
        }
        .ignoresSafeArea(edges: .bottom)
        .padding([.top, .horizontal])
        .sheet(isPresented: $showingProfileView, content: {
            ProfileView(profile: ShorterModel.shared.profile!)
        })
    }
}
