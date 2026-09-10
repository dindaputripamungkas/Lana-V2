//
//  PlaceSearching.swift
//  Lana-V2
//
//  Created by Imam on 08/09/26.
//

@MainActor
protocol PlaceSearching {
    func suggestions(
        for query: String,
        in region: PlaceSearchRegion?
    ) async throws -> [PlaceSearchSuggestion]

    func resolve(
        _ suggestion: PlaceSearchSuggestion,
        in region: PlaceSearchRegion?
    ) async throws -> RouteLocation

    func nearbyLocation(
        at coordinate: RouteCoordinate,
        maximumDistanceMeters: Double
    ) async throws -> RouteLocation?

    func cancel()
}
