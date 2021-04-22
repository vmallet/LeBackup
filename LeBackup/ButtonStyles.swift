//
//  ButtonStyles.swift
//  LeBackup
//
//  Created by Vincent Mallet on 4/22/21.
//

import SwiftUI

/// Oversized button style
struct BigButtonStyle: ButtonStyle {
    let color: Color

    init(_ color: Color) {
        self.color = color
    }

    func makeBody(configuration: Self.Configuration) -> some View {
        configuration.label
            .background(configuration.isPressed ? Color.primary : color)
            .cornerRadius(6.0)
            .padding(10)
    }
}

/// A Button style to have a button look like a link
struct LinkButton: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration
            .label
            .foregroundColor(configuration.isPressed ? .primary : .accentColor)
            .background(Color(NSColor.clear))
    }
}
