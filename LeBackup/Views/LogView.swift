//
//  LogView.swift
//  LeBackup
//
//  Created by Vincent Mallet on 4/11/21.
//

import SwiftUI

extension View {
    func backgroundMaybe<Background>(_ background: Background?, alignment: Alignment = .center) -> some View where Background : View {
        return background == nil ? AnyView(self) : AnyView(self.background(background!))
    }
}

struct LogView: View {
    @EnvironmentObject var logStore: LogStore

    func foregroundForKind(_ kind: LogStore.Entry.Kind) -> Color {
        switch (kind) {
        case .stdout:
            return .blue
        case .stderr:
            return .red
        case .meta:
            return .green
        case .header:
            return .primary
        @unknown default:
            print("!!! UNKNOWN KIND: \(kind)")
            return .red
        }
    }

    var body: some View {
        ScrollView {
            ScrollViewReader { value in
                LazyVStack {
                    var lastCount = 0
                    ForEach(logStore.entries) { ent in
                        HStack {
                            Text(ent.msg)
                                .foregroundColor(foregroundForKind(ent.kind))
                                Spacer()
                        }
                        .backgroundMaybe(ent.kind == .header ? Color.blue : nil)
                    }
                    .onChange(of: logStore.entries) { _ in
                        if logStore.entries.count != lastCount {
                            lastCount = logStore.entries.count
                            let la = logStore.entries.last!
                            print("Scrolling to: \(la)")
                            value.scrollTo(la.id, anchor: .bottomTrailing)
                        }
                    }
                }
            }
        }
        .padding()
    }
}

struct LogView_Previews: PreviewProvider {
    static var previews: some View {
        LogView()
            .environmentObject(LogStore())
    }
}
