//
//  DetailsDividerView.swift
//  LeBackup
//
//  Created by Vincent Mallet on 4/22/21.
//

import SwiftUI
import os

struct DetailsDividerView: View {
    let logger = Logger(subsystem: Bundle.main.bundleIdentifier!, category: "DetailsDividerView")

    @AppStorage(Prefs.Keys.detailsShowing) var areDetailsShowing = false

    let detailsHeight: CGFloat

    @State var window: NSWindow?

    @State var firstShow = true

    var body: some View {
        HStack {
            VStack {
                Divider()
                    .frame(width: 20)
            }
            Button {
                toggleDetails()
            } label: {
                Label("Details", systemImage: areDetailsShowing ? "chevron.down" : "chevron.forward")
            }
            .buttonStyle(LinkButton())
            VStack {
                Divider()
            }
        }
        .background(HostingWindowFinder(callback: receiveWindow))
        .onChange(of: areDetailsShowing) { newValue in
            resizeMainWindow(newValue)
        }
    }

    func receiveWindow(_ window: NSWindow?) {
        guard let win = window else {
            logger.warning("No window received in callback")
            return
        }

        self.window = win

        logger.info("Received window, minSize=\(win.minSize.width)x\(win.minSize.height)")

        // The first time the window is shown, shrink it to its
        // min default size in case the left-over remembered size
        // is too tall
        if firstShow {
            firstShow = false
            if !areDetailsShowing {
                resizeMainWindow(false)
            }
        }
    }


    func toggleDetails() {
        DispatchQueue.main.async {
            withAnimation {
                areDetailsShowing.toggle()
            }
        }
    }

    func resizeMainWindow(_ willShow: Bool) {
        guard let w = window else {
            logger.warning("resizeMainWindow: no window to work with")
            return
        }

        // Compute delta of window height to get to new desired height
        // (collapsed or at least with an extra detailsHeight)
        let minHeight = w.minSize.height
        var delta: CGFloat
        var frame = w.frame
        if willShow {
            let desiredHeight = minHeight + CGFloat(detailsHeight)

            if frame.height < desiredHeight {
                delta = desiredHeight - frame.height
            } else {
                delta = CGFloat(0)
            }
        } else {
            delta = minHeight - frame.height
        }

        // Resize the window without moving it around
        frame.origin.y -= delta
        frame.size.height += delta

        let frameStr = "\(frame)"
        logger.info("Resizing main window with delta=\(delta), new frame=\(frameStr)")

        withAnimation {
            w.setFrame(frame, display: true, animate: true)
        }
    }
}

struct DetailsDividerView_Previews: PreviewProvider {
    static var previews: some View {
        DetailsDividerView(detailsHeight: 200)
    }
}
