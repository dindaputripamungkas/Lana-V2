//
//  PrimaryRouteButton.swift
//  Lana-V2
//
//  Created by Imam on 01/09/26.
//

import SwiftUI

struct PrimaryRouteButton: View {
    let isEnabled: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text("Create Route")
                .font(.headline)
                .foregroundStyle(.primary)
                .frame(maxWidth: .infinity)
                .frame(height: 50)
                .background(.gray)
                .clipShape(
                    RoundedRectangle(cornerRadius: 20)
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
            isEnabled: true,
            action: {}
        )

        PrimaryRouteButton(
            isEnabled: false,
            action: {}
        )
    }
    .padding()
}
