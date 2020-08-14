//
//  AppDelegate.swift
//  NextUpLaunchHelper
//
//  Created by Koen Vendrik on 2020-08-14.
//  Copyright © 2020 Koen Vendrik. All rights reserved.
//

import Cocoa

@NSApplicationMain
class LaunchHelperAppDelegate: NSObject, NSApplicationDelegate {

    func applicationDidFinishLaunching(_ aNotification: Notification) {
        let runningApps = NSWorkspace.shared.runningApplications
        let isRunning = runningApps.contains { $0.bundleIdentifier == "com.kvendrik.NextUp" }

        if !isRunning {
            var path = Bundle.main.bundlePath as NSString
            for _ in 1...4 {
                path = path.deletingLastPathComponent as NSString
            }
            NSWorkspace.shared.launchApplication(path as String)
        }
    }

    func applicationWillTerminate(_ aNotification: Notification) {
        // Insert code here to tear down your application
    }


}

