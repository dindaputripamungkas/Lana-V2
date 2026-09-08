//
//  MapKitRouteGenerating.swift
//  Lana-V2
//

import Foundation

@MainActor
protocol MapKitRouteGenerating {
    func generateOptions(
        from start: RouteLocation,
        to finish: RouteLocation,
        mode: RouteTransportMode
    ) async throws -> [Route]

    func cancel()
}

enum MapKitRouteGenerationError: LocalizedError {
    case invalidLocations
    case noRoutes
    case busy

    var errorDescription: String? {
        switch self {
        case .invalidLocations:
            return "Choose two valid locations at least 50 meters apart."
        case .noRoutes:
            return "No route was returned for these locations and this travel mode."
        case .busy:
            return "A route request is already running."
        }
    }
}
