//
//  ProfileCreationScene.swift
//  Shorter
//
//  Created by Brian Masse on 6/21/24.
//

import Foundation
import SwiftUI
import UIUniversals
import Contacts

struct ProfileCreationView: View {
    
//    MARK: Scenes
    enum ProfileCreationScene: Int, ShorterSceneEnum {
        func getTitle() -> String {
            switch self {
            case .start:    return "start"
            case .overview: return "overview"
            case .contact:  return "contact"
            case .photo:    return "profile picture"
            case .social:   return "find friends"
            }
        }
        
        case start
        case overview
        case contact
        case photo
        case social
        
        var id: Int {
            self.rawValue
        }
    }
    
//    MARK: Vars
    
    @Environment(\.colorScheme) var colorScheme
    @ObservedObject private var contactManager = ContactManager.shared
    
    @State private var activeScene: ProfileCreationScene = .start
    @State private var sceneComplete: Bool = false
    
    @State private var showingStartPage: Bool = false
    
//    overview
    @State private var firstName: String    = ""
    @State private var lastName: String     = ""
    @State private var phoneNumber: Int     = 1
    
//    image
    @State private var uiImage: UIImage?    = nil
    @State private var showingImagePicker: Bool = false
    
//    contacts
    @State private var searchText: String = ""
    
    @State private var showingMessages: Bool = false
    @State private var recipients: [String] = []
    @State private var message = "message"
    
    @State private var filteredProfiles: [ShorterProfile] = []
    @State private var filteredContacts: [CNContact] = []
    @State private var friendIds: [String] = []
    
    private func validatePhoneNumber() -> Bool {
        "\(phoneNumber)".count >= 10 && "\(phoneNumber)".count < 12
    }
    
    private func validateName() -> Bool {
        !firstName.isEmpty && !lastName.isEmpty
    }
    
//    MARK: Methods
    private func submit() {
        if firstName.isEmpty ||
            lastName.isEmpty ||
            "\(phoneNumber)".count < 11 { return }
        
        let photoData = PhotoManager.encodeImage(uiImage)
        
        ShorterModel.shared.profile?.fillProfile(firstName: firstName,
                                                 lastName: lastName,
                                                 phoneNumber: phoneNumber,
                                                 friendIds: friendIds,
                                                 imageData: photoData)
        
        ShorterModel.realmManager.setState(.complete)
    }
    
    private func search() async {
        await ShorterModel.realmManager.shorterProfileQuery.addQuery("test") { query in
            return query.firstName.contains( searchText )
        }
        
        let results: [ShorterProfile] = RealmManager.retrieveObjects()
        self.filteredProfiles = results
        
        self.filteredContacts = contactManager.fetchContacts(for: searchText)
    }
    
//    MARK: Start Screen
    @ViewBuilder
    private func makeStartScene() -> some View {
        VStack {
            if showingStartPage {
                VStack {
                    Spacer()
                    
                    Text("Start by creating your")
                        .bold()
                        .font(.largeTitle)
                    
                    HStack {
                        Text("Shorter")
                            .bold()
                            .font(.largeTitle)
                            .foregroundStyle(Colors.getAccent(from: colorScheme))
                            .shadow(color: Colors.getAccent(from: colorScheme).opacity(0.6),
                                    radius: 20 )
                        
                        Text("Profile.")
                            .bold()
                            .font(.largeTitle)
                    }
                    
                    Spacer()
                }
                .transition( .asymmetric(insertion: .scale, removal: .push(from: .trailing)) )
            }
        }.onAppear { withAnimation {
            sceneComplete = true
            showingStartPage = true
        } }
    }
    
//    MARK: Overview Scenes
    @ViewBuilder
    private func makeOverviewScene() -> some View {
        VStack(alignment: .leading) {
         
            StyledTextField(title: "Whats your name?",
                            prompt: "First Name",
                            binding: $firstName)
            
            StyledTextField(title: "",
                            prompt: "Last Name",
                            binding: $lastName)
        }
        .onChange(of: firstName) { sceneComplete = validateName() }
        .onChange(of: lastName) { sceneComplete = validateName() }
    }
    
    @ViewBuilder
    private func makeContactScene() -> some View {
        VStack(alignment: .leading) {
            
            let phoneBinding: Binding<String> = {
               
                Binding {
                    phoneNumber.formatIntoPhoneNumber()
                } set: { (newValue, _) in
                    phoneNumber = Int( newValue.removeNonNumbers() ) ?? phoneNumber
                }
            }()
         
            StyledTextField(title: "Whats your Phone Number?",
                            prompt: "",
                            binding: phoneBinding)
            .keyboardType(.numberPad)
        }.onChange(of: phoneNumber) {
            sceneComplete = validatePhoneNumber()
        }
    }
    
//    MARK: Profile Picture Scene
    @ViewBuilder
    private func makeProfilePictureScene() -> some View {
        VStack {
            StyledPhotoPicker($uiImage,
                              description: "Choose a picture to display to friends",
                              maxPhotoWidth: .infinity,
                              shouldCrop: true)
        }.onAppear { sceneComplete = true }
    }
    
//    MARK: Social Scene
    @ViewBuilder
    private func makeFriendsScene() -> some View {
        SearchView()
            .onAppear { sceneComplete = true }
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
                     hasStartScene: true) {
            submit()
        } contentBuilder: { scene, dir in
            VStack {
                switch scene {
                case .start:
                    makeTransitionWrapper(dir) {
                        makeStartScene()
                    }
                    
                case .overview:
                    makeTransitionWrapper(dir) {
                        makeOverviewScene()
                    }
                    
                case .contact:
                    makeTransitionWrapper(dir) {
                        makeContactScene()
                    }

                case .photo:        
                    makeTransitionWrapper(dir) {
                        makeProfilePictureScene()
                    }
                    
                case .social:       
                    makeTransitionWrapper(dir) {
                        makeFriendsScene()
                    }
                }
            }
        }
    }
}

#Preview {
    ProfileCreationView()
}


//MARK: SlideTransition
//This adds a slide to the page it is applied to. It is used in all non-app navigation
//ie. entering the app, or leaving the splash screen
private struct SlideTransition: ViewModifier {
    let origin: Edge
    
    func body(content: Content) -> some View {
        content
            .transition(.push(from: origin))
    }
}

extension View {
    func slideTransition(_ origin: Edge) -> some View {
        modifier( SlideTransition(origin: origin) )
    }
}
