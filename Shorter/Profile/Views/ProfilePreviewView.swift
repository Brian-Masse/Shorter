//
//  ProfilePreviewView.swift
//  Shorter
//
//  Created by Brian Masse on 6/23/24.
//

import Foundation
import SwiftUI
import UIUniversals

struct ProfilePreviewView: View{
    
    struct LocalConstants {
        static let deleteHandleSize: CGFloat = 200
        static let deleteHandleOverflow: CGFloat = 100
        static let deleteHandleThreshold: CGFloat = 50
        
        static let profileBlur: CGFloat = 200
        static let previewHeight: CGFloat = 100
    }
    
//    MARK: Vars
    
    let profile: ShorterProfile
    
    private let removeFriendTitle: String = "Remove Friend?"
    private let removeFriendMessage: String = "You won't be able to see any of their older posts, even when you re-add them"
    
    private let blockFriendTitle: String = "Block User?"
    private let blockFriendMessage: String = "You won't be able to see thier posts, and they won't show up in any searchs. This can be undone later in settings"
    
    private let reportAndBlockTitle: String = "Report This User?"
    private let reportAndBlockMessage: String = "If this user has generated innapropriate content, please let us know and we'll investigate it within 24 hours to keep Shorter safe."
    
    @State private var showingRemoveFriendAlert: Bool = false
    @State private var showingBlockFriendAlert: Bool = false
    @State private var showingReportAndBlockFriendAlert: Bool = false
    
    @State private var previousOffset: CGFloat = 0
    @State private var offset: CGFloat = 0
    
//    MARK: Drag Gesture
    private var dragGesture: some Gesture {
        DragGesture()
            .onChanged { value in
                if value.translation.width < 0 {
                    offset = previousOffset +
                    max(-LocalConstants.deleteHandleSize - LocalConstants.deleteHandleOverflow,
                         min(value.translation.width, 0))
                    
                } else if previousOffset == LocalConstants.deleteHandleSize {
                    offset = -LocalConstants.deleteHandleSize -
                    min( 0, max(-value.translation.width, -LocalConstants.deleteHandleSize))
                }
            }
            .onEnded { value in
                if value.translation.width < -LocalConstants.deleteHandleThreshold {
                    withAnimation { self.offset = -LocalConstants.deleteHandleSize }
                } else {
                    withAnimation { self.offset = 0 }
                }
                
                self.previousOffset = offset
            }
    }
    
//    MARK: DeleteHandle
    @MainActor
    @ViewBuilder
    private func makeDeleteHandle() -> some View {
        UniversalButton {
            ZStack {
                Rectangle()
                    .foregroundStyle(.red)
                
                VStack {
                    Image(systemName: "person.badge.minus")
                        .font(.title)
                    
                    Text( "Remove Friend" )
                        .font(.callout)
                        .bold()
                }
                .foregroundStyle(.black)
            }
            
        } action: {
            showingRemoveFriendAlert = true
        }
    }
    
//    MARK: Content
    @MainActor
    @ViewBuilder
    private func makeContent() -> some View {
        GeometryReader { geo in
            HStack {
                HStack {
                    profile.getImage()
                        .resizable()
                        .aspectRatio(1, contentMode: .fit)
                        .clipShape(Circle())
                        .background {
                            profile.getImage()
                                .resizable()
                                .aspectRatio(1, contentMode: .fill)
                                .frame(width: LocalConstants.profileBlur)
                                .blur(radius: 70)
                                .opacity(0.3)
                        }
                    
                    
                    VStack(alignment: .leading) {
                        Text( profile.fullName )
                            .font(.title3)
                            .bold()
                        
                        Text( profile.phoneNumber.formatIntoPhoneNumber() )
                            .font(.caption)
                        
                        Spacer()
                    }
                    .padding(.horizontal)
                    
                    Spacer()
                }
                .padding()
                .padding(.trailing, 7)
                .frame(width: geo.size.width)
            }
        }
        .background(.ultraThinMaterial)
        .offset(x: offset)
        .gesture(dragGesture)
    }
    
//    MARK: Body
    var body: some View {
        
        Rectangle()
            .foregroundStyle(.clear)
            .frame(height: LocalConstants.previewHeight)
            
            .overlay {
                makeContent()
            }
    
            .clipShape(RoundedRectangle(cornerRadius: Constants.UIDefaultCornerRadius))
            .cardWithDepth()
            .contextMenu(ContextMenu(menuItems: {
                Button( "remove friend", systemImage: "person.badge.minus" ) {
                    showingRemoveFriendAlert = true
                }
                
                Button("block", systemImage: "person.slash", role: .destructive) {
                    showingBlockFriendAlert = true
                }
                
                Button( "report and block", systemImage: "exclamationmark.shield", role: .destructive ) {
                    showingReportAndBlockFriendAlert = true
                }
            }))
        
            .alert(removeFriendTitle,
                   isPresented: $showingRemoveFriendAlert) {
                
                Button("remove", role: .destructive) {
                    let id = profile.ownerId
                    Task { await ShorterModel.shared.profile?.removeFriend( id ) }
                }
                
            } message: { Text( removeFriendMessage ) }
        
            .alert(blockFriendTitle, isPresented: $showingBlockFriendAlert) {
                Button("block", role: .destructive) {
                    Task { await ShorterModel.shared.profile?.blockUser( profile.ownerId, toggle: false ) }
                }
            } message: { Text( blockFriendMessage ) }

            .alert(reportAndBlockTitle, isPresented: $showingReportAndBlockFriendAlert) {
                Button("report and block", role: .destructive) {
                    Task {
                        await ShorterModel.shared.profile?.blockUser( profile.ownerId, toggle: false)
                    }
                }
                
            } message: { Text( reportAndBlockMessage ) }
    }
}

#Preview {
    
    let uiImage = UIImage(named: "BigSur")
    let imageData = PhotoManager.encodeImage(uiImage)
    
    let profile = ShorterProfile(ownerId: "test", email: "brianm25it@gmail.com")
    profile.firstName = "Brian"
    profile.lastName = "Masse"
    profile.imageData = imageData
    
    return ProfilePreviewView(profile: profile)
}
