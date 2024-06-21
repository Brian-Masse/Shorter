//
//  ContentView.swift
//  Shorter
//
//  Created by Brian Masse on 6/21/24.
//

import SwiftUI
import RealmSwift

struct ShorterView: View {
    
    @ObservedObject var realmManager = ShorterModel.realmManager
    
    var body: some View {
        switch realmManager.authenticationState {
        case .authenticating:
            AuthenticationView()
                .padding()
            
        case .openingRealm:
            OpenFlexibleSyncRealmView()
                .environment(\.realmConfiguration, realmManager.configuration)
                .padding()
            
        case .creatingProfile:
            ProfileCreationView()
            
        case .error:
            Text("An error occoured")
            
        case .complete:
            MainView()
                .environment(\.realmConfiguration, realmManager.configuration)
                .padding()
        }
    }
}

struct ProfileCreationView: View {
    var body: some View {
        Text("hi")
            .task {
                await ShorterModel.realmManager.checkProfile()
            }
    }
}
