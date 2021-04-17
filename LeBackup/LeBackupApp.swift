//
//  LeBackupApp.swift
//  LeBackup
//
//  Created by Vincent Mallet on 4/7/21.
//

import SwiftUI
import AppKit

let appBlah = LogStore()
var xRunner: Runner?

class AppDelegate: NSObject, NSApplicationDelegate {

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        print("Terminate after last win?")
        return true
    }

    func applicationShouldTerminate(_ sender: NSApplication) -> NSApplication.TerminateReply {
        print("Should terminate...")
        return .terminateNow
    }

    func applicationWillTerminate(_ notification: Notification) {
        print("Will terminate...")
        xRunner?.abortRunningProcess()
    }

    func applicationWillBecomeActive(_ notification: Notification) {
        print("Finished become active...")
    }

    func applicationDidFinishLaunching(_ notification: Notification) {
        print("Finished launching...")
    }

    func applicationWillFinishLaunching(_ notification: Notification) {
        // Disable Tabs (No Command-T, no View -> Show Window Tab Bar)
        NSWindow.allowsAutomaticWindowTabbing = false
    }
}

@main
struct MacExp2App: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @StateObject var blah = appBlah
    @State var showExtras: Bool = false

    init() {
        xRunner = Runner()
    }

    var body: some Scene {
        WindowGroup {
            ContentView(runner: xRunner!, showExtras: $showExtras)
                .environmentObject(blah)
        }
        .commands {
            // Disable New Window menu option (no Command-N)
            CommandGroup(replacing: .newItem, addition: { })

            // Button to show the old experiments view
            CommandGroup(after: .windowArrangement) {
                Toggle(isOn: $showExtras.animation()) {
                    Text("Show Extras")
                }.keyboardShortcut("e")
            }
        }
        Settings {
            PrefsView()
        }
    }
}
