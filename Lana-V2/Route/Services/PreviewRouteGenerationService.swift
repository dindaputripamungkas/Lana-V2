//
//  PreviewRouteGenerationService.swift
//  Lana-V2
//
//  Created by Imam on 31/08/26.
//

import Foundation

struct PreviewRouteGenerationService : RouteGenerating {
    func generateOptions(
        targetDistanceKm: Double,
        routeType: RouteType,
        startLocation: String?,
        finishLocation: String?
    ) -> [Route] {
        let routeKindTitle = routeType == .loop ? "Loop Route" : "A to B Route"
        let warningMessage = routeType == .loop
            ? "Cycling road data is not available in your region"
            : "Route preview uses your start and finish point"

        return [
            Route(
                title: routeType == .loop ? "Loop Route 15K" : "A to B Balanced Route",
                distanceKm: targetDistanceKm + 0.1,
                durationMinutes: 34,
                intersections: 10,
                badgeTitle: "Closest to Target Distance",
                routeKindTitle: routeKindTitle,
                warningMessage: warningMessage,
                currentWeather: "26°C",
                windSpeed: "13 km/h",
                overview: "A balanced route option that stays close to your target distance while keeping the path simple for a first preview."
            ),
            Route(
                title: routeType == .loop ? "Loop Route 2" : "A to B Scenic Route",
                distanceKm: targetDistanceKm + 0.4,
                durationMinutes: 38,
                intersections: 12,
                badgeTitle: nil,
                routeKindTitle: routeKindTitle,
                warningMessage: warningMessage,
                currentWeather: "27°C",
                windSpeed: "11 km/h",
                overview: "A slightly longer option with more turns, useful when you want a calmer route shape for the dummy review flow."
            ),
            Route(
                title: routeType == .loop ? "Loop Quick Route" : "A to B Quick Route",
                distanceKm: max(targetDistanceKm - 0.2, 0.1),
                durationMinutes: 31,
                intersections: 8,
                badgeTitle: "Fastest",
                routeKindTitle: routeKindTitle,
                warningMessage: warningMessage,
                currentWeather: "26°C",
                windSpeed: "15 km/h",
                overview: "The fastest dummy option with fewer intersections, made to help the detail screen show meaningful route data."
            )
        ]
    }
}


