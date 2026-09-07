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

    private let accentColor = Color(red: 0.59, green: 0.29, blue: 0.28)

    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 14) {
                HStack(alignment: .top, spacing: 12) {
                    Text(option.title)
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundStyle(.primary)
                        .multilineTextAlignment(.leading)

                    Spacer(minLength: 8)

                    if let badgeTitle = option.badgeTitle {
                        Text(badgeTitle)
                            .font(.caption2)
                            .fontWeight(.semibold)
                            .foregroundStyle(.white)
                            .lineLimit(1)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 5)
                            .background(accentColor)
                            .clipShape(Capsule())
                    }
                }

                Text("\(option.distanceKm, specifier: "%.1f") km | \(option.durationMinutes) mins | \(option.intersections) Intersections")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundStyle(accentColor)
                    .lineLimit(2)
            }
            .padding(18)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(.white)
            .clipShape(
                RoundedRectangle(cornerRadius: 16)
            )
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    RouteOptionCard(
        option: Route(
            title: "Loop Route 15K",
            distanceKm: 15.1,
            durationMinutes: 34,
            intersections: 10,
            badgeTitle: "Closest to Target Distance",
            routeKindTitle: "Loop Route",
            warningMessage: "Cycling road data is not available in your region",
            currentWeather: "26°C",
            windSpeed: "13 km/h",
            overview: "A balanced route option for preview."
        ),
        action: {}
    )
    .padding()
    .background(Color(.systemGroupedBackground))
}
