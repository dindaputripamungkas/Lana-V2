//
//  PrimaryRouteButton.swift
//  Lana-V2
//
//  Created by Imam on 01/09/26.
//

import SwiftUI

struct PrimaryRouteButton: View {
    let title: String
    let isEnabled: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.headline)
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 52)
                .background(
                    Color(
                        red: 0.59,
                        green: 0.29,
                        blue: 0.28
                    )
                )
                .clipShape(
                    RoundedRectangle(cornerRadius: 14)
                )
        }
        .buttonStyle(.plain)
        .disabled(!isEnabled)
        .opacity(isEnabled ? 1 : 0.5)
    }
}

#Preview {
    VStack(spacing: 20) {
        PrimaryRouteButton(
            title: "Create Route",
            isEnabled: true,
            action: {}
        )

        PrimaryRouteButton(
            title: "Create Route",
            isEnabled: false,
            action: {}
        )
    }
    .padding()
}
