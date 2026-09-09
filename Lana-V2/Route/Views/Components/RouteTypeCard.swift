//
//  RouteTypeCard.swift
//  Lana-V2
//
//  Created by Imam on 01/09/26.
//

import SwiftUI

struct RouteTypeCard: View {
    let icon: String
    let title: String
    let description: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.body.weight(.semibold))

                Text(title)
                    .font(.headline)
            }
            .foregroundStyle(
                isSelected ? Color.black : RouteTheme.primaryText
            )
            .frame(maxWidth: .infinity)
            .frame(height: 52)
            .padding(.horizontal, 12)
            .background(
                isSelected ? RouteTheme.accent : RouteTheme.surface
            )
            .clipShape(RoundedRectangle(cornerRadius: 8))
            .overlay {
                RoundedRectangle(cornerRadius: 8)
                    .strokeBorder(
                        isSelected
                            ? Color.black.opacity(0.18)
                            : RouteTheme.border,
                        lineWidth: 1
                    )
            }
        }
        .buttonStyle(.plain)
        .accessibilityHint(description)
    }
}

#Preview {
    HStack {
        RouteTypeCard(
            icon: "repeat",
            title: "Loop",
            description: "Start and finish at the same point.",
            isSelected: true,
            action: {}
        )

        RouteTypeCard(
            icon: "point.topleft.down.to.point.bottomright.curvepath",
            title: "A to B",
            description: "Start here, finish somewhere else.",
            isSelected: false,
            action: {}
        )
    }
    .padding()
    .background(RouteTheme.background)
    .preferredColorScheme(.dark)
}
