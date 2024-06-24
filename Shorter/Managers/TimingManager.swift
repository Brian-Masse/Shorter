//
//  TimingManager.swift
//  Shorter
//
//  Created by Brian Masse on 6/22/24.
//

import Foundation
import RealmSwift
import UIUniversals

class TimingManager: Object {
    
    @Persisted(primaryKey: true) var _id: ObjectId
    
    @Persisted var seed: RealmSwift.List<Double> = List()
    @Persisted var author: String = "66759d000ae4d97657a322dd"
    
//    a non even number, not divisble by months, weeks, or years
    static let seedLength: Int = 137
    
    static let startHour: Double = 9
    static let endHour: Double = 23
    
    static let offset: Double = 1719028800
    
    convenience init(_ key: String) {
        self.init()
        
        if key != RealmManager.defaultId { return }

        let seed: RealmSwift.List<Double> = List()
        
        for _ in 0...TimingManager.seedLength {
            let random = Double.random(in: 0...1)
            seed.append(random)
        }

        self.seed = seed
        
        RealmManager.addObject(self)
    }
    
    static func getStartDate() -> Date {
        var startDateComponents = DateComponents()
        startDateComponents.day = 22
        startDateComponents.month = 06
        startDateComponents.year = 2024
        
        let startDate = Calendar.current.date(from: startDateComponents)
        return startDate!
    }
    
    @MainActor
    static func getFiringTime( for date: Date ) -> Date {
        
        let startDate = TimingManager.getStartDate()
        let correctedDate = date.timeIntervalSince1970 < startDate.timeIntervalSince1970 ? startDate : date
        
        let timeInterval = correctedDate.timeIntervalSince1970 - offset
        let days: Int = Int(floor(timeInterval / Constants.DayTime))
        
        if let timingManager: TimingManager = RealmManager.retrieveObjects().first {
            let value = timingManager.seed[ days % seedLength ]
            
            let time = Constants.HourTime * ( endHour - startHour ) * value
            
            let hours = time / Constants.HourTime
            let minutes = (hours - floor(hours)) * 60
            
            let newDate = Calendar.current.date(bySettingHour: Int(floor(hours) + startHour),
                                                minute: Int(floor(minutes)),
                                                second: 0,
                                                of: correctedDate.resetToStartOfDay())
            
            return newDate ?? .now
        }
        
        return .now
    }
    
    @MainActor
    static func getPreviousFiringTime() -> Date {
        
        let firingForToday = TimingManager.getFiringTime(for: .now)
        
        if firingForToday < .now {
            return firingForToday
        } else {
         
            let yesterday = .now.resetToStartOfDay() - Constants.DayTime
            return TimingManager.getFiringTime(for: yesterday)
            
        }
    }
}

