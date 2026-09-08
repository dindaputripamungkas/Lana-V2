//
//  MapKitPlaceSearchService.swift
//  Lana-V2
//
//  Created by Imam on 08/09/26.
//

import MapKit

@MainActor
final class MapKitPlaceSearchService: PlaceSearching {
    private var activeSearch: MKLocalSearch?

    func search(_ query: String) async throws -> [RouteLocation] {
        let text = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { return [] }
        cancel()
        try Task.checkCancellation()

        let request = MKLocalSearch.Request()
        request.naturalLanguageQuery = text
        request.resultTypes = [.address, .pointOfInterest]
        let search = MKLocalSearch(request: request)
        activeSearch = search
        defer {
            if activeSearch === search { activeSearch = nil }
        }

        let response = try await search.start()
        try Task.checkCancellation()
        var seen = Set<RouteLocation>()
        return response.mapItems.compactMap { item in
            let coordinate = item.location.coordinate
            let place = RouteLocation(
                name: item.name ?? text,
                coordinate: RouteCoordinate(
                    latitude: coordinate.latitude, longitude: coordinate.longitude
                )
            )
            guard place.coordinate.isValid, seen.insert(place).inserted else { return nil }
            return place
        }
    }

    func cancel() {
        activeSearch?.cancel()
    }
}
