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
            VStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.title3)

                Text(title)
                    .font(.headline)

                Text(description)
                    .font(.subheadline)
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 110)
            .padding(.horizontal, 8)
            .background(.white)
            .clipShape(
                RoundedRectangle(cornerRadius: 16)
            )
            .overlay {
                RoundedRectangle(cornerRadius: 16)
                    .strokeBorder(
                        isSelected
                        ? Color(.black)
                        : .gray,
                        lineWidth: 2
                    )
            }
        }
        .buttonStyle(.plain)
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
    .background(
        Color(.systemGroupedBackground)
    )
}
