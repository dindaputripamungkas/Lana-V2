//
//  PreviewRouteGenerationService.swift
//  Lana-V2
//
//  Created by Imam on 31/08/26.
//

import Foundation

@MainActor
struct PreviewRouteGenerationService: RouteGenerating {
    func minimumDistance(
        from start: RouteLocation,
        to finish: RouteLocation
    ) async throws -> Double {
        try Task.checkCancellation()
        return 5_000
    }

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
                steps: [
                    RouteStep(
                        instruction: "Start riding",
                        distanceMeters: request.targetDistanceMeters * 0.5
                    ),
                    RouteStep(
                        instruction: "Continue to the destination",
                        distanceMeters: request.targetDistanceMeters * 0.5
                    )
                ],
                isPreview: true
            )
        }
    }

    func cancel() {}
}

@MainActor
struct PreviewPlaceSearchService: PlaceSearching {
    func suggestions(
        for query: String,
        in region: PlaceSearchRegion?
    ) async throws -> [PlaceSearchSuggestion] {
        try Task.checkCancellation()
        return [
            PlaceSearchSuggestion(
                id: "apple-park",
                title: "Apple Park",
                subtitle: "Cupertino, CA"
            ),
            PlaceSearchSuggestion(
                id: "cupertino",
                title: "Cupertino",
                subtitle: "California"
            )
        ]
    }

    func resolve(
        _ suggestion: PlaceSearchSuggestion,
        in region: PlaceSearchRegion?
    ) async throws -> RouteLocation {
        try Task.checkCancellation()
        return suggestion.id == "apple-park"
            ? Route.preview.startLocation!
            : Route.preview.finishLocation!
    }

    func nearbyLocation(
        at coordinate: RouteCoordinate,
        maximumDistanceMeters: Double
    ) async throws -> RouteLocation? {
        try Task.checkCancellation()
        return nil
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

@MainActor
struct PreviewLocationNamingService: LocationNaming {
    func name(for coordinate: RouteCoordinate) async -> String? {
        "Preview Location"
    }

    func cancel() {}
}
