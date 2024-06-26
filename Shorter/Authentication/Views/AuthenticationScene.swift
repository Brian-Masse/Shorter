//
//  AuthenticationView.swift
//  Cactus
//
//  Created by Brian Masse on 6/20/24.
//

import Foundation
import SwiftUI

//MARK: AuthenticationScene
struct AuthenticationScene: View {
    
    enum AuthenticationSceneState: Int, ShorterSceneEnum {
        func getTitle() -> String {
            switch self {
            case .start:    return "start"
            case .main:     return "main"
            }
        }
        
        case start
        case main
        
        var id: Int { self.rawValue }
    }
    
    
//    MARK: Vars
    
    @State private var activeScene: AuthenticationSceneState = .start
    @State private var sceneComplete: Bool = true
    
    @State private var startScreenFullText: String = "Welcome to Shorter."
    @State private var startScreenHighlightedText: String = "Shorter"
    
    @State private var email: String = ""
    @State private var password: String = ""
    
    let realmManager = ShorterModel.realmManager
    
    private func validateForm() -> Bool {
        !email.isEmpty && !password.isEmpty
    }
    
    private func submit() {
        if !validateForm() { return }
        
        Task {
            if let _ = await realmManager.signInWithPassword(email: email, password: password) {
                //            TODO: Handle Error
            }
        }
    }
    
    @ViewBuilder
    private func makeTransitionWrapper<C: View>(_ transitionDirection: Edge, @ViewBuilder contentBuilder: () -> C) -> some View {
        contentBuilder()
            .slideTransition( transitionDirection )
    }
    
//    MARK: StartScene
    @ViewBuilder
    private func makeStartScene() -> some View {
        ShorterSplashScreen(startScreenFullText, highlighting: startScreenHighlightedText)
            .onAppear {
                DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                    withAnimation {
                        startScreenFullText = "Lets start making the distance Shorter."
                        startScreenHighlightedText = "Shorter"
                    }
                }
                
            }
    }
    
    @ViewBuilder
    private func makeMainScene() -> some View {
        VStack(alignment: .leading) {
            
            Text("Continue to Shorter")
                .font(.largeTitle)
                .bold()
                .padding(.bottom)
            
            StyledTextField(title: "", prompt: "email", binding: $email)
            
            StyledTextField(title: "", prompt: "password", binding: $password, privateField: true)
            
            Spacer()
        }
        .padding(.vertical)
        .onChange(of: email) { oldValue, newValue in sceneComplete = validateForm() }
        .onChange(of: password) { oldValue, newValue in sceneComplete = validateForm() }
    }
    
//    MARK: Body
    var body: some View {
        ShorterScene($activeScene,
                     sceneComplete: $sceneComplete,
                     canRegressScene: false,
                     hideControls: true,
                     submit: submit) { scene, dir in
            
            VStack {
                switch scene {
                case .start:
                    makeTransitionWrapper(dir) { makeStartScene() }
                    
                case .main:
                    makeTransitionWrapper(dir) { makeMainScene() }
                }
            }
        }
    }
}

#Preview {
    AuthenticationScene()
}
