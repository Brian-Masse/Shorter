//
//  NotificationManager.swift
//  Shorter
//
//  Created by Brian Masse on 6/21/24.
//

import Foundation
import NotificationCenter
import Firebase
import FirebaseMessaging


class NotificationManager: ObservableObject {
//    MARK: Vars
    static let shared = NotificationManager()
    
    let current = UNUserNotificationCenter.current()
    
    @Published var notificationsAllowed: Bool = false
    
//    MARK: Class Methods
//    sets the contactsAllowed variable to the permissions the user gives the app
    @MainActor
    private func requestPermission() async {
        do {
            let options: UNAuthorizationOptions = [ .alert, .sound ]
            
            let result = try await current.requestAuthorization(options: options)
            self.notificationsAllowed = result
            
        } catch {
            print( "there was an error requesting contact permissions: \(error.localizedDescription)" )
        }
    }
    
    @MainActor
    func loadStatus() async  {
        
        let result = await current.notificationSettings().authorizationStatus
        
        switch result {
        case .notDetermined:
            await self.requestPermission()
            
        case .denied:
            self.notificationsAllowed = false
        case .authorized:
            self.notificationsAllowed = true
        default:
            self.notificationsAllowed = false
        }
    }
    
    func makeNotificationRequest(from time: Date, title: String, body: String, identifier: String) {
        let content = makeNotificationContent(title: title,
                                              body: body)
        
        let components = Calendar.current.dateComponents([ .hour, .minute ], from: time)
        
        makeCalendarNotificationRequest(components: components,
                                        identifier: identifier,
                                        content: content)
    }
    
    func clearNotifications() {
//        for a list of identifiers, clear the associated notifications
        UNUserNotificationCenter.current().removeDeliveredNotifications(withIdentifiers: [])
    }
    
//    MARK: Production Methods
    private func makeNotificationContent(title: String, body: String) -> UNMutableNotificationContent {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .ringtoneSoundNamed(.init("Tri-tone"))
        return content
    }
    
    private func makeCalendarNotificationRequest(components: DateComponents, identifier: String, content: UNMutableNotificationContent ) {
        
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: true)
        
        let request = UNNotificationRequest(identifier: identifier,
                                            content: content,
                                            trigger: trigger)
        
        UNUserNotificationCenter.current().add(request)
    }
    
}
