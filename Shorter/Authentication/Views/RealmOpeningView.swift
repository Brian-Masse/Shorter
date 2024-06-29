//
//  RealmOpeningView.swift
//  Cactus
//
//  Created by Brian Masse on 6/20/24.
//

import Foundation
import SwiftUI
import RealmSwift
import UIUniversals


/// This view opens a synced realm.
struct OpenFlexibleSyncRealmView: View {
    // We've injected a `flexibleSyncConfiguration` as an environment value,
    // so `@AsyncOpen` here opens a realm using that configuration.
    @AsyncOpen(appId: RealmManager.appID, timeout: 4000) var asyncOpen
    @Environment(\.colorScheme) var colorScheme
    
    @State private var alertTitle: String = ""
    @State private var alertMessage: String = ""
    @State private var showingErrorAlert: Bool = false
    
    @State private var degrees: CGFloat = 0
    @State private var xRotation: CGFloat = 0
    @State private var yRotation: CGFloat = 0
    
//    MARK: AsyncStatus
    @ViewBuilder
    private func makeStatusLabel(status: String, icon: String) -> some View {
        ShorterTitle(title: status, icon: icon)
    }
    
    @ViewBuilder
    private func makeAsyncStatus() -> some View {
        switch asyncOpen {
        // Starting the Realm.asyncOpen process.
        // Show a progress view.
        case .connecting:
            makeStatusLabel(status: "connecting", icon: "externaldrive.connected.to.line.below")
            
        // Waiting for a user to be logged in before executing
        // Realm.asyncOpen.
        case .waitingForUser:
            makeStatusLabel(status: "Waiting for Authentication", icon: "person.slash")
                .onAppear {
                    self.alertTitle = "User not Authenticated"
                    self.alertMessage = "return to the sign in screen and try again"
                    self.showingErrorAlert = true
                }
            
        // The realm has been opened and is ready for use.
        // Show the content view.
        case .open(let realm):
            makeStatusLabel(status: "Loading Assests", icon: "shippingbox")
                .task { await ShorterModel.realmManager.authRealm(realm: realm) }
            
        // The realm is currently being downloaded from the server.
        // Show a progress view.
        case .progress(_):
            makeStatusLabel(status: "Downloading Realm from Server", icon: "server.rack")
            
            
        // Opening the Realm failed.
        // Show an error view.
        case .error(let error):
            makeStatusLabel(status: "Error Opening Realm", icon: "wrench.and.screwdriver")
                .onAppear {
                    self.alertTitle = "Error Opening Realm"
                    self.alertMessage = "return to the sign in screen and try again"
                    self.showingErrorAlert = true
                    
                    print( "\(error.localizedDescription)" )
                }
        }
    }
    
//    MARK: Icon
    @ViewBuilder
    private func makeIcon() -> some View {
        
        Image(colorScheme == .dark ? "icon-dark" : "icon-light")
            .resizable()
            .aspectRatio(1, contentMode: .fill)
            .frame(width: 120, height: 120)
            .clipShape(RoundedRectangle(cornerRadius: Constants.UILargeTextSize ))
            .contentShape(Rectangle())
            .allowsTightening(false)
            .cardWithDepth(shadow: true)
        
            .rotation3DEffect(
                .init(degrees: degrees),
                                      axis: (x: xRotation, y: yRotation, z: xRotation)
            )
        
            .onAppear {
                withAnimation(.linear(duration: 100)) {
                    degrees = 180
                }
                xRotation = Double.random(in: -1...1)
                yRotation = Double.random(in: -1...1)
            }
    }
    
//    MARK: Body
    var body: some View {
        
        VStack {
            Spacer()
            
            HStack {
                Spacer()
                
                makeIcon()
                
                Spacer()
            }
            
            Spacer()
            
            makeAsyncStatus()
        }
        .ignoresSafeArea()
        .padding()
        .background {
            BlurredBackground(colors: ShorterModel.defautColorPallett)
                .ignoresSafeArea()
        }
        
        .alert(alertTitle, isPresented: $showingErrorAlert) {
            Button("return to sign in", role: .cancel) {
                ShorterModel.realmManager.setState(.authenticating)
            }
        } message: {
            Text( alertMessage )
        }

    }
}
