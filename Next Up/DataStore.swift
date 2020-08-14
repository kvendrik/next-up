//
//  Store.swift
//  Next Up
//
//  Created by Koen Vendrik on 2020-08-14.
//  Copyright © 2020 Koen Vendrik. All rights reserved.
//

import EventKit

struct DataStore {
    private let userDefaults = UserDefaults()

    func getSelectedCalendars(_ calendars: [EKCalendar], defaultCalendarId: String?) -> [EKCalendar] {
        if let selectedCalendarIds = self.userDefaults.stringArray(forKey: "selectedCalendars") {
            return calendars.filter { (calendar: EKCalendar) -> Bool in
                selectedCalendarIds.contains(where: {$0 == calendar.calendarIdentifier})
            }
        }
        
        if let defaultCalendarId = defaultCalendarId {
            if let defaultCalendar = calendars.first(where: { $0.calendarIdentifier == defaultCalendarId }) {
                return [defaultCalendar]
            }
        }
        
        return []
    }
    
    func setSelectedCalendars(_ calendars: [EKCalendar]) {
        userDefaults.set(calendars.map { $0.calendarIdentifier }, forKey: "selectedCalendars")
    }
}
