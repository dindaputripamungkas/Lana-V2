//
//  RouteDetailMetricsView.swift
//  Lana-V2
//

import SwiftUI

struct RouteDetailMetricsView: View {
    let route: Route

    var body: some View {
        HStack(spacing: 0) {
            metric(
                title: "Distance",
                value: String(format: "%.1f km", route.distanceKm),
                icon: "ruler"
            )
            Divider().frame(height: 44)
            metric(
                title: "Est. time",
                value: route.durationText,
                icon: "clock"
            )
            Divider().frame(height: 44)
            metric(
                title: "Turns",
                value: "\(route.intersections)",
                icon: "arrow.turn.up.right"
            )
        }
        .padding(.vertical, 14)
        .background(RouteTheme.surface)
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .overlay {
            RoundedRectangle(cornerRadius: 8)
                .strokeBorder(RouteTheme.border)
        }
    }

    private func metric(
        title: String,
        value: String,
        icon: String
    ) -> some View {
        VStack(spacing: 5) {
            Label(title, systemImage: icon)
                .font(.caption2)
                .foregroundStyle(RouteTheme.secondaryText)
                .lineLimit(1)

            Text(value)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(RouteTheme.primaryText)
                .lineLimit(1)
                .minimumScaleFactor(0.72)
        }
        .frame(maxWidth: .infinity)
        .padding(.horizontal, 4)
    }
}
