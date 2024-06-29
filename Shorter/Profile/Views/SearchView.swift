//
//  SearchView.swift
//  Shorter
//
//  Created by Brian Masse on 6/25/24.
//

import Foundation
import SwiftUI
import Contacts
import UIUniversals


//MARK: SearchView

struct SearchView: View {
    
    struct LocalConstants {
        static let selectProfileSize: CGFloat = 80
    }
    
//    MARK: Vars
    @ObservedObject var contactManager = ContactManager.shared
    @ObservedObject var viewModel = SearchViewModel.shared
    
    @State private var searchText: String = ""
    
    @State private var showingMessages: Bool = false
    @State private var recipients: [String] = []
    @State private var message = "message"
    
    @State private var friendIds: [String] = ["test"]
    
    @State private var searching: Bool = false
    
    let directlyAddFriends: Bool
    
    private func composeMessage(to contact: CNContact) {
        recipients = [ contact.phoneNumbers.first?.value.stringValue ?? "" ]
        message = "you should download this great app!"
        
        if !recipients.first!.isEmpty { showingMessages = true }
    }
    
//    MARK: ViewBuilder
    @ViewBuilder
    private func makeSearchBar() -> some View {
        ZStack(alignment: .trailing) {
            StyledTextField(title: "",
                            prompt: "Joe M...",
                            binding: $searchText)
            
            IconButton("magnifyingglass") {
                withAnimation { self.searching = true }
                Task {
                    await viewModel.search(in: searchText )
                    withAnimation { self.searching = false }
                }
            }
            .padding(.trailing)
        }
    }
    
    @ViewBuilder
    private func makeToggleButton( for id: String ) -> some View {
        IconButton( viewModel.checkProfileIsSelected(id) ? "minus" : "plus") {
            Task { await viewModel.toggleProfile(id, directlyAddProfile: directlyAddFriends) }
        }
    }
    
//    MARK: ContactList
    @ViewBuilder
    private func makeContact( from wrapper: SearchViewModel.ContactWrapper ) -> some View {
        HStack {
            let contact = wrapper.contact
            let phoneNumber = ContactManager.getPhoneNumbers(for: contact).first
            
            VStack(alignment: .leading) {
                Text( "\(contact.givenName) \(contact.familyName)" )
                    .bold()
                
                Text( phoneNumber?.formatIntoPhoneNumber() ?? "" )
                    .font(.caption)
            }
            
            Spacer()
            
            if wrapper.profileId == nil {
                IconButton("arrowshape.turn.up.right") { composeMessage(to: contact) }
                    .padding(.trailing)
            } else {
                makeToggleButton(for: wrapper.profileId!)
                    .padding(.trailing)
            }
            
        }
    }
    
    @ViewBuilder
    private func makeContactList() -> some View {
        if viewModel.filteredContacts.count > 0 {
            VStack(alignment: .leading) {
                Text( "From Contacts" )
                    .font(.title3)
                    .bold()
                
                ForEach( 0..<viewModel.filteredContacts.count, id: \.self ) { i in
                    let contactWrapper = viewModel.filteredContacts[i]
                    
                    makeContact(from: contactWrapper)
                    
                    Divider()
                }
            }
        }
    }
    
//    MARK: ProfileList
    @ViewBuilder
    private func makeProfileList() -> some View {
        if viewModel.filteredProfiles.count > 0 {
            VStack(alignment: .leading) {
                
                ForEach(viewModel.filteredProfiles) { profile in
                    ZStack(alignment: .trailing) {
                        ProfilePreviewView(profile: profile)
                        
                        makeToggleButton(for: profile.ownerId)
                            .padding(.trailing)
                    }
                }
            }
        }
    }
    
//    MARK: SelectedProfileList
    @ViewBuilder
    private func makeSelectedProfile( _ profile: ShorterProfile ) -> some View {
        VStack {
            profile.getImage()
                .resizable()
                .scaledToFit()
                .frame(width: LocalConstants.selectProfileSize,
                       height: LocalConstants.selectProfileSize)
                .clipShape(Circle())
                .contentShape(Circle())
            
            Text( profile.fullName )
                .font( .callout )
        }
    }
    
    @ViewBuilder
    private func makeSelectedProfileList() -> some View {
        if viewModel.selectedProfles.count > 0 {
            VStack(alignment: .leading, spacing: 0) {
                Text("Selected Profiles")
                    .font(.title2)
                    .bold()
                
                ScrollView( .horizontal, showsIndicators: false ) {
                    HStack {
                        ForEach( viewModel.selectedProfles ) { profile in
                            makeSelectedProfile(profile)
                        }
                    }
                }.padding(.vertical)
                
                Divider()
            }
        }
    }
    
    
//    MARK: Body
    var body: some View {
        
        VStack(alignment: .leading) {
            
            Text( "Find Friends" )
                .font(.title3)
                .bold()
            
            makeSearchBar()
                .padding(.bottom)
            
            Divider()
            
            makeSelectedProfileList()
                .padding(.bottom)

            ScrollView(.vertical, showsIndicators: false) {
                if !searching {
                    makeProfileList()
                        .padding(.bottom)
                    
                    makeContactList()
                } else {
                    ProgressView()
                }
            }
            .clipShape(RoundedRectangle(cornerRadius: Constants.UIDefaultCornerRadius ))

            Spacer()
        }
        .onDisappear { viewModel.clear() }
        .task { await contactManager.fetchContacts() }
        .sheet(isPresented: $showingMessages) {
            MessageUIView(recipients: $recipients, body: $message) { result in }
        }
    }
}

#Preview {
    SearchView(directlyAddFriends: true)
}
