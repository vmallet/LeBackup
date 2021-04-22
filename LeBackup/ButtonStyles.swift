//
//  ButtonStyles.swift
//  LeBackup
//
//  Created by Vincent Mallet on 4/22/21.
//

import SwiftUI

// Oversized button style
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
