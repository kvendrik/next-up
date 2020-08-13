//
//  AppDelegate.swift
//  TextTransform
//
//  Created by Koen Vendrik on 2020-04-10.
//  Copyright © 2020 Koen Vendrik. All rights reserved.
//

// TODO:
// - Add location to events
// - Add Join hangout link option for current ongoing event
// - Optimize perf (no unneccesary runs or checks in timer, also do we need the timer?)
// - Learn about testing

import EventKit
import Cocoa

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {
    private var selectedCalendars: [EKCalendar]? = nil
    private var currentTimer: Timer? = nil
    private var events: [EKEvent]? = nil
    private var nextEvent: EKEvent? = nil
    private let utilities = CalendarUtilities()
    private let statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
    private let store = EKEventStore()

    func applicationDidFinishLaunching(_ aNotification: Notification) {
        statusItem.button?.target = self
        utilities.requestCalendarAccess(store: store) {
            DispatchQueue.main.async {
                let calendars = self.store.calendars(for: .event)

                if calendars.isEmpty {
                    return;
                }
                
                let selectedCalendars = [calendars.first(where: { $0.calendarIdentifier == self.store.defaultCalendarForNewEvents?.calendarIdentifier })!]
                let calendarsMenu = self.constructCalendarsMenu(calendars: calendars, selectedCalendars: selectedCalendars)
                
                let events = self.utilities.getEventsForRestOfDay(calendars: selectedCalendars, store: self.store)
                let mainMenu = self.constructMainMenuSkeleton(calendarsMenu: calendarsMenu, events: events)

                self.statusItem.menu = mainMenu
                self.selectedCalendars = selectedCalendars
                self.switchToCalendar(selectedCalendars, events: events)
                NotificationCenter.default.addObserver(self, selector: #selector(self.handleCalendarUpdate), name: .EKEventStoreChanged, object: self.store)
            }
        }
    }
    
    @objc private func handleCalendarUpdate() {
        let events = utilities.getEventsForRestOfDay(calendars: selectedCalendars!, store: self.store)
        switchToCalendar(selectedCalendars!, events: events)
    }
    
    private func updateTopBarButtonTextForEvent(_ event: EKEvent?) {
        if event == nil {
            statusItem.button?.title = "No upcoming meetings"
            return
        }
        
        let prettyTime = utilities.prettyTimeUntilEvent(event!)
        let locationLabel = parseLocation(event?.location) ?? ""
        
        statusItem.button?.title = (event?.title ?? "")+prettyTime+locationLabel
    }
    
    private func switchToCalendar(_ calendars: [EKCalendar], events: [EKEvent]) {
        let nextEvent = utilities.getNextEvent(events)
        let menu = statusItem.menu!
        
        updateTopBarButtonTextForEvent(nextEvent)

        for item in menu.items {
            if let details = item.representedObject as? NSDictionary {
                if (details["type"] as! String == "event") {
                    menu.removeItem(item)
                }
            }
        }
        
        if currentTimer != nil {
            currentTimer?.invalidate()
            currentTimer = nil
        }
        
        if nextEvent == nil {
            return
        }
        
        
        let joinMeetingItem = menu.item(withTitle: "Join via Google Meet...")!
        joinMeetingItem.action = nil

        if nextEvent != nil {
            if utilities.getHangoutsLinkFromEvent(nextEvent!) != nil {
                joinMeetingItem.action = #selector(joinNextEventMeetingUrl)
            }
        }
        
        let eventsTitleItemIndex = menu.indexOfItem(withTitle: "Up Next") + 1

        for (index, eventItem) in constructEventItems(events).enumerated() {
            menu.insertItem(eventItem, at: eventsTitleItemIndex + index)
        }
        
        currentTimer = getNextEventValidationTimer(getEfficientNextEventTimerInterval(nextEvent!))

        self.events = events
        self.nextEvent = nextEvent
    }
    
    @objc private func joinNextEventMeetingUrl(_ item: NSMenuItem) {
        if (nextEvent == nil) {
            return
        }
        
        let meetingUrl = utilities.getHangoutsLinkFromEvent(nextEvent!)!
        NSWorkspace.shared.open(meetingUrl)
    }
    
    @objc private func validateNextEventData() {
        let nextEvent = utilities.getNextEvent(events!)
        
        if nextEvent == nil || nextEvent!.title != self.nextEvent!.title {
            switchToCalendar(selectedCalendars!, events: events!)
            return
        }
        
        updateTopBarButtonTextForEvent(nextEvent)
        
        let interval = getEfficientNextEventTimerInterval(nextEvent!)
        
        if interval != currentTimer?.timeInterval {
            currentTimer?.invalidate()
            currentTimer = getNextEventValidationTimer(interval)
        }
    }
    
    private func getNextEventValidationTimer(_ interval: Double) -> Timer {
        return Timer.scheduledTimer(timeInterval: interval, target: self, selector: #selector(validateNextEventData), userInfo: nil, repeats: true)
    }
    
    private func getEfficientNextEventTimerInterval(_ event: EKEvent) -> Double {
        let timeUntil = utilities.timeUntilEvent(event)
        let hoursAmount = timeUntil.hour!
        var interval = 60.0
        
        if hoursAmount > 1 {
            // At 1 hour mark you want to update the timer
            // to trigger every minute so you get a "59 minutes left"
            // status when appropriate. If hours is more than 1 hour say 3
            // we can optimize performance by saying you get 2 hours before
            // we check again
            interval = Double(hoursAmount - 1) * 60.0
        }
        
        return interval
    }
    
    private func constructMainMenuSkeleton(calendarsMenu: NSMenu, events: [EKEvent]) -> NSMenu {
        let menu = NSMenu()
        let calendarsItem = NSMenuItem(title: "Calendars", action: nil, keyEquivalent: "")
        let joinGoogleMeetItem = NSMenuItem(title: "Join via Google Meet...", action: nil, keyEquivalent: "j")
        
        menu.addItem(joinGoogleMeetItem)
        menu.addItem(NSMenuItem.separator())

        menu.addItem(NSMenuItem(title: "Up Next", action: nil, keyEquivalent: ""))
        menu.addItem(NSMenuItem.separator())
        
        menu.addItem(calendarsItem)
        menu.setSubmenu(calendarsMenu, for: calendarsItem)

        menu.addItem(NSMenuItem.separator())
        menu.addItem(NSMenuItem(title: "About Up Next", action: #selector(openAboutLink), keyEquivalent: ""))
        menu.addItem(NSMenuItem(title: "Quit", action: #selector(quitApplication), keyEquivalent: ""))
        
        return menu
    }
    
    @objc private func quitApplication() {
        NSApplication.shared.terminate(self)
    }
    
    @objc private func openAboutLink() {
        NSWorkspace.shared.open(URL(string: "https://github.com/kvendrik/up-next")!)
    }
    
    @objc private func openGoogleCalendar() {
        NSWorkspace.shared.open(URL(string: "https://calendar.google.com/calendar/r/week")!)
    }
    
    private func constructEventItems(_ events: [EKEvent]) -> [NSMenuItem] {
        var menuItems: [NSMenuItem] = []
        
        let dateFormatter = DateFormatter()

        dateFormatter.timeStyle = DateFormatter.Style.short
        dateFormatter.dateStyle = .none
        
        for event in events {
            if event.isAllDay {
                continue
            }

            let time = dateFormatter.string(from: event.startDate)
            let meetingUrl = utilities.getHangoutsLinkFromEvent(event)
            
            let locationLabel = parseLocation(event.location) ?? ""
            let item = NSMenuItem(title: time+" - "+event.title+locationLabel, action: meetingUrl == nil ? #selector(openGoogleCalendar) : #selector(openEventMeetingUrl), keyEquivalent: "")

            item.representedObject = ["type": "event", "meetingUrl": meetingUrl as Any]
            
            menuItems.append(item)
        }
        
        return menuItems
    }
    
    private func parseLocation(_ location: String?) -> String? {
        if let parts = location?.components(separatedBy: ", ") {
            return " ("+parts[0]+")"
        }
        return nil
    }
    
    private func constructCalendarsMenu(calendars: [EKCalendar], selectedCalendars: [EKCalendar]) -> NSMenu {
        let calendarsMenu = NSMenu()

        for calendar in calendars {
            let item = NSMenuItem(title: calendar.title, action: #selector(toggleCalendarItemState), keyEquivalent: "")
            let isSelected = selectedCalendars.contains { $0.calendarIdentifier == calendar.calendarIdentifier }
            item.representedObject = calendar
            item.state = isSelected ? .on : .off
            calendarsMenu.addItem(item)
        }

        return calendarsMenu
    }
    
    @IBAction private func openEventMeetingUrl(_ item: NSMenuItem) {
        if let details = item.representedObject as? Dictionary<String, Any> {
            if let meetingUrl = details["meetingUrl"] as? URL {
                NSWorkspace.shared.open(meetingUrl)
            }
        }
    }
    
    @IBAction private func toggleCalendarItemState(_ item: NSMenuItem) {
        let newState = item.state == NSControl.StateValue.on ? NSControl.StateValue.off : NSControl.StateValue.on
        let selectedCalendar = item.representedObject as! EKCalendar
        var newSelectedCalendars = selectedCalendars!
        
        if newState == NSControl.StateValue.on {
            newSelectedCalendars.append(selectedCalendar)
        } else {
            newSelectedCalendars.removeAll { $0.calendarIdentifier == selectedCalendar.calendarIdentifier }
        }

        let events = utilities.getEventsForRestOfDay(calendars: newSelectedCalendars, store: self.store)
        
        item.state = newState

        self.selectedCalendars = newSelectedCalendars
        switchToCalendar(newSelectedCalendars, events: events)
    }
}

