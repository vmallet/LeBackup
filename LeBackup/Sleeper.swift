//
//  Sleeper.swift
//  LeBackup
//
//  Created by Vincent Mallet on 4/12/21.
//

import Foundation
import os

struct Sleeper {
    let logger = Logger(subsystem: Bundle.main.bundleIdentifier!, category: "Sleeper")

    func sleepMac(after delay: Double = 0.0) {
        let script = "tell application \"System Events\" to sleep"

        DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
            runScript(script)
        }
    }

    func runScript(_ script: String) {
        let appleScript = NSAppleScript(source: script)
        if appleScript == nil {
            self.logger.log("Failed to even get the script")
        } else {
            var error: NSDictionary?
            let e = appleScript?.executeAndReturnError(&error)
            if let error = error {
                self.logger.log("Script error: \(error, privacy: .public)")
            } else {
                logger.info("No error maybe? e: \(e.debugDescription)")
            }
        }
    }

    // Note: reset privacy permissions on Apple Event with:
    //   sudo tccutil reset AppleEvents com.vmallet.MacExp2
    func probeAppleEvents() {
        runScript("""
            tell application "System Events"
                name of current user
            end tell
            """)
    }
}
