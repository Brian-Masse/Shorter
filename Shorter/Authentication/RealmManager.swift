//
//  RealmManager.swift
//  Cactus
//
//  Created by Brian Masse on 6/20/24.
//

import Foundation
import RealmSwift
import Realm
import AuthenticationServices
import SwiftUI

//RealmManager is responsible for signing/logging in users, opening a realm, and any other
//high level function.
final class RealmManager: ObservableObject {
    
    public enum AuthenticationState: String {
        case authenticating
        case openingRealm
        case creatingProfile
        case error
        case complete
    }
    
    static let defaultId = "66759d000ae4d97657a322dd"
    
    static let defaults = UserDefaults.standard
    
    static let appID = "application-0-ecwqhth"
    
    static let shared: RealmManager = RealmManager()
    
    //    This realm will be generated once the profile has authenticated themselves
    var realm: Realm!
    var app = RealmSwift.App(id: RealmManager.appID)
    var configuration: Realm.Configuration!
    
    //    This is the realm profile that signed into the app
    var user: User?
    
    //    These variables are just temporary storage until the realm is initialized, and can be put in the database
    var firstName: String = ""
    var lastName: String = ""
    var email: String = ""
    
    @Published private(set) var authenticationState: AuthenticationState = .authenticating
    
    //   if the user uses signInWithApple, this will be set to true once it successfully retrieves the credentials
    //   Then the app will bypass the setup portion that asks for your first and last name
    static var usedSignInWithApple: Bool = false
    
//    MARK: Initialization
    @MainActor
    func setState( _ newState: AuthenticationState ) {
        withAnimation {
            self.authenticationState = newState
        }
    }
    
    
//    MARK: Realm Functions
    @MainActor
    static func transferOwnership<T: Object>(of object: T, to newID: String) where T: OwnedRealmObject {
        updateObject(object) { thawed in
            thawed.ownerID = newID
        }
    }
    
    //    in all add, update, and delete transactions, the user has the option to pass in a realm
    //    if they want to write to a different realm.
    //    This is a convenience function either choose that realm, if it has a value, or the default realm
    static func getRealm(from realm: Realm?) -> Realm {
        realm ?? RealmManager.shared.realm
    }
    
    static func writeToRealm(_ realm: Realm? = nil, _ block: () -> Void ) {
        do {
            if getRealm(from: realm).isInWriteTransaction { block() }
            else { try getRealm(from: realm).write(block) }
            
        } catch { print("ERROR WRITING TO REALM:" + error.localizedDescription) }
    }
    
    static func updateObject<T: Object>(realm: Realm? = nil, _ object: T, _ block: (T) -> Void, needsThawing: Bool = true) {
        
        RealmManager.writeToRealm(realm) {
            guard let thawed = object.thaw() else {
                print("failed to thaw object: \(object)")
                return
            }
            
            block(thawed)
        }
    }
    
    static func addObject<T:Object>( _ object: T, realm: Realm? = nil ) {
        self.writeToRealm(realm) {
            getRealm(from: realm).add(object) }
    }
    
    static func retrieveObject<T:Object>( realm: Realm? = nil, where query: ( (Query<T>) -> Query<Bool> )? = nil ) -> Results<T> {
        if query == nil { return getRealm(from: realm).objects(T.self) }
        else { return getRealm(from: realm).objects(T.self).where(query!) }
    }
    
    @MainActor
    static func retrieveObjects<T: Object>(realm: Realm? = nil, where query: ( (T) -> Bool )? = nil) -> [T] {
        if query == nil { return Array(getRealm(from: realm).objects(T.self)) }
        else { return Array(getRealm(from: realm).objects(T.self).filter(query!)  ) }
    }
    
    static func deleteObject<T: RealmSwiftObject>( _ object: T, where query: @escaping (T) -> Bool, realm: Realm? = nil ) where T: Identifiable {
        
        if let obj = getRealm(from: realm).objects(T.self).filter( query ).first {
            self.writeToRealm {
                getRealm(from: realm).delete(obj)
            }
        }
    }
    
//    MARK: Helper Functions
    func addGenericSubcriptions<T>(realm: Realm? = nil, name: String, query: @escaping ((Query<T>) -> Query<Bool>) ) async -> T? where T:RealmSwiftObject  {
        let localRealm = (realm == nil) ? self.realm! : realm!
        let subscriptions = localRealm.subscriptions
        
        do {
            try await subscriptions.update {
                
                let querySub = QuerySubscription(name: name, query: query)
                
                if checkSubscription(name: name, realm: localRealm) {
                    if let foundSubscriptions = subscriptions.first(named: name) {
                        foundSubscriptions.updateQuery(toType: T.self, where: query)
                    }
                }
                else { subscriptions.append(querySub) }
            }
        } catch { print("error adding subcription: \(error)") }
        
        return nil
    }
    
    func removeSubscription(name: String) async {
        let subscriptions = self.realm.subscriptions
        let foundSubscriptions = subscriptions.first(named: name)
        if foundSubscriptions == nil {return}
        
        do {
            try await subscriptions.update{
                subscriptions.remove(named: name)
            }
        } catch { print("error adding subcription: \(error)") }
    }
    
    private func checkSubscription(name: String, realm: Realm) -> Bool {
        let subscriptions = realm.subscriptions
        let foundSubscriptions = subscriptions.first(named: name)
        return foundSubscriptions != nil
    }
    
    func removeAllNonBaseSubscriptions() async {
        
        if let realm = self.realm {
            if realm.subscriptions.count > 0 {
                for subscription in realm.subscriptions {
                    //                    if !QuerySubKey.allCases.contains(where: { key in
                    //                        key.rawValue == subscription.name
                    //                    }) {
                    await self.removeSubscription(name: subscription.name!)
                    
                    //                    }
                }
            }
        }
    }
}
    
protocol OwnedRealmObject: Object {
    var ownerID: String { get set }
}
