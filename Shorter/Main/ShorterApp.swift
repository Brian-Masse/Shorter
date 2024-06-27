//
//  ShorterApp.swift
//  Shorter
//
//  Created by Brian Masse on 6/21/24.
//

import SwiftUI
import UIKit
import Firebase
import FirebaseMessaging
import UserNotifications
import UIUniversals

//MARK: ProxyAppDelegate
//This registers the app for remote notifications
//and initializes firebase + captures a token which is generated at app launch
class ProxyAppDelegate: NSObject, UIApplicationDelegate, ObservableObject, MessagingDelegate, UNUserNotificationCenterDelegate  {
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        
        FirebaseApp.configure()
        
        Messaging.messaging().delegate = self
        UNUserNotificationCenter.current().delegate = self
        
        application.registerForRemoteNotifications()

        return true
    }
    
//    After registering for remote notifications, confirm that it was successful or print the error
//    if it is successful manually give Google the APNs Token
    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        Messaging.messaging().setAPNSToken(deviceToken, type: .unknown)
    }
    
    func application(_ application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: any Error) {
        print( "failed to register device for notifications: \(error.localizedDescription)" )
    }
    
    
    func messaging(_ messaging: Messaging, didReceiveRegistrationToken fcmToken: String?) {
//        messaging.token { token, error in
//            guard let token = token else { return }
//        }
    }
}


//MARK: Main
@main
struct ShorterApp: App {
    
    @UIApplicationDelegateAdaptor private var appDelegate: ProxyAppDelegate
    
//    This sets all the important constants for the UIUniversals Styled to match recall
//    These are initialized on the spot, (as opposed to be constant variables)
//    because they should only be invoked from UIUniversals after this point
    private func setupUIUniversals() {
        Colors.setColors(baseLight:         .init(255, 255, 255),
                         secondaryLight:    .init(240, 240, 240),
                         baseDark:          .init(0, 0, 0),
                         secondaryDark:     .init(15.5, 15.5, 15.5),
                         lightAccent:       .init(63, 45, 64),
                         darkAccent:        .init(212, 178, 214))
        
        Constants.UIDefaultCornerRadius = 20
        
        Constants.setFontSizes(UILargeTextSize: 35,
                               UITitleTextSize: 45,
                               UIMainHeaderTextSize: 35,
                               UIHeaderTextSize: 30,
                               UISubHeaderTextSize: 20,
                               UIDefeaultTextSize: 15,
                               UISmallTextSize: 11)
        
//        This registers all the fonts provided by UIUniversals
        FontProvider.registerFonts()
    }
    
//    before anything is done in the app, make sure UIUniversals is properly initialized
    init() { setupUIUniversals() }
    
    var body: some Scene {
        WindowGroup {
            ShorterView()
        }
    }
}
