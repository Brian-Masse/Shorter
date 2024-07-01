//
//  ProfileView.swift
//  Shorter
//
//  Created by Brian Masse on 6/26/24.
//

import Foundation
import SwiftUI
import UIUniversals

struct ProfileView: View {
    
//    MARK: Vars
    @Environment(\.dismiss) var dismiss
    @Environment(\.colorScheme) var colorScheme
    
    @Namespace var profileNameSpace
    private let iconId: String = "iconID"
    
    let profile: ShorterProfile
    
    @State private var showingProfileEdittingView: Bool = false
    @State private var showingPostCreationView: Bool = false
    
    @State private var showingBlockedUsersView: Bool = false
    @State private var showingHiddenPostsView: Bool = false
    @State private var showingPrivacySummary: Bool = false
    
    @State private var activeIcon: String = UIApplication.shared.alternateIconName ?? "icon-dark"
    
//    MARK: Header
    @ViewBuilder
    private func makeHeader() -> some View {
        
        ShorterHeader(leftIcon: "chevron.down", title: "Profile", rightIcon: "pencil") {
            dismiss()
        } action2: {
            showingProfileEdittingView = true
        }
    }
    
    @ViewBuilder
    private func makeSectionLabel( icon: String, title: String ) -> some View {
        HStack {
            Image(systemName: icon)
            Text( title )
        }
        .font(.callout)
        .bold()
        .padding(.leading)
    }
    
//    MARK: ProfileImage
    @ViewBuilder
    private func makeProfileImage() -> some View {
        VStack {
            
            HStack {  Spacer() }
            
            profile.getImage()
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 112, height: 112)
                .clipShape(Circle())
                .background {
                    profile.getImage()
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: 350, height: 250)
                        .clipShape(Circle())
                        .blur(radius: 120)
                }
                .allowsTightening(false)
                .contentShape(Rectangle())
            
            Text( profile.fullName )
                .font(.largeTitle)
                .bold()
            
            Text( "Shorter User Since \(profile.dateJoined.formatted(date: .abbreviated, time: .omitted))" )
                .opacity(0.65)
        }
    }
    
//    MARK: Contact Information
    @ViewBuilder
    private func makeContactNode( title: String, content: String ) -> some View {
        HStack {
            Text( title )
                .font(.title3)
                .bold()
            
            Spacer()
            
            Text(content)
                .font(.callout)
                .opacity(0.7)
        }
    }
    
    @ViewBuilder
    private func makeContactSection() -> some View {
        VStack(alignment: .leading) {
            makeSectionLabel(icon: "phone", title: "Contact")
            
            VStack {
                makeContactNode(title: "email", content: profile.email)
                makeContactNode(title: "phone number", content: profile.phoneNumber.formatIntoPhoneNumber())
            }
            .padding(.horizontal, 7)
            .rectangularBackground(style: .transparent)
            .cardWithDepth()
        }
    }
    
//    MARK: Social Page
    @ViewBuilder
    private func makeSocialPage() -> some View {
        VStack(alignment: .leading) {
            makeSectionLabel(icon: "person.2", title: "Friends")
            
            FriendList(profile: profile)
        }
    }
    
//    MARK: Icon
    @ViewBuilder
    private func makeIconSwitcherButton(icon: String) -> some View {
        Image(icon)
            .resizable()
            .aspectRatio(contentMode: .fill)
            .frame(width: 65)
            .clipShape(RoundedRectangle(cornerRadius: Constants.UIDefaultCornerRadius))
            .cardWithDepth()
        
            .padding()
            .background {
                if icon == activeIcon {
                    RoundedRectangle(cornerRadius: Constants.UILargeTextSize)
                        .foregroundStyle(Colors.getAccent(from: colorScheme))
                        .matchedGeometryEffect(id: iconId,
                                               in: profileNameSpace)
                }
            }
        
            .padding(Constants.subPadding)
        
            .onTapGesture {
                withAnimation { self.activeIcon = icon }
                UIApplication.shared.setAlternateIconName(icon) { error in
                    if let err = error { print( err.localizedDescription ) }
                }
            }
    }
    
    @ViewBuilder
    private func makeIconSwitcher() -> some View {
        VStack(alignment: .leading) {
            makeSectionLabel(icon: "square.grid.3x3.square", title: "Preferences")
        
            HStack {
                Spacer()
                
                makeIconSwitcherButton(icon: "icon-dark")
                makeIconSwitcherButton(icon: "icon-light")
                
                Spacer()
            }
            .rectangularBackground(style: .transparent)
            .cardWithDepth()
        }
    }
    
//    MARK: Privacy
    @ViewBuilder
    private func makePrivacySection() -> some View {
        VStack(alignment: .leading) {
            
            makeSectionLabel(icon: "hand.raised", title: "Privacy")
            
            Text( "All User Data stored on our servers is explicitly user generated, and does not leave our servers for any tracking, advertising, or 3rd party reason." )
                .font(.caption)
                .opacity(Constants.tertiaryTextAlpha)
                .padding(.horizontal)
            
            makeProfileButton(icon: "newspaper", label: "Full Privacy Summary") {
                showingPrivacySummary = true
            }
            
            makeProfileButton(icon: "person.2.slash", label: "Blocked users") {
                showingBlockedUsersView = true
            }
            
            makeProfileButton(icon: "square.slash", label: "Hidden posts") {
                showingHiddenPostsView = true
            }
        }
    }
    
//    MARK: Signout Button
    @ViewBuilder
    private func makeProfileButton(icon: String, label: String, style: UniversalStyle = .secondary, action: @escaping () -> Void) -> some View {
        UniversalButton {
            HStack {
                Spacer()
                Text(label)
                Image(systemName: icon)
                Spacer()
            }
            .rectangularBackground(style: style)
            .if(style == .accent && colorScheme == .light) { view in view.foregroundStyle(.white) }
            
        } action: { action() }
    }
    
    @ViewBuilder
    private func makeButtons() -> some View {
        VStack(alignment: .leading) {
            Text( "Profile Modification" )
                .font(.callout)
                .bold()
                .padding(.leading)
            
            makeProfileButton(icon: "ipad.and.arrow.forward", label: "sign out", style: .accent) {
                Task { await ShorterModel.realmManager.logoutUser() }
            }
            makeProfileButton(icon: "macpro.gen3.server", label: "delete accont") {
                Task { await ShorterModel.realmManager.logoutUser() }
            }
            .foregroundStyle(.red)
        }
    }
    
    
//    MARK: Body
    var body: some View {
        
        VStack {
            makeHeader()
            
            makeProfileImage()
                .padding(.bottom)
            
            ScrollView(.vertical, showsIndicators: false) {
                makeContactSection()
                    .padding(.bottom)
                
                makeSocialPage()
                    .padding(.bottom)
                
                makeIconSwitcher()
                    .padding(.bottom)
                
                makePrivacySection()
                    .padding(.bottom)
                
                Divider()
                    .padding(.bottom, 30)
                
                makeButtons()
                    .padding(.bottom, 30)
                
                Text( ShorterModel.ownerId )
                    .font(.caption2)
                    .opacity(0.7)
                    .padding(.bottom)
                    .onTapGesture {
                        print( ShorterModel.ownerId )
                        NotificationManager.shared.readFiringDates()
                        
                        showingPostCreationView = true
                    }
                
            }.clipShape(RoundedRectangle(cornerRadius: Constants.UIDefaultCornerRadius))
            
            Spacer()
        }
        .padding([.top, .horizontal])
        .ignoresSafeArea(edges: .bottom)
        .sheet(isPresented: $showingProfileEdittingView) {
            ProfileEdittingView(profile: profile)
        }
        .sheet(isPresented: $showingPostCreationView, content: {
            ShorterPostCreationView()
        })
        .sheet(isPresented: $showingBlockedUsersView, content: {
            BlockedUsersPage(blockedUsers: Array(ShorterModel.shared.profile!.blockedIds))
        })
        .sheet(isPresented: $showingHiddenPostsView, content: {
            HiddenPostsPage(hiddenPosts: Array( ShorterModel.shared.profile!.hiddenPosts ))
        })
    }
}

#Preview {
    let uiImage = UIImage(named: "BigSur")
    let imageData = PhotoManager.encodeImage(uiImage)
    
    let profile = ShorterProfile(ownerId: "test", email: "brianm25it@gmail.com")
    profile.firstName = "Brian"
    profile.lastName = "Masse"
    profile.phoneNumber = 17813153811
    profile.imageData = imageData
    
    return ProfileView(profile: profile)
}
