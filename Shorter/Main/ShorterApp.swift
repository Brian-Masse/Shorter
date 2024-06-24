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
    
    var body: some Scene {
        WindowGroup {
            ShorterView()
        }
    }
}
