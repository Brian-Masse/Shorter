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
    private let selectedSearchQueryKey: String = "selectedSearchQueryKey"
    
    @Published var filteredProfiles: [ShorterProfile] = []
    @Published var filteredContacts: [ContactWrapper] = []
    @Published var selectedProfles: [String] = []
    
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
        if directlyAddProfile {
            Task { await ShorterModel.shared.profile?.toggleFriend(id: id ) }
            return
        }
            
        var mutatingProfiles = selectedProfles
        
        if let index = selectedProfles.firstIndex(of: id) {
            mutatingProfiles.remove(at: index)
        } else {
            mutatingProfiles.append(id)
        }
        
        withAnimation { self.selectedProfles = mutatingProfiles }
    }
    
//    MARK: GetDataBaseProfiles
    @MainActor
    private func retrieveDataBaseProfiles(in searchText: String) async {
        let realmManager = ShorterModel.realmManager
        
        await realmManager.shorterProfileQuery.addQuery(searchQueryKey) { query in
            query.firstName.contains( searchText )
        }
        
        await realmManager.shorterProfileQuery.addQuery(selectedSearchQueryKey) { query in
            query.ownerId.in(self.selectedProfles)
        }
        
        var results: [ShorterProfile] = RealmManager.retrieveObjects()
        results = results
            .filter { profile in
                !ShorterModel.shared.profile!.blockedIds.contains( profile.ownerId ) &&
                !ShorterModel.shared.profile!.blockingIds.contains( profile.ownerId )
            }
            .filter { profile in
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
    
//    MARK: search
    func search(in searchText: String) async {

        await self.retrieveDataBaseProfiles(in: searchText)
        await self.retrieveContacts(in: searchText)
        
    }
    
}
