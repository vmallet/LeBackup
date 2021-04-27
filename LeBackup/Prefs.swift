//
//  Prefs.swift
//  LeBackup
//
//  Created by Vincent Mallet on 4/10/21.
//

import Foundation

fileprivate let noDateValue = -1.2345

extension Date: RawRepresentable {
    public var rawValue: String {
        return String(self.timeIntervalSinceReferenceDate)
    }

    public init?(rawValue: String) {
        let double = Double(rawValue) ?? noDateValue
        if double == noDateValue {
            return nil
        }
        self = Date(timeIntervalSinceReferenceDate: double)
    }
}

enum AutoAction: String {
    case sleep = "sleep"
    case shutdown = "shutdown"
}

class Prefs {
    enum Keys {
        static let src = "rsync.src"
        static let dest = "rsync.dest"
        static let autoActionEnabled = "auto.action.enabled"
        static let postBackupAction = "post.backup.action"
        static let lastSuccessful = "last.successful"
        static let detailsShowing = "details.showing"
    }

    static let shared = Prefs()

    static let defaultRsyncSrc = getDocumentsDirectory().relativePath + "/Parallels"
    static let defaultRsyncDest = "/Volumes/SauvegardeMac/sauvegarde-manuelle/"

    private let defaults: UserDefaults

//    private let cancellable: Cancellable
//
//    let objectWillChange = PassthroughSubject<Void, Never>()

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults

        defaults.register(defaults: [
            Keys.src: Prefs.defaultRsyncSrc,
            Keys.dest: Prefs.defaultRsyncDest,
            Keys.autoActionEnabled: false,
            Keys.postBackupAction: AutoAction.sleep.rawValue,
            Keys.lastSuccessful: "\(noDateValue)",
            Keys.detailsShowing: false
            ])

//        cancellable = NotificationCenter.default
//            .publisher(for: UserDefaults.didChangeNotification)
//            .map { _ in () }
//            .subscribe(objectWillChange)
    }

    var rsyncSrc: String {
        set { defaults.set(newValue, forKey: Keys.src) }
        get { defaults.string(forKey: Keys.src) ?? Prefs.defaultRsyncSrc }
    }

    var rsyncDest: String {
        set { defaults.set(newValue, forKey: Keys.dest) }
        get { defaults.string(forKey: Keys.dest) ?? Prefs.defaultRsyncDest }
    }

    var autoSleep: Bool {
        set { defaults.set(newValue, forKey: Keys.autoActionEnabled) }
        get { defaults.bool(forKey: Keys.autoActionEnabled) }
    }

    var lastSuccessful: Date? {
        set {
            if newValue == nil || newValue?.timeIntervalSinceReferenceDate == noDateValue {
                defaults.removeObject(forKey: Keys.lastSuccessful)
            } else {
                defaults.set(newValue!.rawValue, forKey: Keys.lastSuccessful)
            }
        }
        get {
            guard let rawValue = defaults.string(forKey: Keys.lastSuccessful) else { return nil }
            return Date.init(rawValue: rawValue)
        }
    }

    var areDetailsShowing: Bool {
        set { defaults.set(newValue, forKey: Keys.detailsShowing) }
        get { defaults.bool(forKey: Keys.detailsShowing) }
    }

    var postBackupAction: AutoAction {
        set { defaults.set(newValue.rawValue, forKey: Keys.postBackupAction) }
        get { AutoAction(rawValue: defaults.string(forKey: Keys.postBackupAction) ?? "") ?? .sleep }
    }

    class func getDocumentsDirectory() -> URL {
        let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        let documentsDirectory = paths[0]
        return documentsDirectory
    }
}
