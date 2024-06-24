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
    
//    MARK: Body
    var body: some View {
        HStack {
            profile.getImage()
                .resizable()
                .aspectRatio(1, contentMode: .fit)
                .clipShape(Circle())
            
            
            VStack(alignment: .leading) {
                Text( profile.fullName )
                    .font(.title2)
                    .bold()
                
                Text( "friend since \(Date.now.formatted(date: .abbreviated, time: .omitted))" )
                    
                
                Spacer()
            }
            .padding(.horizontal)
            
            Spacer()
        }
        .frame(height: 75)
        .padding()
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: Constants.UIDefaultCornerRadius))
        .shadow(color: .black.opacity(0.2), radius: 10, y: 10)
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
