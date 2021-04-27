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
    @AppStorage(Prefs.Keys.autoActionEnabled) var autoActionEnabled = false
    // see postBackupHack in ContentView
    @AppStorage(Prefs.Keys.postBackupAction) var postBackupHack = ""
    @State var postBackupAction = Prefs.shared.postBackupAction
    @AppStorage(Prefs.Keys.detailsShowing) var areDetailsShowing = false

    let chooseLabel = NSLocalizedString("CHOOSE_...", comment: "")

    private let columns = [GridItem(.fixed(150), alignment: .trailing), GridItem(.fixed(500), alignment: .leading), GridItem(.fixed(100))]

    let emptyCell = AnyView(Color(NSColor.clear))

    func buildGrid(_ index: Int) -> AnyView {
        switch (index) {
        case 0:
            return AnyView(Text(NSLocalizedString("SOURCE_:", comment: "")))
        case 1:
            return AnyView(TextField(NSLocalizedString("SOURCE_DIRECTORY", comment: ""), text: $rsyncSrc))
        case 2:
            return AnyView(
                Button(chooseLabel) {
                    if let newDir = dirPicker(rsyncSrc) {
                        rsyncSrc = newDir
                    }
                }
            )
        case 3:
            return AnyView(Text(NSLocalizedString("DESTINATION_:", comment: "")))
        case 4:
            return AnyView(TextField(NSLocalizedString("TARGET_DIRECTORY", comment: ""), text: $rsyncDest))
        case 5:
            return AnyView(
                Button(chooseLabel) {
                    if let newDir = dirPicker(rsyncDest) {
                        rsyncDest = newDir
                    }
                }
            )
        case 7:
            return AnyView(VStack(alignment: .leading) {
                Toggle(NSLocalizedString("WHEN_A_BACKUP_IS_COMPLETE_AUTOMATICALLY", comment: ""), isOn: $autoActionEnabled.animation())
                Picker("", selection: $postBackupAction) {
                    Text(NSLocalizedString("SLEEP", comment: ""))
                        .tag(AutoAction.sleep)
                    Text(NSLocalizedString("SHUTDOWN", comment: ""))
                        .tag(AutoAction.shutdown)
                }
                .labelsHidden()
                .pickerStyle(RadioGroupPickerStyle())
                .offset(x: 15)
                .disabled(!autoActionEnabled)
            }
            .onChange(of: postBackupHack) { _ in
                postBackupAction = Prefs.shared.postBackupAction
            }
            .onChange(of: postBackupAction) { newValue in
                Prefs.shared.postBackupAction = newValue
            })

        case 10:
            return AnyView(Toggle(NSLocalizedString("SHOW_DETAILS_PANE", comment: ""),
                                  isOn: $areDetailsShowing))

        default:
            return emptyCell
        }
    }

    var body: some View {
        Form {
            LazyVGrid(columns: columns) {
                ForEach(0..<15) { index in
                    buildGrid(index)
                }
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
