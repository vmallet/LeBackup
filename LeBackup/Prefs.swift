//
//  Prefs.swift
//  LeBackup
//
//  Created by Vincent Mallet on 4/10/21.
//

import Foundation

class Prefs {
    enum Keys {
        static let src = "rsync.src"
        static let dest = "rsync.dest"
        static let autoSleep = "auto.sleep"
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
            Keys.autoSleep: false
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
        set { defaults.set(newValue, forKey: Keys.autoSleep) }
        get { defaults.bool(forKey: Keys.autoSleep) }
    }

    class func getDocumentsDirectory() -> URL {
        let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        let documentsDirectory = paths[0]
        return documentsDirectory
    }
}
