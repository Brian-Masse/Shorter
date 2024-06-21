//
//  ContactManager.swift
//  Shorter
//
//  Created by Brian Masse on 6/21/24.
//

import Foundation
import SwiftUI
import Contacts

class ContactManager: ObservableObject {
    
    static let shared: ContactManager = ContactManager()
    
    let store = CNContactStore()
    
    private let keys = [ CNContactGivenNameKey, CNContactFamilyNameKey, CNContactPhoneNumbersKey, CNContactImageDataKey ] as [ CNKeyDescriptor ]
    
    @Published var contactsAllowed: Bool = false
    @Published var retreivedContacts: [CNContact] = []
    
//    MARK: Persmissions
//    sets the contactsAllowed variable to the permissions the user gives the app
    @MainActor
    private func requestPermission() async {
        do {
            let result = try await store.requestAccess(for: .contacts)
            self.contactsAllowed = result
        } catch {
            print( "there was an error requesting contact permissions: \(error.localizedDescription)" )
        }
    }
    
//    converts the results of authorizationStatus into a bool
    @MainActor
    func getStatus() async {
        
        let result = CNContactStore.authorizationStatus(for: .contacts)
        switch result {
        case .notDetermined:
            await self.requestPermission()
            
        case .restricted:
            self.contactsAllowed = true
        case .denied:
            self.contactsAllowed = false
        case .authorized:
            self.contactsAllowed = true
        @unknown default:
            self.contactsAllowed = false
        }
    }
    
//    MARK: Fetch Contacts
    @MainActor
    func fetchContacts(for name: String) -> [CNContact] {
        do {
            let predicate = CNContact.predicateForContacts(matchingName: name)
            let contacts = try store.unifiedContacts(matching: predicate, keysToFetch: keys)
            return contacts
            
        } catch {
            print( "error seraching for contact by name: \(name), \(error.localizedDescription)" )
            return []
        }
    }
    
    @MainActor
    func fetchContacts() async {
        
        await getStatus()
        
        if !self.contactsAllowed { return }
        
        let fetchRequest = CNContactFetchRequest(keysToFetch: keys)
        
        let result = await executeFetchRequest(fetchRequest)
        self.retreivedContacts = result
    }
    
    private func executeFetchRequest( _ fetchRequest: CNContactFetchRequest ) async -> [CNContact] {
        
        let fetchingTask = Task {
            var results: [CNContact] = []
            
            do {
                try store.enumerateContacts(with: fetchRequest) { contact, stop in
                
                    
                    results.append( contact )
                }
            } catch {
                print( "error executing fetch request: \(error.localizedDescription)" )
            }
            
            return results
        }
        
        return try! await fetchingTask.result.get()
        
    }
}
