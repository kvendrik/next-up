//
//  AppDelegate.swift
//  TextTransform
//
//  Created by Koen Vendrik on 2020-04-10.
//  Copyright © 2020 Koen Vendrik. All rights reserved.
//

import EventKit
import Cocoa

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {
    private var calendarMenuItems: [NSMenuItem] = []
    private var calendars: [EKCalendar]? = nil
    private var currentTimer: Timer? = nil
    private var currentCalendar: EKCalendar? = nil
    private let utilities = CalendarUtilities()
    private let statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
    private let store = EKEventStore()

    func applicationDidFinishLaunching(_ aNotification: Notification) {
        statusItem.button?.target = self
        utilities.requestCalendarAccess(store: store) {
            DispatchQueue.main.async {
                let calendars = self.store.calendars(for: .event)
                let selectedCalendar = calendars.first(where: { $0.calendarIdentifier == self.store.defaultCalendarForNewEvents?.calendarIdentifier })

                self.calendars = calendars
                self.updateToCalendar(selectedCalendar!)
            }
        }
    }

    func applicationWillTerminate(_ aNotification: Notification) {
        // Insert code here to tear down your application
    }
    
    private func updateToCalendar(_ calendar: EKCalendar) {
        let events = utilities.getEventsForRestOfDay(calendars: [calendar], store: store)
        let calendarsMenu = constructCalendarsMenu(selectedCalendar: calendar)
        let mainMenu = constructMainMenu(events: events, calendarsMenu: calendarsMenu)
        
        if let timer = currentTimer {
            timer.invalidate()
            currentTimer = nil
        }
        
        statusItem.menu = mainMenu
        currentCalendar = calendar
        
        statusItem.button?.title = events.isEmpty ? "No upcoming meetings" : utilities.prettyTimeUntilEvent(events[0])
        
        if !events.isEmpty {
            currentTimer = Timer.scheduledTimer(timeInterval: 60.0, target: self, selector: #selector(updateButton), userInfo: nil, repeats: true)
        }
    }
    
    @objc private func updateButton() {
        // 1. Update button with time till next
        // 2. Update events in calendar menu if the current event passed
    }
    
    private func constructMainMenu(events: [EKEvent], calendarsMenu: NSMenu) -> NSMenu {
        let menu = NSMenu()

        let calendarsItem = NSMenuItem(title: "Calendars", action: nil, keyEquivalent: "")
        menu.addItem(calendarsItem)
        
        menu.setSubmenu(calendarsMenu, for: calendarsItem)
        
        menu.addItem(NSMenuItem.separator())
        
        let eventsTitleItem = NSMenuItem(title: "Up Next", action: nil, keyEquivalent: "")
        menu.addItem(eventsTitleItem)
        
        for item in constructEventItems(events) {
            menu.addItem(item)
        }
        
        return menu
    }
    
    private func constructEventItems(_ events: [EKEvent]) -> [NSMenuItem] {
        var menuItems: [NSMenuItem] = []
        
        let dateFormatter = DateFormatter()

        dateFormatter.timeStyle = DateFormatter.Style.short
        dateFormatter.dateStyle = .none
        
        for event in events {
            let time = dateFormatter.string(from: event.startDate)
            menuItems.append(NSMenuItem(title: time+" - "+event.title, action: nil, keyEquivalent: ""))
        }
        
        return menuItems
    }
    
    private func constructCalendarsMenu(selectedCalendar: EKCalendar) -> NSMenu {
        let calendarsMenu = NSMenu()

        for calendar in self.calendars! {
            let item = NSMenuItem(title: calendar.title, action: #selector(toggleCalendarItemState), keyEquivalent: "")
            item.representedObject = calendar
            if calendar.calendarIdentifier == selectedCalendar.calendarIdentifier {
                item.state = .on
            }
            calendarMenuItems.append(item)
            calendarsMenu.addItem(item)
        }

        return calendarsMenu
    }
    
    @IBAction private func toggleCalendarItemState(_ item: NSMenuItem) {
        for calendarMenuItem in calendarMenuItems {
            calendarMenuItem.state = .off
        }
        item.state = item.state == .on ? .off : .on
        let selectedCalendar = item.representedObject as! EKCalendar
        updateToCalendar(selectedCalendar)
    }
}

