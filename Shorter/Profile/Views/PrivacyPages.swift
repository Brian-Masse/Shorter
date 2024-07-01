//
//  File.swift
//  Shorter
//
//  Created by Brian Masse on 7/1/24.
//

import Foundation
import SwiftUI
import RealmSwift
import UIUniversals

struct PrivacyPageHeader: View {
    
    let title: String
    let message: String
    
    var body: some View {
        VStack(alignment: .leading) {
            Text( title )
                .font(.title2)
                .bold()
            
            Text( message )
                .font(.caption)
                .opacity(Constants.tertiaryTextAlpha)
                .padding(.bottom)
        }
    }
}

//MARK: BlockedUserPage
struct BlockedUsersPage: View {
    
    let blockedUsers: [String]

    @State private var loadingUsers: Bool = true
    
    @State private var showingUnblockAlert: Bool = false

    private let unblockAlertMessage = "You still won't be able to see their old posts, but when they share new content, it will show up on your home feed"
    
//    MARK: BlockedUser
    @MainActor
    @ViewBuilder
    private func makeBlockedUserView( profile: ShorterProfile ) -> some View {
        
        HStack {
            Text( profile.fullName )
                .bold()
            
            Spacer()
            
            IconButton("person.slash") { showingUnblockAlert = true }
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
            
            PrivacyPageHeader(title: "Blocked Users",
                              message: "Blocked Users cannot see your posts or view your profile, including your name, contact information, and profile photo in any search or post. Their posts and contact photo will be hidden.")
            
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
                            
                            Divider()
                                .padding(.bottom, 5)
                        }
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

//MARK: HiddenPostsPage
@MainActor
struct HiddenPostsPage: View {
    
    @Environment(\.colorScheme) var colorScheme
    
    let hiddenPosts: [ObjectId]
    
    @State private var showingUnHidePostAlert: Bool = false
    private let unhideAlertTitle = "unhind post?"
    private let unhideAlertMessage = "This post will be visible on your home screen. You can hide it again any time."
    
    @State private var postId: ObjectId? = nil
    @State private var allowsMatureContent: Bool = ShorterModel.shared.profile!.allowsMatureContent
    
    @MainActor
    private func unHidePost() async {
        ShorterModel.shared.profile?.hidePost(postId!, toggle: true)
        
        let posts: [ShorterPost] = RealmManager.retrieveObjects()
        await ShorterPostsPageViewModel.shared.getSharedWithMePosts(from: posts)
    }
    
    @ViewBuilder
    private func makeMatureContentToggle() -> some View {
        HStack {
            Image(systemName: "hand.raised")
            Text( "Hide Mature Content" )
            
            Spacer()
            
            Toggle("", isOn: $allowsMatureContent)
                .tint(Colors.getAccent(from: colorScheme))
        }
        .rectangularBackground(style: .secondary)
        .onChange(of: allowsMatureContent) { Task {
            await ShorterModel.shared.profile?.toggleMatureContent()
        } }
    }
    
//    MARK: HiddenPost
    @MainActor
    @ViewBuilder
    private func makeHiddenPost( _ post: ShorterPost ) -> some View {
        HStack {
            VStack(alignment: .leading) {
                Text( "post from \(post.ownerName)" )
                    .bold()
                Text( "shared on \(post.postedDate.formatted(date: .abbreviated, time: .omitted))" )
                    .font(.callout)
                    .opacity(Constants.tertiaryTextAlpha)
            }
            
            Spacer()
            
            IconButton("square.slash") { showingUnHidePostAlert = true }
        }
        .alert(unhideAlertTitle, isPresented: $showingUnHidePostAlert) {
            
            Button("unhide") { Task {
                postId = post._id
                await unHidePost()
            } } 
            
        } message: { Text( unhideAlertMessage ) }

    }
    
    
    var body: some View {
        VStack(alignment: .leading) {
            
            PrivacyPageHeader(title: "Hidden Posts",
                              message: "Hidden posts cannot be seen on your home feed. Additionally, you can choose to filter out posts marked with mature content")
            
            makeMatureContentToggle()
            Text( "Choose whether you want to view posts marked with sensitive content on your homescreen" )
                .font(.caption)
                .padding(.leading, Constants.subPadding)
                .opacity(Constants.tertiaryTextAlpha)
                .padding(.bottom)
            
            
            if hiddenPosts.count == 0 {
                ShorterPlaceHolderView(icon: "square.slash", message: "You haven't hidden any posts")
            } else {
                
                ForEach( hiddenPosts, id: \.self ) { id in
                    if let post = ShorterPost.getPost(from: id) {
                        
                        makeHiddenPost(post)
                        
                        Divider()
                            .padding(.bottom, 5)
                    } else {
                        ProgressView()
                            .task {
                                postId = id
                                await unHidePost()
                            }
                    }
                }
            }
            
            Spacer()
        }
        .padding()
    }
}


//MARK: Privacy Report

struct PrivacyReport: View {
    
//    MARK: Privacy Section
    @ViewBuilder
    private func makePrivacySection<C: View>(icon: String, title: String, message: String, content: () -> C = { EmptyView() } ) -> some View {
        
        HStack {
            Spacer()
            
            VStack {
                VStack {
                    Image(systemName: icon)
                    Text( title )
                }
                .font(.title2)
                .bold()
                
                Text(message)
                    .multilineTextAlignment(.center)
                    .font(.callout)
                    .opacity(Constants.secondaryTextAlpha)
                
                content()
                    .padding(.top)
            }
            
            Spacer()
        }
        .rectangularBackground(style: .transparent)
        .cardWithDepth()
        .padding(.bottom)
    }
    
    
    @ViewBuilder
    private func makeSummaryNode(icon: String, message: String) -> some View {
        HStack {
            Image(systemName: icon)
                
            
            Text( message )
                .lineLimit(2)
        }
        .font(.callout)
        .bold()
        .padding(.horizontal)
    }
    
    @ViewBuilder
    private func makeSummaryList( icon1: String, _ msg1: String,
                                  icon2: String = "", _ msg2: String = "",
                                  icon3: String, _ msg3: String,
                                  icon4: String = "", _ msg4: String = "" ) -> some View {
        
        HStack {
            VStack {
               makeSummaryNode(icon: icon1, message: msg1)
                if !icon2.isEmpty {
                    makeSummaryNode(icon: icon2, message: msg2)
                }
            }
            
            Spacer()
            
            VStack {
                makeSummaryNode(icon: icon3, message: msg3)
                if !icon4.isEmpty {
                    makeSummaryNode(icon: icon4, message: msg4)
                }
            }
        }
        
    }
    
//    MARK: Body
    var body: some View {
        
        VStack(alignment: .leading) {
            Text("Shorter Privacy Summary")
                .font(.title)
                .bold()
            
            Text( "By using Shorter, you agree to the privacy policies stated [here](https://s3.us-east-2.amazonaws.com/www.recallprivacynotice.com/ShorterPrivacyPolicy.html)." )
                .font(.callout)
                .opacity(Constants.tertiaryTextAlpha)
                .padding(.bottom)
            
            ScrollView(.vertical, showsIndicators: false) {
                makePrivacySection(icon: "macpro.gen3.server",
                                   title: "Data Collection",
                                   message: "Shorter will never sell, distribute, manipulate or falsify your data. All stored data is explicitly created by the user.") {
                    
                    makeSummaryList(icon1: "info.circle", "full name",
                                    icon3: "phone", "contact info")
                }
                
                makePrivacySection(icon: "hand.raised",
                                   title: "Safety",
                                   message: "Shorter gives user the ability to filter the content they see.")  {
                    
                    makeSummaryList(icon1: "person.slash", "block users",
                                    icon2: "exclamationmark.shield", "report posts",
                                    icon3: "figure.and.child.holdinghands", "filter mature content",
                                    icon4: "square.slash", "hide posts")
                }
                
                makePrivacySection(icon: "chart.line.uptrend.xyaxis",
                                   title: "analytics",
                                   message: "Shorter does not collect any analytic data on its users. It is privatley owned and maintained.")
                
                makePrivacySection(icon: "exclamationmark.triangle",
                                   title: "Abusive content",
                                   message: "Shorter does not tolerate any abusive content, including hate speech, pornography, or violence.")
                    .foregroundStyle(.red)
                    .padding(.bottom)
            }

            HStack { Spacer() }
            
            Spacer()

        }
    }
}


#Preview {
    PrivacyReport()
}
