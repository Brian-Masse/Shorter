//
//  File.swift
//  Shorter
//
//  Created by Brian Masse on 7/1/24.
//

import Foundation
import SwiftUI
import UIUniversals

struct BlockedUsersPage: View {
    
    let blockedUsers: [String]

    @State private var loadingUsers: Bool = true
    
    @State private var showingUnblockAlert: Bool = false

    private let unblockAlertMessage = "You still won't be able to see their old posts, but when they share new content, it will show up on your home feed"
    
//    MARK: BlockedUser
    @ViewBuilder
    private func makeBlockedUserView( profile: ShorterProfile ) -> some View {
        
        HStack {
            Text( profile.fullName )
                .bold()
            
            Spacer()
            
            IconButton("person.badge.plus") { showingUnblockAlert = true }
        }
        .alert("Unblock \(profile.firstName)", isPresented: $showingUnblockAlert) {
            Button("unblock", role: .destructive) {
                Task { await ShorterModel.shared.profile?.unblockUser(profile.ownerId) }
            }
        } message: { Text( unblockAlertMessage ) }

        
    }
    
    
//    MARK: Body
    var body: some View {
        VStack(alignment: .leading) {
            
            Text( "Blocked Users" )
                .font(.title2)
                .bold()
            
            Text( "Blocked Users cannot see your posts or view your profile, including your name, contact information, and profile photo in any search or post. Their posts and contact photo will be hidden." )
                .font(.caption)
                .opacity(Constants.tertiaryTextAlpha)
                .padding(.bottom)
            
            HStack { Spacer() }
            
            if blockedUsers.count == 0 {
                ShorterPlaceHolderView(icon: "person.2.slash", message: "You haven't blocked any users.")
            } else {
                
                if loadingUsers {
                    ProgressView()
                } else {
                    ForEach( blockedUsers ) { id in
                        if let profile = ShorterProfile.getProfile(for: id) {
                            makeBlockedUserView(profile: profile)
                        }
                        
                        Divider()
                            .padding(.bottom, 5)
                    }
                }
            }
            
            Spacer()
        }
        .padding()
        .task {
            await ShorterModel.realmManager.addBlockedUserSubscription()
            self.loadingUsers = false
        }
        .onDisappear { Task {
            self.loadingUsers = true
            await ShorterModel.realmManager.removeBlockedUserSubscription()
            
        } }
    }
}
