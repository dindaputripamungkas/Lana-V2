//
//  RouteOptionCard.swift
//  Lana-V2
//
//  Created by Imam on 01/09/26.
//

import SwiftUI

struct RouteOptionCard: View {
    let option: Route
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 12) {
                HStack(alignment: .top, spacing: 12) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(option.title)
                            .font(.headline)
                            .fontWeight(.semibold)
                            .foregroundStyle(RouteTheme.primaryText)

                        Label(
                            option.routingModeUsed.title,
                            systemImage: option.routingModeUsed == .cycling
                                ? "bicycle"
                                : "car.fill"
                        )
                        .font(.caption)
                        .foregroundStyle(RouteTheme.accent)
                    }

                    Spacer(minLength: 8)

                    if let badgeTitle = option.badgeTitle {
                        Text(badgeTitle)
                            .font(.caption2.weight(.semibold))
                            .foregroundStyle(.black)
                            .lineLimit(1)
                            .padding(.horizontal, 9)
                            .padding(.vertical, 5)
                            .background(RouteTheme.accent)
                            .clipShape(Capsule())
                    }

                    Image(systemName: "chevron.forward")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(RouteTheme.secondaryText)
                }

                HStack(spacing: 16) {
                    metric(
                        icon: "ruler",
                        value: String(format: "%.1f km", option.distanceKm)
                    )
                    metric(icon: "clock", value: option.durationText)
                    metric(
                        icon: "arrow.turn.up.right",
                        value: "\(option.intersections) turns"
                    )
                }

                HStack(spacing: 6) {
                    Image(systemName: "scope")
                    Text(
                        "Target \(option.targetDistanceKm, specifier: "%.1f") km, gap \(option.distanceGapKm, specifier: "%.1f") km"
                    )
                }
                .font(.caption)
                .foregroundStyle(RouteTheme.accent)

                if !option.warningMessage.isEmpty {
                    Label(
                        option.warningMessage,
                        systemImage: "exclamationmark.triangle.fill"
                    )
                    .font(.caption)
                    .foregroundStyle(RouteTheme.secondaryText)
                    .lineLimit(2)
                }
            }
            .padding(.vertical, 6)
            .frame(maxWidth: .infinity, alignment: .leading)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    private func metric(icon: String, value: String) -> some View {
        Label(value, systemImage: icon)
            .font(.caption)
            .foregroundStyle(RouteTheme.secondaryText)
            .lineLimit(1)
            .minimumScaleFactor(0.75)
    }
}

#Preview {
    RouteOptionCard(option: .preview, action: {})
        .padding()
        .background(RouteTheme.background)
        .preferredColorScheme(.dark)
}
