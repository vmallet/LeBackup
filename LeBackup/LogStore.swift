//
//  LogStore.swift
//  LeBackup
//
//  Created by Vincent Mallet on 4/10/21.
//

import Foundation
import os

class LogStore: ObservableObject {
    let logger = Logger(subsystem: Bundle.main.bundleIdentifier!, category: "LogStore")

    @Published var entries = [Entry]()

    struct Entry: Identifiable, Hashable, CustomStringConvertible {
        enum Kind {
            case header
            case stdout
            case stderr
            case meta
        }

        let id = UUID()
        let msg: String
        let kind: Kind

        init(_ str: String, kind: Kind) {
            self.msg = str
            self.kind = kind
        }

        static func == (lhs: Entry, rhs: Entry) -> Bool {
            return lhs.id == rhs.id
        }

        func hash(into hasher: inout Hasher) {
            hasher.combine(id)
        }

        var description: String { msg }
    }

    func emptyEntry() -> Entry {
        return Entry("", kind: .meta) //TODO: is meta really the right thing for an empty entry?
    }

    func append(_ msg: String, kind: Entry.Kind) {
        if !Thread.current.isMainThread {
            logger.warning("LogStore.append: not on the main thread: \(Thread.current), msg=\(msg)")
        }
        let entry = Entry(msg, kind: kind)
        if kind == .header {
            entries.append(emptyEntry())
        }
        self.entries.append(entry)
    }

    func replaceLast(_ msg: String, kind: Entry.Kind) {
        if !Thread.current.isMainThread {
            logger.warning("LogStore.replace(): Not on the main thread: \(Thread.current), msg=\(msg)")
        }
        guard kind != .header else {
            //TODO: do the todo
            print("TODO: THROW SOME RELEVANT ERROR HERE")
            append(msg, kind: kind)
            return
        }

        let entry = Entry(msg, kind: kind)
        if entries.isEmpty {
            entries.append(entry)
        } else {
            entries[entries.count - 1] = entry
        }
    }
}
