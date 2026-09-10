//
//  SavedRouteCardView.swift
//  Lana-V2
//
//  Created by Dinda Putri Pamungkas on 31/08/26.
//

import SwiftUI

struct SavedRouteCardView: View {
    let route: Route
    var showFavoriteButton = true
    var onSelect: (() -> Void)?
    var onFavoriteToggle: (() -> Void)?

    var body: some View {
        HStack(spacing: 12) {
            Button(action: { onSelect?() }) {
                HStack {
                    VStack(alignment: .leading, spacing: 6) {
                        Text(route.title)
                            .font(.headline)
                            .foregroundStyle(RouteTheme.primaryText)

                        Text(
                            "\(String(format: "%.1f", route.distanceKm)) km | \(route.durationText)"
                        )
                        .font(.subheadline)
                        .foregroundStyle(RouteTheme.secondaryText)

                        Label(
                            route.routingModeUsed.title,
                            systemImage: route.routingModeUsed == .cycling
                                ? "bicycle"
                                : "car.fill"
                        )
                        .font(.caption)
                        .foregroundStyle(RouteTheme.accent)
                    }

                    Spacer()
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)

            if showFavoriteButton {
                Button(action: { onFavoriteToggle?() }) {
                    Image(systemName: route.isFavorite ? "star.fill" : "star")
                        .foregroundStyle(
                            route.isFavorite
                                ? RouteTheme.accent
                                : RouteTheme.secondaryText
                        )
                        .frame(width: 40, height: 40)
                }
                .buttonStyle(.plain)
                .accessibilityLabel(
                    route.isFavorite
                        ? "Remove from favorites"
                        : "Add to favorites"
                )
            }
        }
        .padding(16)
        .background(RouteTheme.elevatedSurface)
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .overlay {
            RoundedRectangle(cornerRadius: 8)
                .strokeBorder(RouteTheme.border)
        }
    }
}

#Preview {
    SavedRouteCardView(
        route: .preview,
        onSelect: {},
        onFavoriteToggle: {
            print("Toggled favorite!")
        }
    )
    .padding()
    .background(RouteTheme.background)
    .preferredColorScheme(.dark)
}
