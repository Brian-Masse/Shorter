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
        VStack {
            switch realmManager.authenticationState {
            case .authenticating:
                AuthenticationScene()
                
            case .openingRealm:
                OpenFlexibleSyncRealmView()
                    .environment(\.realmConfiguration, realmManager.configuration)
                
            case .creatingProfile:
                ProfileCreationView()
                    .environment(\.realmConfiguration, realmManager.configuration)
                
            case .error:
                Text("An error occoured")
                
            case .complete:
                MainView()
                    .environment(\.realmConfiguration, realmManager.configuration)
            }
        }
        .task { realmManager.checkLogin() }
    }
}

#Preview {
    ShorterView()
}
