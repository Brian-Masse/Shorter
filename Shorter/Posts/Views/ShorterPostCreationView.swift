//
//  ShorterPostCreationView.swift
//  Shorter
//
//  Created by Brian Masse on 6/26/24.
//

import Foundation
import SwiftUI

struct ShorterPostCreationView: View {
    
    enum CreationPostScene: Int, ShorterSceneEnum {
        func getTitle() -> String {
            switch self {
            case .overview:     return "overview"
            case .photo:        return "photo"
            }
        }
        case overview
        case photo
        
        var id: Int { self.rawValue }
    }
    
//    MARK: Vars
    @State private var activeScene: CreationPostScene = .overview
    @State private var sceneComplete: Bool = false
    
    @State private var showingImagePicker: Bool = false
    
    @State private var title: String = ""
    @State private var fullTitle: String = ""
    @State private var notes: String = ""
    
    @State var uiImage: UIImage? = nil
    
    private func validateFields() -> Bool {
        !title.isEmpty && !fullTitle.isEmpty
    }
    
    @MainActor
    private func submit() {
        if title.isEmpty { return }
        
//        let imageData = PhotoManager.encodeImage(self.image)
//        
//        let post = ShorterPost(ownerId: ShorterModel.ownerId,
//                               authorName: ShorterModel.shared.profile!.fullName,
//                               fullTitle: fullTitle,
//                               title: title,
//                               emoji: "🙂‍↔️",
//                               notes: notes,
//                               data: imageData)
//        
//        RealmManager.addObject( post )
    }
    

//    MARK: ViewBuilder
    @ViewBuilder
    private func makeOverviewScene() -> some View {
        VStack(alignment: .leading) {
            
            Text("Share your Day")
                .font(.title)
                .bold()
                .padding(.bottom)
            
            HStack(alignment: .bottom) {
                StyledTextField(title: "Whats your status today?",
                                prompt: "excited, tired, productive ..",
                                binding: $title)
                
                EmojiPicker()
            }
                .padding(.bottom)
            
            StyledTextField(title: "What are you up to?",
                            prompt: "going to a beach with my friends",
                            binding: $fullTitle)
            .padding(.bottom)
            
            StyledTextField(title: "Any additional notes?",
                            prompt: "notes",
                            binding: $notes)

            Spacer()
        }
        .onChange(of: fullTitle) { sceneComplete = validateFields() }
        .onChange(of: title) { sceneComplete = validateFields() }
    }
    
    @ViewBuilder
    private func makePhotoScene() -> some View {
        Text("hi")
    }
    
    @ViewBuilder
    private func makeTransitionWrapper<C: View>(_ transitionDirection: Edge, @ViewBuilder contentBuilder: () -> C) -> some View {
        contentBuilder()
            .slideTransition( transitionDirection )
    }
    
//    MARK: Body
    var body: some View {
        
        ShorterScene($activeScene,
                     sceneComplete: $sceneComplete,
                     canRegressScene: true,
                     submit: submit ) { scene, dir in
            
            VStack {
                switch scene {
                case .overview:     makeOverviewScene()
                case .photo:        makePhotoScene()
                }
            }
        }
        .emojiPresenter()
    }
}

#Preview {
    ShorterPostCreationView()
        .emojiPresenter()
}
