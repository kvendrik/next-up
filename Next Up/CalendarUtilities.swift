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
        if calendars.count == 0 {
            return []
        }
        
        var endOfDayDateComponent = DateComponents()
        endOfDayDateComponent.day = 1
        endOfDayDateComponent.second = -1

        let endOfDay = Calendar.current.date(byAdding: endOfDayDateComponent, to: Calendar.current.startOfDay(for: Date()))!
        
        let predicate = store.predicateForEvents(withStart: Date(), end: endOfDay, calendars: calendars)
        let events = store.events(matching: predicate)
        
        return events
    }
    
    func requestCalendarAccess(store: EKEventStore, onAccess: @escaping () -> Void, onError: @escaping () -> Void) {
        store.requestAccess(to: EKEntityType.event) { (granted: Bool, error: Optional<Error>) -> () in
            if granted {
                print("Got access")
                onAccess()
            } else {
                print("No access")
                onError()
            }
        }
    }
    
    func timeUntilEvent(_ event: EKEvent) -> DateComponents {
        let calendar = Calendar.current
        return calendar.dateComponents([.hour, .minute, .second], from: Date(), to: event.startDate)
    }
    
    func prettyTimeUntilEvent(_ event: EKEvent) -> String {
        let timeUntil = timeUntilEvent(event)
        var timeString = ""
        
        let hour = timeUntil.hour!
        let minute = timeUntil.minute!

        if hour > 0 {
            timeString = " in "+String(hour)+pluralize(hour, " hour")
        } else if minute > 0 {
            timeString = " in "+String(minute)+" min"
        } else {
            timeString = " now"
        }

        return timeString
    }
    
    func getNextEvent(_ events: [EKEvent]) -> EKEvent? {
        if events.isEmpty {
            return nil
        }

        let currentOrNextEvent = findNextEvent(events, skip: 0)!
        let currentDate = Date()
        
        let calendar = Calendar.current
        let eventDuration = calendar.dateComponents([.minute], from: currentOrNextEvent.startDate, to: currentOrNextEvent.endDate)
        let startPlusPercentageDuration = Calendar.current.date(byAdding: .minute, value: eventDuration.minute! / 3, to: currentOrNextEvent.startDate)
        
        if currentDate > startPlusPercentageDuration! {
            if let nextCurrentOrNextEvent = findNextEvent(events, skip: 1) {
                return nextCurrentOrNextEvent
            }
        }
        
        return currentOrNextEvent
    }
    
    private func findNextEvent(_ events: [EKEvent], skip: Int) -> EKEvent? {
        var currentIndex = 0
        var skippedCount = 0

        while events[currentIndex].isAllDay || skippedCount != skip {
            if !events[currentIndex].isAllDay {
                skippedCount += 1
            }
            
            currentIndex += 1
            
            if currentIndex >= events.count {
                return nil
            }
        }
        
        return events[currentIndex]
    }
    
    func getHangoutsLinkFromEvent(_ event: EKEvent) -> URL? {
        if event.notes == nil {
            return nil
        }

        let detector = try! NSDataDetector(types: NSTextCheckingResult.CheckingType.link.rawValue)
        let matches = detector.matches(in: event.notes!, options: [], range: NSRange(location: 0, length: event.notes!.utf16.count))
        
        for match in matches {
            if match.url?.host == "hangouts.google.com" || match.url?.host == "meet.google.com" {
                return match.url
            }
        }
        
        return nil
    }
    
    func parseLocationForEventLabel(_ location: String?) -> String? {
        if let parts = location?.components(separatedBy: ", ") {
            return " ("+parts[0]+")"
        }
        return nil
    }
    
    private func pluralize(_ amount: Int, _ str: String) -> String {
        return amount > 1 ? str+"s" : str;
    }
}
