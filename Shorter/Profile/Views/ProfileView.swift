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
    
    let profile: ShorterProfile
    
    @State private var showingProfileEdittingView: Bool = false
    
//    MARK: Header
    @ViewBuilder
    private func makeHeader() -> some View {
        
        HStack {
            IconButton("chevron.down") {
                dismiss()
            }
            
            Spacer()
            
            Text( "Profile" )
                .bold()
                .opacity(0.5)
            
            Spacer()
            
            IconButton("pencil") {
                showingProfileEdittingView = true
            }
        }
    }
    
//    MARK: ProfileImage
    @ViewBuilder
    private func makeProfileImage() -> some View {
        VStack {
            
            HStack {  Spacer() }
            
            profile.getImage()
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 150, height: 150)
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
            Text( "Contact" )
                .font(.callout)
                .bold()
                .padding(.leading)
            
            VStack {
                makeContactNode(title: "email", content: profile.email)
                makeContactNode(title: "phone number", content: profile.phoneNumber.formatIntoPhoneNumber())
            }
            .padding(.horizontal, 7)
            .rectangularBackground(style: .transparent)
        }
    }
    
//    MARK: Social Page
    @ViewBuilder
    private func makeSocialPage() -> some View {
        VStack(alignment: .leading) {
            
            Text( "Friends" )
                .font(.callout)
                .bold()
                .padding(.leading)
            
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
    
//    MARK: Signout Button
    @ViewBuilder
    private func makeProfileButton(icon: String, label: String, action: @escaping () -> Void) -> some View {
        UniversalButton {
            HStack {
                Spacer()
                Text(label)
                Image(systemName: icon)
                Spacer()
            }
            .rectangularBackground(style: .secondary)
            
        } action: { action() }
    }
    
    @ViewBuilder
    private func makeButtons() -> some View {
        VStack(alignment: .leading) {
            Text( "Profile Modification" )
                .font(.callout)
                .bold()
                .padding(.leading)
            
            makeProfileButton(icon: "ipad.and.arrow.forward", label: "sign out") {
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
            
            ScrollView(.vertical) {
                makeContactSection()
                    .padding(.bottom)
                
                makeSocialPage()
                    .padding(.bottom)
                
                Divider()
                
                makeButtons()
                    .padding(.bottom, 30)
                
                Text( ShorterModel.ownerId )
                    .font(.caption2)
                    .opacity(0.7)
                
            }.clipShape(RoundedRectangle(cornerRadius: Constants.UIDefaultCornerRadius))
            
            Spacer()
        }
        .padding()
        .sheet(isPresented: $showingProfileEdittingView) {
            ProfileEdittingView(profile: profile)
        }
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
