//
//  ContentView.swift
//  LeBackup
//
//  Created by Vincent Mallet on 4/7/21.
//

//TODO: move the rsync run stuff out to model/view somewhere else
//TODO: fix partial data notifications from Runner output
//TODO: VM detection upon run;
//TODO:   - auto detect and show some red, auto detect closure?
//TODO: make log area selectable / copyable?
//TODO: Alert "Are you sure" when closing window w/ running rsync

import os
import Cocoa
import Darwin
import SwiftUI

let keepThingsHidden = false

struct BigButtonStyle: ButtonStyle {
    let color: Color

    init(_ color: Color) {
        self.color = color
    }

    func makeBody(configuration: Self.Configuration) -> some View {
        configuration.label
            .background(configuration.isPressed ? Color.primary : color)
            .cornerRadius(6.0)
            .padding(10)
    }
}

struct ContentView: View {
    static let markerDate = Date(timeIntervalSinceReferenceDate: -1.5432)

    let logger = Logger(subsystem: Bundle.main.bundleIdentifier!, category: "ContentView")

    private static let osQueue =  DispatchQueue(label: "com.vmallet.MacExp2.osQueue")

    let quack = NSSound(contentsOf: Bundle.main.url(forResource: "quack", withExtension: "mp3")!, byReference: false)

    @EnvironmentObject var blahx: LogStore
    @State var runner: Runner
    @Binding var showExtras: Bool
    @State var progress = 0.0
    @State var sdone: UInt64 = 0
    @State var size: UInt64 = 0
    @State var showRunning = false
    @State var aborted = false
    @State var wasStarted = false
    @State var dryRun = false

    @State var currentFile: String?
    @State var currentFileProgress = 0.0

    @AppStorage(Prefs.Keys.src) var rsyncSrc = Prefs.defaultRsyncSrc
    @AppStorage(Prefs.Keys.dest) var rsyncDest = Prefs.defaultRsyncDest
    @AppStorage(Prefs.Keys.autoSleep) var autoSleep = false
    @AppStorage(Prefs.Keys.lastSuccessful) var lastSuccessful: Date = markerDate
    var body: some View {
        GeometryReader { geometry in
            HStack {
                if showExtras {
                    HStack {
                        body2
                            .frame(width: 280)
                        Divider()
                    }.transition(.move(edge: .leading))
                }
                mainBody
            }
            .frame(minWidth: 600.0, minHeight: 250)
        }
        .onChange(of: autoSleep) { _ in
            maybeCheckAppleEvents()
        }
    }

    var mainBody: some View {
        VStack {
            controlBody
            Divider()
            LogView()
        }
    }

    var controlBody: some View {
        ZStack {
            if !keepThingsHidden && showRunning {
                bodyRunning
                    .frame(height: 150)
                    .transition(.opacity)
                    .zIndex(1)
            } else {
                HStack {
                    VStack(alignment: .leading) {
                        Text(NSLocalizedString("BACK_UP_PARALLELS", comment: "Title, verb imperative"))
                            .font(.title)
                            .fontWeight(.semibold)
                        Spacer()
                        HStack {
                            VStack(alignment: .leading) {
                                Text(NSLocalizedString("SOURCE_:", comment: ""))
                                    .lineLimit(1)
                                    .padding(.bottom, 5)
                                    .padding(.top, 10)
                                Text(NSLocalizedString("DESTINATION_:", comment: ""))
                                    .lineLimit(1)
                                    .padding(.bottom, 5)
                            }
                            VStack(alignment: .leading) {
                                Text(rsyncSrc)
                                    .lineLimit(1)
                                    .padding(.bottom, 5)
                                    .padding(.top, 10)
                                Text(rsyncDest)
                                    .lineLimit(1)
                                    .padding(.bottom, 5)
                            }
                            Spacer()
                            VStack(alignment: .leading) {
                                Spacer()
                                Toggle(NSLocalizedString("DRY_RUN", comment: ""), isOn: $dryRun)
                                    .padding(.bottom)
                                Button(NSLocalizedString("SETTINGS", comment: "Settings button label")) {
                                    showSettings()
                                }
                            }
                        }
                        HStack {
                            Text(NSLocalizedString("LAST_SUCCESSFUL_RUN", comment: ""))
                            if lastSuccessful == Self.markerDate {
                                Text(NSLocalizedString("NEVER", comment: ""))
                            } else {
                                HStack {
                                    Text(lastSuccessful, style: .date)
                                    Text(lastSuccessful, style: .time)
                                }
                            }
                            Spacer()
                        }
                        .foregroundColor(.secondary)
                        Spacer()
                    }
                    .padding([.top, .leading, .trailing])
                    Spacer()
                    Divider()
                    VStack {
                        Button(NSLocalizedString("QUACK_!", comment: "")) {
                            quack?.play()
                        }
                        Spacer()
                        Toggle(NSLocalizedString("SLEEP_WHEN_DONE", comment: "Main UI checkbox label"), isOn: $autoSleep)
                        Spacer()
                        bigButton(NSLocalizedString("RUN_!", comment: "Main run button")) {
                            tryToRunRsync()
                        }
                    }
                    .padding()
                    .frame(width: 280)
                }
                .frame(height: 150)
            }

        } // ZStack
    }

    func bigButton(_ label: String, color: Color = .blue, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(label)
                .font(.title)
                .fontWeight(.light)
                .frame(maxWidth: 200, maxHeight: 35)
        }
        .buttonStyle(BigButtonStyle(color))
    }

    var bodyRunning: some View {
        HStack {
            VStack(alignment: .leading) {
                Text(NSLocalizedString("BACKING_UP_PARALLELS", comment: ""))
                    .font(.title)
                    .fontWeight(.semibold)
                Spacer()

                if wasStarted {
                    ProgressView(value: progress, total: 100) {
                        HStack {
                            if let cur = currentFile {
                                Text(NSLocalizedString("COPYING_:", comment: "") + cur)
                                    .lineLimit(1)
                                    .padding(.trailing)
                                Spacer()
                                ProgressView(value: currentFileProgress, total: 100)
                                    .progressViewStyle(LinearProgressViewStyle())
                                    .frame(width: 75)
                            } else {
                                Text("...")
                                Spacer()
                            }
                        }
                    }
                    .progressViewStyle(LinearProgressViewStyle())
                } else {
                    ProgressView(NSLocalizedString("SCANNING_FILES", comment: ""))
                        .progressViewStyle(LinearProgressViewStyle())
                }
                HStack {
                    Spacer()
                    Text(size > 0 ? "\(niceSize(sdone)) / \(niceSize(size))" : " ")
                }
                Spacer()
            }
            .padding()

            Divider()

            VStack {
                Spacer()
                Toggle(NSLocalizedString("SLEEP_WHEN_DONE", comment: ""), isOn: $autoSleep)
                Spacer()
                bigButton(NSLocalizedString("ABORT", comment: ""), color: .red) {
                    runner.abortRunningProcess()
                }
            }
            .padding()
            .frame(width: 280)
        }
    }

    var body2: some View {
        VStack {
            HStack {
                Button() {
                    showSettings()
                } label: {
                    Image(systemName: "gear")
                }
                .padding()
                Spacer()
            }
            Spacer()

            bigButton("Test Processes") {
                logger.log("Test Processes button pressed")
                blahx.append(NSLocalizedString("SCANNING_PARALLELS_PROCESSES", comment: ""), kind: .header)
                let _ = processes()
            }

            bigButton("Test rsync") {
                logger.log("Test rsync button pressed")
                tryToRunRsync()
            }

            bigButton("Fais dodo") {
                logger.log("Sleep button pressed")
                print("Ha Script!")
                Sleeper().sleepMac(after: 1.0)
            }

            bigButton("Alert") {
                showVmsDetectedAlert(["Win90", "Ubuntu"])
            }

            bigButton("Hide") {
                withAnimation {
                    showExtras = false
                }
            }

            HStack {
                Button("probeEvents") {
                    let _ = Sleeper().probeAppleEvents()
                }
                Button("setDate") {
                    Prefs.shared.lastSuccessful = Date()
                }
                Button("clrDate") {
                    Prefs.shared.lastSuccessful = nil
                }
            }
            Spacer()
        }
    }

    func showSettings() {
        NSApp.sendAction(Selector(("showPreferencesWindow:")), to: nil, from: nil)
    }

    func showVmsDetectedAlert(_ vms: [String]) {
        let alert = NSAlert()
        alert.messageText = NSLocalizedString("PARALLELS_VMS_DETECTED", comment: "")
        alert.informativeText =
            NSLocalizedString("THE_FOLLOWING_VMS_ARE_RUNNING", comment: "") + "\n"
                + vms.joined(separator: "\n") + "\n"
                + NSLocalizedString("SHUT_THEM_DOWN_TRY_AGAIN", comment: "")

        alert.addButton(withTitle: NSLocalizedString("TRY_AGAIN", comment: "")) // First
        alert.addButton(withTitle: NSLocalizedString("RUN_ANWAYS", comment: "")) // Second
        let cancel = alert.addButton(withTitle: NSLocalizedString("CANCEL", comment: "")) // Third
        cancel.keyEquivalent = "\u{1b}" // Escape

        alert.beginSheetModal(for:  NSApp.keyWindow!) { response in
            print(Thread.current)
            switch (response) {
            case .alertFirstButtonReturn:
                tryToRunRsync()
            case .alertSecondButtonReturn:
                switchViewRunRsync()
            case .alertThirdButtonReturn: //Cancel
                break
            default:
                let respStr = "\(response)"
                logger.error("We got an unexpected dialog response. Who did this? Ignoring it.. \(respStr)")
            }
        }
    }

    func showNeedPrivilegesAlert() {
        let alert = NSAlert()
        alert.messageText = NSLocalizedString("MISSING_SYSTEM_EVENTS_PRIVILEGES", comment: "")
        alert.informativeText =
            NSLocalizedString("SYSTEM_EVENTS_PRIVILEGES_TEXT", comment: "")

        let ok = alert.addButton(withTitle: "OK")
        ok.keyEquivalent = "\u{1b}" // Escape

        alert.runModal()
    }

    func maybeCheckAppleEvents() {
        guard autoSleep else { return }

        logger.info("AutoSleep is on: sending Apple Events probe")
        if Sleeper().probeAppleEvents() {
            DispatchQueue.main.async {
                showNeedPrivilegesAlert()
            }
        }
    }

    func resetRunState() {
        aborted = false
        sdone = 0
        size = 0
        progress = 0.0
        wasStarted = false
    }

    func getFileSize(dir: String, file: String) -> UInt64? {
        let filePath = dir + (dir.hasSuffix("/") ? "" : "/") + file
        do {
            let attrs = try FileManager.default.attributesOfItem(atPath: filePath) as NSDictionary
            if let type = attrs.fileType(), type == FileAttributeType.typeRegular.rawValue {
                return attrs.fileSize()
            }
            logger.info("NOT A REGULAR FILE -> 0  (\(filePath))")
            return 0
        } catch {
            let errStr = "\(error)"
            logger.error("getFileSize() error for file: \(filePath): \(errStr)")
        }
        return nil
    }

    func niceSize(_ size: UInt64) -> String {
        return ByteCountFormatter.string(fromByteCount: Int64(size), countStyle: .file)
    }

    func tryToRunRsync() {
        let vms = processes()
        if !vms.isEmpty {
            showVmsDetectedAlert(vms)
            return
        }

        switchViewRunRsync()
    }

    func switchViewRunRsync() {
        withAnimation {
            showRunning = true
        }

        DispatchQueue.main.async {
            testRsync()
        }
    }

    // "/foo/bar/" -> "/foo/bar/"; "/foo/bar" -> "/foo/"
    func rsyncDirBase(of dir: String) -> String {
        if dir.hasSuffix("/") {
            return dir
        }
        guard let lastSlash = dir.lastIndex(of: "/") else {
            return ""
        }
        return String(dir[dir.startIndex...lastSlash])
    }

    func testRsync() {
        //TODO: protect against running twice
        resetRunState()

        blahx.append(NSLocalizedString("RUNNING_RSYNC_N", comment: ""), kind: .header)

        let src = Prefs.shared.rsyncSrc
        let dest = Prefs.shared.rsyncDest
        print("RSYNC-test: \(src)   ->    \(dest)")
        blahx.append(NSLocalizedString("SOURCE_:", comment: "") + src, kind: .meta)
        blahx.append(NSLocalizedString("DESTINATION_:", comment: "") + dest, kind: .meta)

        var expectedSize: UInt64 = 0
        var inFileList = false

        let group = DispatchGroup()

        let base = rsyncDirBase(of: src)

        var lines = 0
        let handler: (String, Bool) -> Void = { line, isErr in
            lines += 1
            DispatchQueue.main.async {
                blahx.append(line, kind: isErr ? .stderr : .stdout)
            }
            guard !isErr else { return }

            if inFileList {
                if line.isEmpty {
                    print("Exiting inFileList")
                    inFileList = false
                } else {
                    if !line.hasSuffix("/") {
                        Self.osQueue.async(group: group) {
                            let size = getFileSize(dir: base, file: line) ?? 0
                            expectedSize += size
                        }
                    } else {
                        logger.debug("Rsync stats: skipping directory: \(line)")
                    }
                }
            } else if line.hasSuffix("files to consider") {
                print("Switching to inFileList")
                inFileList = true
            } else if line.hasPrefix("total size is ") {
                let size = UInt64(line.split(separator: " ", maxSplits: 4)[3]) ?? 0
                print("Total size: \(size)")
                print(line.split(separator: " ", maxSplits: 5))
                self.size = size
            }
        }

        let completion: (Int32) -> Void = { status in
            group.notify(queue: .main) {
                logger.info("testRsync() group notify; lines=\(lines)")
                let msg = String(format: NSLocalizedString("TERMINATION_STATUS_WITH_TOTALS %d %@ %@", comment: ""), status, niceSize(size), niceSize(expectedSize))
                blahx.append(msg, kind: .meta)
                guard status == 0 else {
                    logger.warning("rsync -n FAILED, aborting (status: \(status))")
                    return
                }

                if expectedSize != 0 {
                    self.size = expectedSize
                }
                if !dryRun {
                    self.startRealRsync()
                } else {
                    blahx.append(NSLocalizedString("DRY_RUN_SKIPPING_RSYNC", comment: ""), kind: .meta)
                    withAnimation {
                        showRunning = false
                    }
                }
            }
        }

        runner.run("/usr/bin/rsync", "-av", "--partial", "--progress", "-n", src, dest,
                   outputHandler: handler,
                   onCompletion: completion)
    }

    func startRealRsync() {
        blahx.append(NSLocalizedString("RUNNING_RSYNC", comment: ""), kind: .header)

        let src = Prefs.shared.rsyncSrc
        let dest = Prefs.shared.rsyncDest
        print("RSYNC: \(src)   ->    \(dest)")
        blahx.append(NSLocalizedString("SOURCE_:", comment: "") + src, kind: .meta)
        blahx.append(NSLocalizedString("DESTINATION_:", comment: "") + dest, kind: .meta)

        var totalDone: UInt64 = 0
        var curDone: UInt64 = 0
        var shouldAppendProgress = true

        let handler: (String, Bool) -> Void = { line, isErr in
            guard !isErr && line.hasPrefix(" ") else {
                DispatchQueue.main.async {
                    blahx.append(line, kind: isErr ? .stderr : .stdout)
                    // This is clearly a bit brutal: anything that's not starting with " "
                    // is treated as a file... We could do better
                    //TODO: unify rsync output parsing in both places
                    if !isErr && !line.hasPrefix("total") {
                        currentFile = line
                    } else {
                        currentFile = nil
                    }
                    currentFileProgress = 0.0
                }
                return
            }

            let split = line.split(separator: " ")
            print("split: \(split)")
            if (split.count == 4 || split.count == 6) && split[1].hasSuffix("%"), let done = UInt64(split[0]) {
                if shouldAppendProgress {
                    DispatchQueue.main.async {
                        blahx.append(line, kind: isErr ? .stderr : .stdout)
                    }
                } else {
                    DispatchQueue.main.async {
                        blahx.replaceLast(line, kind: isErr ? .stderr : .stdout)
                    }
                }
                if let percent = Double(String(split[1].dropLast())) {
                    print("Parsed percentage: \(percent)")
                    currentFileProgress = percent
                }
                print("SPLIT VALUE: \(done)")
                if split.count == 6 && split[1] == "100%" {
                    let t = totalDone;
                    totalDone += done
                    curDone = 0
                    print("100%: rotating total \(t) -> \(totalDone)")
                    shouldAppendProgress = true
                } else {
                    shouldAppendProgress = false
                    curDone = done
                }
                self.sdone = totalDone + curDone
                self.progress = (Double(self.sdone) * 100.0) / Double(self.size) //TODO: learn about conversions
            } else {
                DispatchQueue.main.async {
                    blahx.append(line, kind: isErr ? .stderr : .stdout)
                }
            }
        }

        wasStarted = true
        runner.run("/usr/bin/rsync", "-av", "--partial", "--progress", src, dest,
                   outputHandler: handler,
                   onCompletion: { status in
                    DispatchQueue.main.async {
                        let msg = String(format: NSLocalizedString("TERMINATION_STATUS %d", comment: ""), status)
                        blahx.append(msg, kind: .meta)
                        if status == 0 {
                            Prefs.shared.lastSuccessful = Date()
                        }
                        withAnimation {
                            showRunning = false
                        }
                        if autoSleep {
                            blahx.append(NSLocalizedString("SLEEP_REQUESTED_SLEEPING", comment: ""), kind: .header)
                            Sleeper().sleepMac(after: 2.0)
                        }
                    }})
    }

    func processes() -> [String] {
        // Get all running applications
        let applications = NSWorkspace.shared.runningApplications

        let total = applications.count
        var parallels = 0

        var vms = [String]()

        var observers = [(NSRunningApplication, NSKeyValueObservation)]()

        for app in applications {
            if app.bundleIdentifier == "com.parallels.vm" {
                parallels += 1
                let name = app.localizedName ?? "None"
                blahx.append(name, kind: .stderr)
                let obs = app.observe(\.isTerminated, changeHandler: { app, change in
                    print("Process observer: SOMETHING CHANGED!! app: \(app)   change: \(change)   app.isTerminated: \(app.isTerminated)")
                })
                // app gets added to observers to capture it and prevent it from being
                // deallocated while the observer lives on (it crashes otherwise)
                observers.append((app, obs))
                vms.append(name)
            }
        }
        print("Observers before: ")
        for (idx, (_, obs)) in observers.enumerated() {
            print("obs[\(idx)]: \(obs)")
        }
        let msg = String(format: NSLocalizedString("STATUS %lld %lld", comment: ""), total, parallels)
        blahx.append(msg, kind: .meta)
        let seconds = 10.0
        DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + seconds, execute: {
            print("Observers after \(seconds) seconds: ")
            for (idx, (_, obs)) in observers.enumerated() {
                print("obs[\(idx)]: \(obs)")
                obs.invalidate()
            }
        })
        return vms
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        let blah = LogStore()
        ContentView(runner: Runner(), showExtras: .constant(false))
            .environmentObject(blah)
    }
}
