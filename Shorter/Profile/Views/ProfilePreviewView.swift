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
    
    let profile: ShorterProfile
    
    private let removeFriendTitle: String = "Remove Friend?"
    private let removeFriendMessage: String = "You won't be able to see any of their older posts, even when you re-add them"
    
    @State private var showingRemoveFriendAlert: Bool = false
    
    @State private var previousOffset: CGFloat = 0
    @State private var offset: CGFloat = 0
    
    private let maxDeleteHandleSize: CGFloat = 200
    
    private var dragGesture: some Gesture {
        DragGesture()
            .onChanged { value in
                if value.translation.width < 0 {
                    offset = previousOffset + max(-maxDeleteHandleSize - 100, min(value.translation.width, 0))
                } else if previousOffset == maxDeleteHandleSize {
                    offset = -maxDeleteHandleSize - min( 0, max(-value.translation.width, -maxDeleteHandleSize))
                }
            }
            .onEnded { value in
                if value.translation.width < -50 {
                    withAnimation { self.offset = -maxDeleteHandleSize }
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
                                .frame(width: 200)
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
                
                ZStack(alignment: .leading) {
                    Color.red
                        .frame(width: maxDeleteHandleSize + 200)
                    
                    makeDeleteHandle()
                        .frame(width: maxDeleteHandleSize)
                }
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
            .frame(height: 100)
            
            .overlay {
                makeContent()
            }
    
            .clipShape(RoundedRectangle(cornerRadius: Constants.UIDefaultCornerRadius))
            .cardWithDepth()
        
        
            .alert(removeFriendTitle,
                   isPresented: $showingRemoveFriendAlert,
                   actions: {
                
                Button("remove", role: .destructive) {
                    let id = profile.ownerId
                    Task { await ShorterModel.shared.profile?.removeFriend( id ) }
                }
                
            }, message: {
                Text( removeFriendMessage )
            })
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
