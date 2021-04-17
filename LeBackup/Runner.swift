//
//  Runner.swift
//  LeBackup
//
//  Created by Vincent Mallet on 4/9/21.
//

import Foundation
import os

class Runner {
    let logger = Logger(subsystem: Bundle.main.bundleIdentifier!, category: "Runner")

    var onlyProcess : Process? = nil
    var terminated = false
    var terminationHandler: ((Int32) -> Void)? = nil

    var lines = 0

    private var mQueue =  DispatchQueue(label: "com.vmallet.MacExp2.runnerQueue")

    func outputHandler(_ fh: FileHandle, isErr: Bool, custom handler: ((String, Bool) -> Void)? = nil){
        let data = fh.availableData
        guard data.count > 0 else {
            return
        }
        guard let output = String(data: data, encoding: .utf8) else {
            print("Unable to decode pipe output data as UTF8, isErr: \(isErr), data: \(data as NSData)")
            return
        }

        mQueue.async {
            self.logger.debug("output: \(output)")
            output.enumerateLines { line, _ in
                handler?(line, isErr)
            }
        }
    }

    func run(_ cmd: String, _ args : String...,
             outputHandler: ((String, Bool) -> Void)? = nil,
             onCompletion handler: ((Int32) -> Void)? = nil) {
        print("run(): \(Thread.current)")

        guard onlyProcess == nil else {
            print("Some other process is already running")
            return
        }

        let pipe = Pipe()
        let pipeErr = Pipe()
        let process = Process()
        process.launchPath = cmd
        process.arguments = args
        process.standardOutput = pipe
        process.standardError = pipeErr
        let stdout = pipe.fileHandleForReading

        stdout.readabilityHandler = { fh in
            self.outputHandler(fh, isErr: false, custom: outputHandler)
        }

        let stderr = pipeErr.fileHandleForReading
        stderr.readabilityHandler = { fh in
            self.outputHandler(fh, isErr: true, custom: outputHandler)
        }

        let start = DispatchTime.now()

        lines = 0
        process.terminationHandler = { proc in
            self.mQueue.async {
            let end = DispatchTime.now()

            let millis = (end.uptimeNanoseconds - start.uptimeNanoseconds) / 1000000
            print("Termination handler: \(Thread.current)")
            print("Termination:  elapsed: \(millis) millis   lines: \(self.lines)")

            if let fh = (proc.standardOutput as? Pipe)?.fileHandleForReading {
                try? fh.close()
                fh.readabilityHandler = nil
                print("Closed stdout")
            }
            if let fh = (proc.standardError as? Pipe)?.fileHandleForReading {
                try? fh.close()
                fh.readabilityHandler = nil
                print("Closed stderr")
            }
            let status = proc.terminationStatus
            print("Termination status: \(status)   reason: \(proc.terminationReason.rawValue)")

            DispatchQueue.main.async {
                self.terminated = true
                self.onlyProcess = nil
                let tHandler = self.terminationHandler
                self.terminationHandler = nil
                tHandler?(status)
            }
        }
        }
        terminationHandler = handler

        onlyProcess = process

        process.launch()
    }

    func abortRunningProcess() {
        if let proc = onlyProcess {
            print("Terminating running script...")
            proc.terminate()
            onlyProcess = nil
            var i = 0
            while proc.isRunning && i < 10 {
                usleep(100000)
                i += 1
            }
            if !proc.isRunning {
                print("Script terminated successfully")
            } else {
                print("Issue terminating script!");
            }
        }
    }
}
