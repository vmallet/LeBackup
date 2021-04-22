//
//  HostingWindowFinder.swift
//  LeBackup
//
//  Created by Vincent Mallet on 4/22/21.
//

import SwiftUI

//
// HostingWindowFinder technique taken from:
//    https://lostmoa.com/blog/ReadingTheCurrentWindowInANewSwiftUILifecycleApp/
//
struct HostingWindowFinder: NSViewRepresentable {
    var callback: (NSWindow?) -> ()

    func makeNSView(context: Self.Context) -> NSView {
        let view = NSView()
        DispatchQueue.main.async { [weak view] in
            self.callback(view?.window)
        }
        return view
    }
    func updateNSView(_ nsView: NSView, context: Context) {}
}
