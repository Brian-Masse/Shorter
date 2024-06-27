//
//  ProfileEdittingView.swift
//  Shorter
//
//  Created by Brian Masse on 6/26/24.
//

import Foundation
import SwiftUI

struct ProfileEdittingView: View {
    
    enum ProfileEdittingViewScene: Int, ShorterSceneEnum {
        func getTitle() -> String { "main" }

        case main
        
        var id: Int { self.rawValue }
    }
    
//    MARK: Submit
    private func validateFields() -> Bool {
        !firstName.isEmpty &&
        !lastName.isEmpty &&
        !email.isEmpty &&
        "\(phoneNumber)".count >= 10 && "\(phoneNumber)".count < 12
    }
    
    private func validateImage() -> Bool {
        uiImage != nil
    }
    
    private func submit() {
        if !validateFields() { return }
        if !validateImage() { return }
        
        let imageData = PhotoManager.encodeImage(uiImage)
        
        profile.updateProfile(firstName: firstName,
                              lastName: lastName,
                              email: email,
                              phoneNumber: phoneNumber,
                              imageData: imageData)
        
        dismiss()
    }
    
//    MARK: Vars
    @Environment(\.dismiss) var dismiss
    
    let profile: ShorterProfile
    
    @State private var activeScene: ProfileEdittingViewScene = .main
    @State private var sceneComplete: Bool = true
    
    @State private var firstName: String
    @State private var lastName: String
    @State private var email: String
    @State private var phoneNumber: Int
    @State private var uiImage: UIImage? = nil
    
    init( profile: ShorterProfile ) {
        self.firstName = profile.firstName
        self.lastName = profile.lastName
        self.email = profile.email
        self.phoneNumber = profile.phoneNumber
        
        let uiImage = PhotoManager.decodeUIImage(from: profile.imageData)
        self.uiImage = uiImage
        
        self.profile = profile
    }
    
    private var phoneNumberBinding: Binding<String> {
        Binding {
            phoneNumber.formatIntoPhoneNumber()
        } set: { (newValue, _) in
            phoneNumber = Int( newValue.removeNonNumbers() ) ?? phoneNumber
        }
    }
    
//    MARK: Overview
    @ViewBuilder
    private func makeOverviewView() -> some View {
        VStack(alignment: .leading) {
            StyledTextField(title: "Whats your name?",
                            prompt: "First Name",
                            binding: $firstName)
            
            StyledTextField(title: "",
                            prompt: "Last Name",
                            binding: $lastName)
            .padding(.bottom)
            
            StyledTextField(title: "How would you like to be contacted?",
                            prompt: "email",
                            binding: $email)
            
            StyledTextField(title: "",
                            prompt: "phoneNumber",
                            binding: phoneNumberBinding)
            .padding(.bottom)
        }
        .onChange(of: firstName) { sceneComplete = validateFields() }
        .onChange(of: lastName) { sceneComplete = validateFields() }
        .onChange(of: email) { sceneComplete = validateFields() }
        .onChange(of: phoneNumber) { sceneComplete = validateFields() }
    }
    
    
    @ViewBuilder
    private func makePhotoView() -> some View {
        StyledPhotoPicker($uiImage, description: "")
            .onAppear { PhotoManager.shared.storedImage = self.uiImage }
            .onChange(of: uiImage) { sceneComplete = validateImage() }
    }
    
//    MARK: Body
    var body: some View {
        ShorterScene($activeScene,
                     sceneComplete: $sceneComplete,
                     canRegressScene: true,
                     hideControls: true, submit: submit) { _, _ in
            
            VStack(alignment: .leading) {
            
                Text( "Edit Profile" )
                    .font(.largeTitle)
                    .bold()
                
                
                ScrollView {
                    makeOverviewView()
                    
                    makePhotoView()
                }
            }
        }
    }
}

#Preview {
    let uiImage = UIImage(named: "BigSur")
    let imageData = PhotoManager.encodeImage(uiImage)
    
    let profile = ShorterProfile(ownerId: "test", email: "brianm25it@gmail.com")
    profile.firstName = "Brian"
    profile.lastName = "Masse"
    profile.phoneNumber = 17813153811
    profile.imageData = imageData
    
    return ProfileEdittingView(profile: profile)
}
