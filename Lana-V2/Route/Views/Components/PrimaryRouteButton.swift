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
    var isLoading = false
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 10) {
                if isLoading {
                    ProgressView()
                        .tint(.black)
                }

                Text(title)
                    .font(.headline)
            }
                .foregroundStyle(
                    isEnabled ? Color.black : RouteTheme.secondaryText
                )
                .frame(maxWidth: .infinity)
                .frame(minHeight: 32)
        }
        .buttonStyle(.borderedProminent)
        .buttonBorderShape(.capsule)
        .controlSize(.large)
        .tint(.white)
        .disabled(!isEnabled)
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
    .background(RouteTheme.background)
    .preferredColorScheme(.dark)
}
