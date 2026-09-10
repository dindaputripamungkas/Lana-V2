//
//  RouteRideStatsView.swift
//  Lana-V2
//

import SwiftUI

struct RouteRideStatsView: View {
    let averageElevationMeters: Double?
    let averageSpeedKmh: Double?

    var body: some View {
        VStack(spacing: 12) {
            HStack(spacing: 0) {
                metric(
                    title: "Avg. elevation",
                    value: averageElevationMeters.map {
                        "\(Int($0.rounded())) m"
                    } ?? "--"
                )
                Divider().frame(height: 42)
                metric(
                    title: "Avg. speed",
                    value: averageSpeedKmh.map {
                        String(format: "%.1f km/h", $0)
                    } ?? "--"
                )
            }

            if averageElevationMeters == nil && averageSpeedKmh == nil {
                Text("Complete and save a ride to add your recorded statistics.")
                    .font(.caption)
                    .foregroundStyle(RouteTheme.secondaryText)
                    .multilineTextAlignment(.center)
            }
        }
        .padding(14)
        .background(RouteTheme.surface)
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .overlay {
            RoundedRectangle(cornerRadius: 8)
                .strokeBorder(RouteTheme.border)
        }
    }

    private func metric(title: String, value: String) -> some View {
        VStack(spacing: 5) {
            Text(title)
                .font(.caption)
                .foregroundStyle(RouteTheme.secondaryText)
            Text(value)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(RouteTheme.primaryText)
        }
        .frame(maxWidth: .infinity)
    }
}
