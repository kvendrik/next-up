//
//  AutoLaunch.swift
//  Next Up
//
//  Created by Koen Vendrik on 2020-08-14.
//  Copyright © 2020 Koen Vendrik. All rights reserved.
//

import Cocoa
import ServiceManagement

struct AutoLaunchManager {
    private let helperBundleName = "com.kvendrik.NextUpLaunchHelper"
    
    func setAutoLaunchEnabled(_ newValue: Bool) {
        SMLoginItemSetEnabled(helperBundleName as CFString, newValue)
    }
    
    func autoLaunchEnabled() -> Bool {
        return NSWorkspace.shared.runningApplications.contains { $0.bundleIdentifier == helperBundleName }
    }
}
