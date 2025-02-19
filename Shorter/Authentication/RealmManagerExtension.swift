//
//  RealmManagerExtension.swift
//  Shorter
//
//  Created by Brian Masse on 6/22/24.
//

import Foundation
import RealmSwift
import Realm
import AuthenticationServices
import SwiftUI
import WidgetKit


extension RealmManager {
    
    //    MARK: Subscriptions
    //    These can add, remove, and return compounded queries. During the app lifecycle, they'll need to change based on the current view
    var shorterPostQuery: (QueryPermission<ShorterPost>) {
        .init(named: QuerySubKey.shorterPostQuery.rawValue) { query in
            query.ownerId == ShorterModel.ownerId || query.sharedOwnerIds.contains( ShorterModel.ownerId )
        }
    }
    
    var shorterProfileQuery: (QueryPermission<ShorterProfile>) {
        .init(named: QuerySubKey.shorterProfileQuery.rawValue) { query in
            query.ownerId == ShorterModel.ownerId || query.friendIds.contains(ShorterModel.ownerId)
        }
    }
    
    var timingManagerQuery: (QueryPermission<TimingManager>) {
        .init(named: QuerySubKey.timingManager.rawValue) { query in
            query.author == RealmManager.defaultId
        }
    }
    
    //    MARK: Convenience Functions
    static func stripEmail(_ email: String) -> String {
        email.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
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
    
//    once a user is signed in, save their ownerID to the defaults shared between the app
//    and the widget extension so the widgets can query data properly
    private func saveOwnerId() {
        if let defaults = UserDefaults(suiteName: WidgetKeys.suiteName) {
            defaults.set(ShorterModel.ownerId, forKey: WidgetKeys.ownerIdKey)
        }
    }
    
    @MainActor
    private func postAuthenticationInit() {
        self.saveOwnerId()
        self.setConfiguration()
        self.setState(.openingRealm)
    }
    
    //    MARK: Logout
    @MainActor
    func removeRealmFile() {
        do {
            try FileManager.default.removeItem(at: Realm.Configuration.defaultConfiguration.fileURL!)
        } catch {
            print("error deleting realm file: \(error.localizedDescription)")
        }
    }
    
    @MainActor
    func logoutUser() {
        if let user = self.user {
            user.logOut { error in
                if let err = error { print("error logging out: \(err.localizedDescription)") }
                
                DispatchQueue.main.async {
                    NotificationManager.shared.clearNotifications()
                    ShorterModel.shared.profile?.logout()
                    self.setState(.authenticating)
                }
            }
        }
        Task { await self.removeAllNonBaseSubscriptions() }
        
        self.user = nil
    }
    
    //    MARK: SetConfiguration
    private func addInitialSubscription<T: Object>(_ query: QueryPermission<T>, to subs: SyncSubscriptionSet ) {
        let subscription = query.getSubscription()
        
        if subs.first(named: query.name) == nil {
            subs.append(subscription)
        }
    }
    
    @MainActor
    private func setConfiguration() {
        self.configuration = user?.flexibleSyncConfiguration(initialSubscriptions: { subs in
            self.addInitialSubscription(self.shorterProfileQuery, to: subs)
            self.addInitialSubscription(self.shorterPostQuery, to: subs)
            self.addInitialSubscription(self.timingManagerQuery, to: subs)
        })
        
        self.configuration.objectTypes = [ ShorterPost.self, ShorterProfile.self, TimingManager.self ]
    }
    
    
    //    MARK: Profile Functions
    @MainActor
    func deleteProfile() async {
        self.logoutUser()
    }
    
    //    This checks the user has created a profile with Recall already
    //    if not it will trigger the ProfileCreationScene
    @MainActor
    func checkProfile() async {
        if let profile: ShorterProfile = RealmManager.retrieveObject(where: { query in
            query.ownerId == ShorterModel.ownerId
        }).first {
            self.registerProfile(profile)
            if profile.isComplete {
                self.setState(.complete)
            }
            
        } else {
            let templateProfile = ShorterProfile(ownerId: ShorterModel.ownerId, email: self.email)
            
            RealmManager.addObject(templateProfile)
            
            self.registerProfile(templateProfile)
        }
    }
    
    //    If the user does not have an index, create one and add it to the database
    private func createProfile() {
        //        TODO: Create a template profile, and then move the user into the creating a profile scene
    }
    
    //    whether you're loading the profile from the databae or creating at startup, it should go throught this function to
    //    let the model know that the profile now has a profile and send that profile object to the model
    private func registerProfile(_ profile: ShorterProfile) {
        ShorterModel.shared.profile = profile
        profile.saveFriendListToDefaults()
    }
    
    //    MARK: Realm Loading Functions
    //    Called once the realm is loaded in OpenSyncedRealmView
    @MainActor
    func authRealm(realm: Realm) async {
        self.realm = realm
        self.setState(.creatingProfile)
        await self.checkProfile()
    }
    
    @MainActor
    func transferDataOwnership(to ownerID: String) {
        //        TODO: Implement Transfer Data Ownership
    }
    
//    MARK: Refresh Subscripton
    func refreshSubscriptions() async {
        await removeSubscription(name: QuerySubKey.shorterPostQuery.rawValue)
        
        let shorterPostQuery: (QueryPermission<ShorterPost>) = .init(named: QuerySubKey.shorterPostQuery.rawValue) { query in
            query.ownerId == ShorterModel.ownerId || query.sharedOwnerIds.contains( ShorterModel.ownerId )
        }
     
        let _ = await self.addGenericSubcriptions(name: shorterPostQuery.name, query: shorterPostQuery.query)
        
    }
    
    func addBlockedUserSubscription() async {
        let _ : ShorterProfile? = await self.addGenericSubcriptions(name: QuerySubKey.blockedUsersQuery.rawValue) { query in
            query.blockingIds.contains( ShorterModel.ownerId )
        }
    }
    
    func removeBlockedUserSubscription() async {
        await self.removeSubscription(name: QuerySubKey.blockedUsersQuery.rawValue)
    }
}

