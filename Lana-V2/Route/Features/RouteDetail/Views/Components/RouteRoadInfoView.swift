//
//  RouteRoadInfoView.swift
//  Lana-V2
//

import SwiftUI

struct RouteRoadInfoView: View {
    let route: Route
    let title: String
    let message: String

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: route.routingModeUsed == .cycling
                ? "bicycle"
                : "car.fill")
                .font(.headline)
                .foregroundStyle(RouteTheme.accent)
                .frame(width: 36, height: 36)
                .background(RouteTheme.accentMuted)
                .clipShape(Circle())

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(RouteTheme.primaryText)

                Text(message)
                    .font(.caption)
                    .foregroundStyle(RouteTheme.secondaryText)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer(minLength: 6)

            Text(route.routeKindTitle)
                .font(.caption2.weight(.semibold))
                .foregroundStyle(RouteTheme.primaryText)
                .padding(.horizontal, 8)
                .padding(.vertical, 5)
                .background(RouteTheme.surface)
                .clipShape(Capsule())
        }
        .padding(14)
        .background(RouteTheme.elevatedSurface)
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .overlay {
            RoundedRectangle(cornerRadius: 8)
                .strokeBorder(RouteTheme.border)
        }
    }
}
