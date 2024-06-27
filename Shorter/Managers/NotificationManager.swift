//
//  NotificationManager.swift
//  Shorter
//
//  Created by Brian Masse on 6/21/24.
//

import Foundation
import NotificationCenter
import UIUniversals


class NotificationManager: ObservableObject {
//    MARK: Vars
    static let shared = NotificationManager()
    static let totalNotificationCount: Int = 7
    
    private struct NotificationsDefaultKeys {
        static let suiteName: String = "notificationsDefault"
        static let notifcationEntryBase: String = "notificationEntryBase"
    }
    
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
        
        self.setupFiringDates()
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
        var keys: [String] = []
        
        let defaults = UserDefaults(suiteName: NotificationsDefaultKeys.suiteName)!
        
        for i in 0..<NotificationManager.totalNotificationCount {
            let key = makeKey(for: i)
            keys.append(key)
            
            defaults.removeObject(forKey: key)
        }
        
        UNUserNotificationCenter.current().removeDeliveredNotifications(withIdentifiers: keys)
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
        
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
        
        let request = UNNotificationRequest(identifier: identifier,
                                            content: content,
                                            trigger: trigger)
        
        UNUserNotificationCenter.current().add(request)
    }
    
//    MARK: SetupFiringDates
//    creates several notifications at the specified `random` date / time start at .now
//    once a notification has been created its fire date is saved into UserDefaults
//    if one of the notification firing dates in the UserDefaults has alread run, then it adds an additional
//    notification
    @MainActor
    private func setupFiringDates(_ forceRefresh: Bool = false) {
        if !self.notificationsAllowed { return }
        
        if !self.firingDatesNeedRefresh() && !forceRefresh { return }
        
        print( "refreshing firing dates" )
        
        for i in 0..<NotificationManager.totalNotificationCount {
            let key = makeKey(for: i)
            
            let proposedDate = Date.now.resetToStartOfDay() + (Constants.DayTime * Double(i))
            
            let date = TimingManager.getFiringTime(for: proposedDate)
            
            let components = Calendar.current.dateComponents([ .day, .month, .year, .hour, .minute ],
                                                             from: date)
            
            let content = makeNotificationContent(title: "Notificaiton \(i)", body: "This notification was supposed to be sent at: \( date.formatted(date: .abbreviated, time: .complete) )")
            
            makeCalendarNotificationRequest(components: components,
                                            identifier: key,
                                            content: content)
         
            saveFiringDate(key: key, date: date)
        }
    }
    
    private func makeKey(for index: Int) -> String {
        "\(NotificationsDefaultKeys.notifcationEntryBase)\(index)"
    }
    
    private func saveFiringDate(key: String, date: Date) {
        if let defaults = UserDefaults(suiteName: NotificationsDefaultKeys.suiteName) {
            defaults.setValue(date, forKey: key)
        }
    }
    
//    if the current date is ahead of the first firing date, then all notifications need to be refreshed
    private func firingDatesNeedRefresh() -> Bool {
        if let defaults = UserDefaults(suiteName: NotificationsDefaultKeys.suiteName) {
            let key = makeKey(for: 0)
            
            if let date = defaults.object(forKey: key) as? Date {
                return Date.now.resetToStartOfDay() > date.resetToStartOfDay()
            }
        }
        return true
    }
    
    func readFiringDates() {
        if let defaults = UserDefaults(suiteName: NotificationsDefaultKeys.suiteName) {
            
            for i in 0..<NotificationManager.totalNotificationCount {
                let key = makeKey(for: i)
                
                if let date = defaults.object(forKey: key) as? Date {
                    print( date.formatted() )
                }
            }
        }
    }
}
