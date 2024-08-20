//
//  ShorterPostCreationView.swift
//  Shorter
//
//  Created by Brian Masse on 6/26/24.
//

import Foundation
import SwiftUI
import UIUniversals

struct ShorterPostCreationView: View {
    
    enum CreationPostScene: Int, ShorterSceneEnum {
        func getTitle() -> String {
            switch self {
            case .overview:     return "overview"
            case .photo:        return "photo"
            case .social:        return "social"
            }
        }
        case overview
        case photo
        case social
        
        var id: Int { self.rawValue }
    }
    
//    MARK: Vars
    @Environment(\.dismiss) var dismiss
    @Environment(\.colorScheme) var colorScheme
    
    @State private var activeScene: CreationPostScene = .overview
    @State private var sceneComplete: Bool = false
    
    @State private var title: String = ""
    @State private var fullTitle: String = ""
    @State private var notes: String = ""
    
    @State var uiImage: UIImage? = nil
    @State private var showingImagePicker: Bool = false
    @State private var showingLibraryPicker: Bool = false
    
    @State private var showingAllProfiles: Bool = false
    @State private var selectedProfileIds: [String] = Array(ShorterModel.shared.profile!.friendIds)
    
    @State private var hasMatureContent: Bool = false
    
    private func validateFields() -> Bool {
        !title.isEmpty && !fullTitle.isEmpty
    }
    
    @MainActor
    private func submit() {
        if title.isEmpty { return }
        
        let imageData = PhotoManager.encodeImage(self.uiImage)
        
        let post = ShorterPost(ownerId: ShorterModel.ownerId,
                               authorName: ShorterModel.shared.profile!.fullName,
                               fullTitle: fullTitle,
                               title: title,
                               emoji: EmojiPickerViewModel.shared.selectedEmoji,
                               notes: notes,
                               shareList: selectedProfileIds,
                               hasMatureContent: hasMatureContent,
                               data: imageData)
//        
        RealmManager.addObject( post )
        
        dismiss()
    }
    
    private func toggleProfileId(_ id: String) {
        if let index = selectedProfileIds.firstIndex(of: id) {
            selectedProfileIds.remove(at: index)
        } else {
            selectedProfileIds.append(id)
        }
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
            
            StyledTextField(title: "Any additional notes?",
                            prompt: "notes",
                            binding: $notes,
                            multiLine: true)

            Spacer()
        }
        .onChange(of: fullTitle) { sceneComplete = validateFields() }
        .onChange(of: title) { sceneComplete = validateFields() }
    }
    
//    MARK: PhotoScene
    @ViewBuilder
    private func makePhotoScene() -> some View {
        VStack() {
            Spacer()
            
            if let image = self.uiImage {
                VStack {
                    Spacer()
                    
                    Image(uiImage: image)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .clipShape(RoundedRectangle(cornerRadius: Constants.UIDefaultCornerRadius))
                        
                    Spacer()
                    
                    HStack {
                        IconButton("arrow.triangle.2.circlepath") {
                            self.showingImagePicker = true
                        }
                        
                        Spacer()
                        
                        IconButton("trash") {
                            self.uiImage = nil
                        }
                    }
                }
                
            } else {
                
                UniversalButton {
                    VStack {
                        Image(systemName: "iphone.rear.camera")
                            .font(.largeTitle)
                            .padding(.bottom)
                        
                        Text( "Take a Picture" )
                            .font(.title2)
                            .bold()
                    }
                } action: { self.showingImagePicker = true }
                
                Spacer()
                
                UniversalButton {
                    HStack {
                        Image(systemName: "photo.on.rectangle")
                        
                        Text( "or upload a photo" )
                    }
                    .padding()
                    .opacity(Constants.secondaryTextAlpha)
                    .font(.callout)
                    .bold()
                    
                } action: { self.showingLibraryPicker = true }
            }
        }
        .sheet(isPresented: $showingImagePicker) {
            ImagePickerView(sourceType: .camera) { uiImage in
                self.uiImage = uiImage
            }
            .ignoresSafeArea()
        }
        .sheet(isPresented: $showingLibraryPicker) {
            ImagePickerView(sourceType: .photoLibrary) { uiImage in
                self.uiImage = uiImage
            }
            .ignoresSafeArea()
        }
        .onChange(of: uiImage) {
            sceneComplete = uiImage != nil
        }
    }
    
//    MARK: SocialScene
    private func getSelectedProfileCountMessage() -> String {
        if selectedProfileIds.count == ShorterModel.shared.profile?.friendIds.count {
            return "everyone"
        } else if selectedProfileIds.count != 0 {
            return "\(selectedProfileIds.count) profiles selected"
        } else {
            return "\(selectedProfileIds.count) profile selected"
        }
    }
    
    private func isSelected( _ id: String ) -> Bool { selectedProfileIds.contains(id) }
    
    @ViewBuilder
    private func makeMatureContentToggle() -> some View {
        HStack {
            Image(systemName: "hand.raised")
            Text( "This post has mature content" )
            
            Spacer()
            
            Toggle("", isOn: $hasMatureContent)
                .tint(Colors.getAccent(from: colorScheme))
        }
        .rectangularBackground(style: .secondary)
    }
    
    @ViewBuilder
    private func makeSocialScene() -> some View {
        VStack(alignment: .leading) {
                
            Text( "Who would you like to share this with?" )
                .font(.title2)
                .bold()
                .padding([.bottom, .trailing])
            
            UniversalButton {
                
                HStack {
                    Image(systemName:  showingAllProfiles ? "chevron.up" : "chevron.down")
                        .bold()
                    
                    Text( "Profiles" )
                        .bold()
                    
                    Spacer()
                    
                    Text( getSelectedProfileCountMessage() )
                        .opacity(Constants.tertiaryTextAlpha)
                }
                
            } action: { showingAllProfiles.toggle() }
             
            ScrollView(.vertical) {
                VStack {
            
                    if showingAllProfiles {
                        ForEach( ShorterModel.shared.profile!.friendIds ) { id in
                            
                            if let profile = ShorterProfile.getProfile(for: id) {
                                ProfilePreviewView(profile: profile)
                                    .onTapGesture { withAnimation { toggleProfileId(id) } }
                                    .opacity( isSelected(id) ? 1 : 0.3 )
                            }
                        }
                    }
                }
            }
            
            Spacer()
            
            makeMatureContentToggle()
            Text( "Help keep Shorter safe by marking mature content. This will only display for users that allow mature content" )
                .font(.caption)
                .padding(.leading, Constants.subPadding)
                .opacity(Constants.secondaryTextAlpha)
                .padding(.bottom)
        }
        .onAppear { sceneComplete = true }
    }
    
    @ViewBuilder
    private func makeTransitionWrapper<C: View>(_ transitionDirection: Edge, @ViewBuilder contentBuilder: () -> C) -> some View {
        contentBuilder()
            .slideTransition( transitionDirection )
    }
    
//    MARK: Body
    var body: some View {
        ZStack(alignment: .topTrailing) {
            ShorterScene($activeScene,
                         sceneComplete: $sceneComplete,
                         canRegressScene: true,
                         hideControls: true,
                         submit: submit ) { scene, dir in
                
                VStack {
                    switch scene {
                    case .overview:     makeOverviewScene()
                    case .photo:        makePhotoScene()
                    case .social:       makeSocialScene()
                    }
                }
            }
            
            IconButton("chevron.down") {
                dismiss()
            }
            .padding()
        }
        .emojiPresenter()
    }
}

#Preview {
    ShorterPostCreationView()
        .emojiPresenter()
}
