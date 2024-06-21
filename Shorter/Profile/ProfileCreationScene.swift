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
            case .overview: return "overview"
            case .photo:    return "profile picture"
            case .social:   return "find friends"
            }
        }
        
        case overview
        case photo
        case social
        
        var id: Int {
            self.rawValue
        }
    }
    
//    MARK: Vars
    @ObservedObject private var contactManager = ContactManager.shared
    
    @State private var activeScene: ProfileCreationScene = .overview
    @State private var sceneComplete: Bool = true
    
    @State private var firstName: String    = ""
    @State private var lastName: String     = ""
    @State private var phoneNumber: Int     = 1
    @State private var uiImage: UIImage?    = nil
    
    @State private var showingImagePicker: Bool = false
    
    @State private var searchText: String = ""
    
    @State private var showingMessages: Bool = false
    @State private var recipients: [String] = []
    @State private var message = "message"
    
    @State private var filteredProfiles: [ShorterProfile] = []
    @State private var filteredContacts: [CNContact] = []
    @State private var friendIds: [String] = []
    
    private var phoneNumberBinding: Binding<String> {
        Binding {
            self.phoneNumber.formatIntoPhoneNumber()
        } set: { newValue in
            self.phoneNumber = Int( newValue ) ?? self.phoneNumber
        }
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
    
//    MARK: ViewBuilders
    @ViewBuilder
    private func makeOverviewScene() -> some View {
        VStack(alignment: .leading) {
         
            TextField("firstName", text: $firstName, prompt: Text( "First Name" ))
                .padding(.bottom)
            
            TextField("lastName", text: $lastName, prompt: Text( "Last Name" ))
                .padding(.bottom)
            
            TextField("phoneNumber", text: phoneNumberBinding, prompt: Text( "Phone Number" ))
                .padding(.bottom)
            
            Button(action: { showingMessages = true }) {
                Text("show messages")
            }
        }
    }
    
    @ViewBuilder
    private func makeProfilePictureScene() -> some View {
        VStack {
            Button(action: { showingImagePicker = true }) {
                Text("pick image")
            }
            
            if let uiImage = self.uiImage {
                Image(uiImage: uiImage)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
            }
        }
        .sheet(isPresented: $showingImagePicker) {
            ImagePickerView(sourceType: .photoLibrary) { image in
                self.uiImage = image
            }
        }
    }
    
    @ViewBuilder
    private func makeFriendsScene() -> some View {
        VStack(alignment: .leading) {
            
            HStack {
                TextField("search", text: $searchText, prompt: Text( "search for friends" ))
                
                Image(systemName: "magnifyingglass")
                    .onTapGesture {
                        Task {
                            await ShorterModel.realmManager.shorterProfileQuery.addQuery("test") { query in
                                return query.firstName.contains( searchText )
                            }
                            
                            let results: [ShorterProfile] = RealmManager.retrieveObjects()
                            self.filteredProfiles = results
                            
                            self.filteredContacts = contactManager.fetchContacts(for: searchText)
                        }
                    }
            }
            Text("Selected Users")
                .font(.title3)
                .bold()
            
            ForEach(friendIds) { id in
                if let profile = ShorterProfile.getProfile(for: id) {
                    Text("\(profile.firstName)")
                } else {
                    Text( "error getting profie: \(id)" )
                }
            }
            
            Text( "Uesrs" )
                .font(.title3)
                .bold()
            
            ForEach( filteredProfiles ) { profile in
                Text( "\( profile.firstName ) \( profile.lastName )" )
                    .onTapGesture {
                        if let index = friendIds.firstIndex(where: { str in str == profile.ownerId }) {
                            friendIds.remove(at: index)
                        } else {
                            friendIds.append(profile.ownerId)
                        }
                    }
            }
            
            Text("Contacts")
                .font(.title3)
                .bold()
            
            ForEach( filteredContacts ) { contact in
                Text( "\(contact.givenName) \(contact.familyName)" )
                    .onTapGesture {
                        recipients = [ contact.phoneNumbers.first?.value.stringValue ?? "" ]
                        message = "you should download this great app!"
                        
                        if !recipients.first!.isEmpty {
                            showingMessages = true
                        }
                    }
            }
            
            Spacer()
        }
        .task {
            await contactManager.fetchContacts()
        }
        .sheet(isPresented: $showingMessages) {
            MessageUIView(recipients: $recipients, body: $message) { result in
                
            }
        }

    }
    
//    MARK: Body
    var body: some View {
        
        
        ShorterScene($activeScene, sceneComplete: $sceneComplete, canRegressScene: true) {
            submit()
        } contentBuilder: { scene in
            VStack {
                switch scene {
                case .overview:     makeOverviewScene()
                case .photo:        makeProfilePictureScene()
                case .social:       makeFriendsScene()
                }
            }
        }
    }
}
