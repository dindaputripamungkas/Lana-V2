//
//  RouteWeatherView.swift
//  Lana-V2
//

import SwiftUI

struct RouteWeatherView: View {
    let weather: RouteWeatherDisplay

    var body: some View {
        HStack(spacing: 0) {
            weatherMetric(
                title: "Current Weather",
                value: weather.temperatureText,
                icon: weather.symbolName
            )
            Divider().frame(height: 44)
            weatherMetric(
                title: "Wind",
                value: weather.windSpeedText,
                icon: "wind"
            )
        }
        .redacted(reason: weather.isLoading ? .placeholder : [])
        .padding(.vertical, 14)
        .background(RouteTheme.surface)
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .overlay {
            RoundedRectangle(cornerRadius: 8)
                .strokeBorder(RouteTheme.border)
        }
        .accessibilityElement(children: .combine)
    }

    private func weatherMetric(
        title: String,
        value: String,
        icon: String
    ) -> some View {
        VStack(spacing: 6) {
            Text(title)
                .font(.caption)
                .foregroundStyle(RouteTheme.secondaryText)

            Label(value, systemImage: icon)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(RouteTheme.primaryText)
                .lineLimit(1)
                .minimumScaleFactor(0.75)
        }
        .frame(maxWidth: .infinity)
        .padding(.horizontal, 6)
    }
}
