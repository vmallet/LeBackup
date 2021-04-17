//
//  PrefsView.swift
//  LeBackup
//
//  Created by Vincent Mallet on 4/10/21.
//

import SwiftUI

struct PrefsView: View {
    @AppStorage(Prefs.Keys.src) var rsyncSrc = Prefs.defaultRsyncSrc
    @AppStorage(Prefs.Keys.dest) var rsyncDest = Prefs.defaultRsyncDest
    @AppStorage(Prefs.Keys.autoSleep) var autoSleep = false

    let chooseLabel = NSLocalizedString("CHOOSE_...", comment: "")

    var body: some View {
        Form {
//            Toggle("Perform some boolean Setting", isOn: $kSetting)
//                .help(kSetting ? "Undo that boolean Setting" : "Perform that boolean Setting")
            Section(header: Text("Rsync")) {
                HStack {
                    Text(NSLocalizedString("SOURCE_:", comment: ""))
                    TextField(NSLocalizedString("SOURCE_DIRECTORY", comment: ""), text: $rsyncSrc)
                    Button(chooseLabel) {
                        if let newDir = dirPicker(rsyncSrc) {
                            rsyncSrc = newDir
                        }
                    }
                }
                HStack {
                    Text(NSLocalizedString("DESTINATION_:", comment: ""))
                    TextField(NSLocalizedString("TARGET_DIRECTORY", comment: ""), text: $rsyncDest)
                    Button(chooseLabel) {
                        if let newDir = dirPicker(rsyncDest) {
                            rsyncDest = newDir
                        }
                    }
                }
                Toggle(NSLocalizedString("AUTOMATICALLY_SLEEP_AFTER_BACKUP", comment: ""), isOn: $autoSleep)
            }
        }
        .padding()
        .frame(minWidth: 400)
    }

    func dirPicker(_ directory: String?) -> String? {
        let dialog = NSOpenPanel();

        dialog.title = "Choose single directory"
        dialog.showsResizeIndicator = true
        dialog.showsHiddenFiles = false
        dialog.canChooseFiles = false
        dialog.canChooseDirectories = true
        if let dir = directory {
            dialog.directoryURL = URL(fileURLWithPath: dir)
        }

        if (dialog.runModal() ==  NSApplication.ModalResponse.OK) {
            if let path = dialog.url?.path {
                print("DirPicker: path: \(path)")
                return path
            }
        } else {
            print("Canceled!")
        }
        return nil
    }
}

struct PrefsView_Previews: PreviewProvider {
    static var previews: some View {
        PrefsView()
    }
}
