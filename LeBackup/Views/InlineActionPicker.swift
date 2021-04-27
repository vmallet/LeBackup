//
//  InlineActionPicker.swift
//  LeBackup
//
//  Created by Vincent Mallet on 4/26/21.
//

import SwiftUI

struct InlineActionPicker: View {
    @Binding var isEnabled: Bool
    @Binding var action: AutoAction

    var body: some View {
        HStack {
            Toggle(isOn: $isEnabled) {
                Text(NSLocalizedString("WHEN_DONE_:", comment: ""))
            }
            if isEnabled {
                Picker("", selection: $action) {
                    Text(NSLocalizedString("SLEEP", comment: ""))
                        .tag(AutoAction.sleep)
                    Text(NSLocalizedString("SHUTDOWN", comment: ""))
                        .tag(AutoAction.shutdown)
                }
                .labelsHidden()
                .pickerStyle(SegmentedPickerStyle())
            } else {
                Text("...")
                    .foregroundColor(.secondary)
            }
        }
    }
}

struct InlineActionPicker_Previews: PreviewProvider {
    static var previews: some View {
        InlineActionPicker(isEnabled: .constant(true), action: .constant(.shutdown))
    }
}
