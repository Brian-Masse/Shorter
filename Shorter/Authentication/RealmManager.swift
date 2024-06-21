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
    
    static let defaults = UserDefaults.standard
    
    static let appID = "application-0-ecwqhth"
    
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
    //    These can add, remove, and return compounded queries. During the app lifecycle, they'll need to change based on the current view
    
    @MainActor lazy var shorterPostQuery: (QueryPermission<ShorterPost>) = QueryPermission { query in
        query.ownerId == ShorterModel.ownerId || query.sharedOwnerIds.contains( ShorterModel.ownerId )
    }
    
    
    init() {
        Task { await self.checkLogin() }
    }
    
    //    MARK: Convenience Functions
    static func stripEmail(_ email: String) -> String {
        email.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
    }
    
    @MainActor
    func setState( _ newState: AuthenticationState ) {
        withAnimation {
            self.authenticationState = newState
        }
    }
    
    //    MARK: SignInWithAppple
    //    most of the authenitcation / registration is handled by Apple
    //    All I need to do is check that nothing went wrong, and then move the signIn process along
    func signInWithApple(_ authorization: ASAuthorization) {
        
        switch authorization.credential {
        case let credential as ASAuthorizationAppleIDCredential:
            print("successfully retrieved credentials")
            self.email = credential.email ?? ""
            self.firstName = credential.fullName?.givenName ?? ""
            self.lastName = credential.fullName?.familyName ?? ""
            
            if let token = credential.identityToken {
                let idTokenString = String(data: token, encoding: .utf8)
                let realmCredentials = Credentials.apple(idToken: idTokenString!)
                
                RealmManager.usedSignInWithApple = true
                Task { await ShorterModel.realmManager.authenticateOnlineUser(credentials: realmCredentials ) }
                
            } else {
                print("unable to retrieve idenitty token")
            }
            
        default:
            print("unable to retrieve credentials")
            break
        }
    }
    
    //    MARK: SignInWithPassword
    //    the basic flow, for offline and online, is to
    //    1. check the email + password are valid (reigsterUser)
    //    2. authenticate the user (save their information into defaults or Realm)
    //    3. postAuthenticatinInit (move onto opening the realm)
    func signInWithPassword(email: String, password: String) async -> String? {
        
        let fixedEmail = RealmManager.stripEmail(email)
        
        let error =  await registerOnlineUser(fixedEmail, password)
        if error == nil {
            let credentials = Credentials.emailPassword(email: fixedEmail, password: password)
            self.email = fixedEmail
            let secondaryError = await authenticateOnlineUser(credentials: credentials)
            
            if secondaryError != nil {
                print("error authenticating registered user")
                return secondaryError!.localizedDescription
            }
            
            return nil
        }
        
        print( "error authenticating register user: \(error!.localizedDescription)" )
        return error!.localizedDescription
    }
    
    //    only needs to run for email + password signup
    //    checks whether the provided email + password is valid
    private func registerOnlineUser(_ email: String, _ password: String) async -> Error? {
        
        let client = app.emailPasswordAuth
        do {
            try await client.registerUser(email: email, password: password)
            return nil
        } catch {
            if error.localizedDescription == "name already in use" { return nil }
            print("failed to register user: \(error.localizedDescription)")
            return error
        }
    }
    
    //        this simply logs the profile in and returns any status errors
    //        Once done, it moves the app onto the loadingRealm phase
    func authenticateOnlineUser(credentials: Credentials) async -> Error? {
        do {
            self.user = try await app.login(credentials: credentials)
            await self.postAuthenticationInit()
            return nil
        } catch { print("error logging in: \(error.localizedDescription)"); return error }
    }
    
    //    MARK: Login / Authentication Functions
    //    If there is a user already signed in, skip the user authentication system
    //    the method for checking if a user is signedIn is different whether you're online or offline
    @MainActor
    func checkLogin() {
        if let user = app.currentUser {
            self.user = user
            self.postAuthenticationInit()
        }
    }
    
    @MainActor
    private func postAuthenticationInit() {
        self.setConfiguration()
        self.setState(.openingRealm)
    }
    
    //    MARK: Logout
    @MainActor
    func logoutUser(onMain: Bool = false){
        
        if let user = self.user {
            user.logOut { error in
                if let err = error { print("error logging out: \(err.localizedDescription)") }
                
                DispatchQueue.main.async {
                    self.setState(.authenticating)
                }
            }
        }
        Task {
            await self.removeAllNonBaseSubscriptions()
        }
        
        self.user = nil
    }
    
    //    MARK: SetConfiguration
    private func setConfiguration() {
        self.configuration = user?.flexibleSyncConfiguration()
    }
    
    
    //    MARK: Profile Functions
    @MainActor
    func deleteProfile() async {
        self.logoutUser(onMain: true)
    }
    
    //    This checks the user has created a profile with Recall already
    //    if not it will trigger the ProfileCreationScene
    @MainActor
    func checkProfile() async {
        //        TODO: Check if the person has a profile or not, and if not go through the process to create one
        self.setState(.complete)
    }
    
    //    If the user does not have an index, create one and add it to the database
    private func createProfile() {
        //        TODO: Create a template profile, and then move the user into the creating a profile scene
    }
    
    //    whether you're loading the profile from the databae or creating at startup, it should go throught this function to
    //    let the model know that the profile now has a profile and send that profile object to the model
    private func registerProfile() {
        //        TODO: Save a reference of the profile into the model
    }
    
    //    MARK: Realm Loading Functions
    //    Called once the realm is loaded in OpenSyncedRealmView
    @MainActor
    func authRealm(realm: Realm) async {
        self.realm = realm
        await self.addSubcriptions()
        
        await self.checkProfile()
        self.setState(.creatingProfile)
    }
    
    //    MARK: Subscription Functions
    //    Subscriptions are only used when the app is online
    //    otherwise you are able to retrieve all the data from the Realm by default
    private func addSubcriptions() async {
        await self.removeAllNonBaseSubscriptions()
        
        let _ : ShorterPost? = await addGenericSubcriptions(name: QuerySubKey.shorterPostQuery.rawValue,
                                                                         query: shorterPostQuery.baseQuery)
    }
    
    //    MARK: Helper Functions
    func addGenericSubcriptions<T>(realm: Realm? = nil, name: String, query: @escaping ((Query<T>) -> Query<Bool>) ) async -> T? where T:RealmSwiftObject  {
        let localRealm = (realm == nil) ? self.realm! : realm!
        let subscriptions = localRealm.subscriptions
        
        do {
            try await subscriptions.update {
                
                let querySub = QuerySubscription(name: name, query: query)
                
                if checkSubscription(name: name, realm: localRealm) {
                    let foundSubscriptions = subscriptions.first(named: name)!
                    foundSubscriptions.updateQuery(toType: T.self, where: query)
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
    
    @MainActor
    func transferDataOwnership(to ownerID: String) {
        //        TODO: Implement Transfer Data Ownership
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
        realm ?? ShorterModel.realmManager.realm
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
}
    
protocol OwnedRealmObject: Object {
    var ownerID: String { get set }
}
