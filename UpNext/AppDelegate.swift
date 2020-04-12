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

    func applicationWillTerminate(_ aNotification: Notification) {
        // Insert code here to tear down your application
    }
    
    @objc private func handleCalendarUpdate() {
        let events = utilities.getEventsForRestOfDay(calendars: selectedCalendars!, store: self.store)
        switchToCalendar(selectedCalendars!, events: events)
    }
    
    private func switchToCalendar(_ calendars: [EKCalendar], events: [EKEvent]) {
        let nextEvent = utilities.getNextEvent(events)
        let menu = statusItem.menu!
        
        statusItem.button?.title = nextEvent == nil ? "No upcoming meetings" : utilities.prettyTimeUntilEvent(nextEvent!)

        for item in menu.items {
            if item.representedObject as? String == "event" {
                menu.removeItem(item)
            }
        }
        
        if currentTimer != nil {
            currentTimer?.invalidate()
            currentTimer = nil
        }
        
        if nextEvent == nil {
            return
        }
        
        print(nextEvent?.location)
        print(utilities.getHangoutsLinkFromEvent(nextEvent!))
        
        let eventsTitleItemIndex = menu.indexOfItem(withTitle: "Up Next") + 1

        for (index, eventItem) in constructEventItems(events).enumerated() {
            menu.insertItem(eventItem, at: eventsTitleItemIndex + index)
        }
        
        currentTimer = getNextEventValidationTimer(getEfficientNextEventTimerInterval(nextEvent!))

        self.events = events
        self.nextEvent = nextEvent
    }
    
    @objc private func validateNextEventData() {
        let nextEvent = utilities.getNextEvent(events!)
        
        if nextEvent == nil || nextEvent!.title != self.nextEvent!.title {
            switchToCalendar(selectedCalendars!, events: events!)
            return
        }
        
        statusItem.button?.title = utilities.prettyTimeUntilEvent(nextEvent!)
        
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
        let joinGoogleMeetItem = NSMenuItem(title: "Join via Google Meet...", action: nil, keyEquivalent: "J")
        
        joinGoogleMeetItem.representedObject = "join_meet"
        
        menu.addItem(joinGoogleMeetItem)
        menu.addItem(NSMenuItem.separator())

        menu.addItem(NSMenuItem(title: "Up Next", action: nil, keyEquivalent: ""))
        menu.addItem(NSMenuItem.separator())
        
        menu.addItem(calendarsItem)
        menu.setSubmenu(calendarsMenu, for: calendarsItem)

        menu.addItem(NSMenuItem.separator())
        menu.addItem(NSMenuItem(title: "Quit", action: #selector(quitApplication), keyEquivalent: ""))
        
        return menu
    }
    
    @objc private func quitApplication() {
        NSApplication.shared.terminate(self)
    }
    
    private func constructEventItems(_ events: [EKEvent]) -> [NSMenuItem] {
        var menuItems: [NSMenuItem] = []
        
        let dateFormatter = DateFormatter()

        dateFormatter.timeStyle = DateFormatter.Style.short
        dateFormatter.dateStyle = .none
        
        for event in events {
            let time = dateFormatter.string(from: event.startDate)
            let item = NSMenuItem(title: time+" - "+event.title, action: nil, keyEquivalent: "")
            item.representedObject = "event"
            menuItems.append(item)
        }
        
        return menuItems
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

