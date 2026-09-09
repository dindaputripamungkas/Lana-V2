//
//  PreviewRouteGenerationService.swift
//  Lana-V2
//
//  Created by Imam on 31/08/26.
//

import Foundation

@MainActor
struct PreviewRouteGenerationService: RouteGenerating {
    func generateBestRoutes(
        for request: RouteGenerationRequest
    ) async throws -> [Route] {
        try Task.checkCancellation()

        let finish = request.routeType == .loop
            ? request.start
            : request.finish ?? request.start

        return [0.1, 0.4, -0.2].enumerated().map { index, distanceOffset in
            Route(
                title: "\(request.routeType.title) Option \(index + 1)",
                routeType: request.routeType,
                targetDistanceKm: request.targetDistanceKm,
                distanceKm: max(request.targetDistanceKm + distanceOffset, 0.1),
                durationMinutes: 34 + (index * 3),
                intersections: 8 + (index * 2),
                badgeTitle: index == 0 ? "Closest to Target" : nil,
                overview: "A preview route generated from the current request.",
                startLocation: request.start,
                finishLocation: finish,
                routingModeUsed: .cycling,
                coordinates: [
                    request.start.coordinate,
                    finish.coordinate
                ],
                instructions: ["Start riding", "Continue to the destination"],
                isPreview: true
            )
        }
    }

    func cancel() {}
}

@MainActor
struct PreviewPlaceSearchService: PlaceSearching {
    func search(_ query: String) async throws -> [RouteLocation] {
        try Task.checkCancellation()
        return [
            Route.preview.startLocation,
            Route.preview.finishLocation
        ].compactMap { $0 }
    }

    func cancel() {}
}

@MainActor
struct PreviewLocationService: LocationProviding {
    func requestCurrentLocation() async throws -> RouteLocation {
        try Task.checkCancellation()
        return Route.preview.startLocation!
    }

    func cancel() {}
}
