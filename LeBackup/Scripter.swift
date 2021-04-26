//
//  Scripter.swift
//  LeBackup
//
//  Created by Vincent Mallet on 4/12/21.
//

import Foundation
import os

struct Scripter {
    private let noSystemEventPrivilegesErrorNumber = -1743

    enum Error {
        case noAppleScript
        case noSystemEventsPrivileges
        case other(number: Int, description: String?)
        case unknown
    }

    let logger = Logger(subsystem: Bundle.main.bundleIdentifier!, category: "Sleeper")

    func sleepMac(after delay: Double = 0.0) {
        let script = "tell application \"System Events\" to sleep"

        DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
            runScript(script)
        }
    }

    func runScript(_ script: String) -> Error? {
        let appleScript = NSAppleScript(source: script)
        guard appleScript != nil else {
            self.logger.log("Failed to even get the script")
            return .noAppleScript
        }
        var error: NSDictionary?
        let e = appleScript?.executeAndReturnError(&error)
        if let error = error {
            self.logger.log("Script error: \(error, privacy: .public)")
            if let number = error["NSAppleScriptErrorNumber"] as? Int {
                if number == noSystemEventPrivilegesErrorNumber {
                    return .noSystemEventsPrivileges
                }
                return .other(number: number, description: error["NSAppleScriptErrorMessage"] as? String)
            }
            return .unknown
        }

        logger.info("No error maybe? e: \(e.debugDescription)")
        return nil
    }

    // Note: reset privacy permissions on Apple Event with:
    //   sudo tccutil reset AppleEvents com.vmallet.LeBackup
    // Return: true if problematic, false if all OK
    func probeAppleEvents() -> Bool {
        return nil != runScript("""
            tell application "System Events"
                name of current user
            end tell
            """)
    }
}
