//
//  SearchViewModel.swift
//  Shorter
//
//  Created by Brian Masse on 6/25/24.
//

import Foundation
import SwiftUI
import Contacts

class SearchViewModel: ObservableObject {
    
    struct ContactWrapper {
        let contact: CNContact
        let profileId: String?
    }
    
    //    MARK: Vars
    static let shared = SearchViewModel()
    
    private let contactManager = ContactManager.shared
    
    private let searchQueryKey: String = "searchQueryKey"
    
    @Published var filteredProfiles: [ShorterProfile] = []
    @Published var filteredContacts: [ContactWrapper] = []
    @Published var selectedProfles: [ShorterProfile] = []
    
    private func formatString( _ str: String ) -> String {
        str.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
    }
    
    private func comparePhoneNumbers( num1: Int, num2: Int ) -> Bool {
        if num1 == num2 { return true }
        if "\(num1)".count == "\(num2)".count + 1 {
            var str1 = "\(num1)"
            str1.removeFirst()
            return str1 == "\(num2)"
        }
        return false
    }
    
    @MainActor
    func clear() {
        self.filteredProfiles = []
        self.filteredContacts = []
        self.selectedProfles = []
        
        Task { await ShorterModel.realmManager.removeSubscription(name: searchQueryKey) }
    }
    
    //    MARK: selectProfile
    @MainActor
    func toggleProfile( _ id: String, directlyAddProfile: Bool ) async {
        var mutatingProfiles = selectedProfles
        
        if directlyAddProfile {
            withAnimation { ShorterModel.shared.profile?.addFriend( id ) }
            return
        }
        
        if let index = selectedProfles.firstIndex(where: { profile in
            profile.ownerId == id
        }) {
            mutatingProfiles.remove(at: index)
        } else {
            if let profile = ShorterProfile.getProfile(for: id) {
                mutatingProfiles.append(profile)
            }
        }
        
        withAnimation { self.selectedProfles = mutatingProfiles }
    }
    
    func checkProfileIsSelected(_ id: String) -> Bool {
        selectedProfles.firstIndex { profile in
            profile.ownerId == id
        } != nil
    }
    
//    MARK: GetDataBaseProfiles
    @MainActor
    private func retrieveDataBaseProfiles(in searchText: String) async {
        let realmManager = ShorterModel.realmManager
        await realmManager.shorterProfileQuery.addQuery(searchQueryKey) { query in
            query.firstName.contains( searchText )
        }
        
        var results: [ShorterProfile] = RealmManager.retrieveObjects()
        results = results.filter { profile in
            profile.ownerId != ShorterModel.ownerId
            && (profile.firstName.contains(searchText) || profile.lastName.contains(searchText))
        }
        
        withAnimation { self.filteredProfiles = results }
    }
    
//    MARK: getContacts
//    returns the ownerId if it has one, and nil if it doesnt
    private func contactHasProfile( _ contact: CNContact ) -> String? {
        let phoneNumbers = ContactManager.getPhoneNumbers(for: contact)
        
        let matchingProfiles = filteredProfiles.filter { profile in
            formatString(profile.firstName) == formatString(contact.givenName) &&
            phoneNumbers.contains(where: { num in
                comparePhoneNumbers(num1: profile.phoneNumber, num2: num)
            })
        }
        
        return matchingProfiles.first?.ownerId
    }
    
    @MainActor
    private func retrieveContacts( in searchText: String ) async {
        let contacts = contactManager.fetchContacts(for: searchText)
        
        let filteredContacts: [ContactWrapper] = contacts.compactMap({ contact in
            let ownerId = contactHasProfile(contact)
            return ContactWrapper(contact: contact, profileId: ownerId)
        })
        
        withAnimation { self.filteredContacts = filteredContacts }
    }
    
    func search(in searchText: String) async {

        await self.retrieveDataBaseProfiles(in: searchText)
        await self.retrieveContacts(in: searchText)
        
    }
    
}
