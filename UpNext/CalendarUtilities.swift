//
//  CalendarUtilities.swift
//  UpNext
//
//  Created by Koen Vendrik on 2020-04-10.
//  Copyright © 2020 Koen Vendrik. All rights reserved.
//

import EventKit

struct CalendarUtilities {
    func getEventsForRestOfDay(calendars: [EKCalendar], store: EKEventStore) -> [EKEvent] {
        var endOfDayDateComponent = DateComponents()
        endOfDayDateComponent.day = 1
        endOfDayDateComponent.second = -1

        let endOfDay = Calendar.current.date(byAdding: endOfDayDateComponent, to: Calendar.current.startOfDay(for: Date()))!
        
        let predicate = store.predicateForEvents(withStart: Date(), end: endOfDay, calendars: calendars)
        let events = store.events(matching: predicate)
        
        return events
    }
    
    func requestCalendarAccess(store: EKEventStore, onAccess: @escaping () -> Void) {
        store.requestAccess(to: EKEntityType.event) { (granted: Bool, error: Optional<Error>) -> () in
            if granted {
                print("Got access")
                onAccess()
            } else {
                print("The app is not permitted to access reminders, make sure to grant permission in the settings and try again")
            }
        }
    }
    
    func prettyTimeUntilEvent(_ event: EKEvent) -> String {
        let calendar = Calendar.current
        let timeUntil = calendar.dateComponents([.hour, .minute, .second], from: Date(), to: event.startDate)
        var timeString = ""
        
        let hour = timeUntil.hour!
        let minute = timeUntil.minute!

        if hour > 0 {
            timeString = " in "+String(hour)+pluralize(hour, " hour")
        } else if minute > 0 {
            timeString = " in "+String(minute)+pluralize(minute, " minute")
        } else {
            timeString = " now"
        }

        return event.title+timeString
    }
    
    private func pluralize(_ amount: Int, _ str: String) -> String {
        return amount > 1 ? str+"s" : str;
    }
}
