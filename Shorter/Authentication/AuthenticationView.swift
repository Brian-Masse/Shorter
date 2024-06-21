//
//  AuthenticationView.swift
//  Cactus
//
//  Created by Brian Masse on 6/20/24.
//

import Foundation
import SwiftUI

struct AuthenticationView: View {
    
    @State private var email: String = ""
    @State private var password: String = ""
    
    let realmManager = ShorterModel.realmManager
    
    private func submit() async {
        if email.isEmpty || password.isEmpty { return }
        
        if let error = await realmManager.signInWithPassword(email: email, password: password) {
//            TODO: Handle Error
        }
    }
    
    var body: some View {
        VStack(alignment: .leading) {
            
            Text("Sign in / Register")
                .font(.title)
                .bold()
            
            TextField(text: $email, prompt: Text("email")) { }
            
            TextField(text: $password, prompt: Text("password")) { }
            
            Button(action: { Task {
                await submit()
            }}) {
                Text("register")
            }
            
            Spacer()
        }
    }
}
