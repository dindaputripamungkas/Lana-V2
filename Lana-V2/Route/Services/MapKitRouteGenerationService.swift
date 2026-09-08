//
//  MapKitRouteGenerationService.swift
//  Lana-V2
//
//  Created by Imam on 08/09/26.
//
import CoreLocation
import MapKit

@MainActor
final class MapKitRouteGenerationService: MapKitRouteGenerating {
    private var activeDirections: MKDirections?

    func generateOptions(
        from start: RouteLocation,
        to finish: RouteLocation,
        mode: RouteTransportMode
    ) async throws -> [Route] {
        guard activeDirections == nil else { throw MapKitRouteGenerationError.busy }
        guard start.coordinate.isValid, finish.coordinate.isValid else {
            throw MapKitRouteGenerationError.invalidLocations
        }

        let origin = CLLocation(
            latitude: start.coordinate.latitude, longitude: start.coordinate.longitude
        )
        let destination = CLLocation(
            latitude: finish.coordinate.latitude, longitude: finish.coordinate.longitude
        )
        guard origin.distance(from: destination) >= 50 else {
            throw MapKitRouteGenerationError.invalidLocations
        }

        try Task.checkCancellation()
        let request = MKDirections.Request()
        request.source = MKMapItem(location: origin, address: nil)
        request.destination = MKMapItem(location: destination, address: nil)
        request.transportType = mode.mapKitValue
        request.requestsAlternateRoutes = true

        let directions = MKDirections(request: request)
        activeDirections = directions
        defer { activeDirections = nil }

        let response = try await directions.calculate()
        try Task.checkCancellation()

        let options = response.routes.compactMap { route -> Route? in
            guard route.transportType == mode.mapKitValue,
                  route.distance.isFinite, route.distance > 0,
                  route.expectedTravelTime.isFinite, route.expectedTravelTime > 0,
                  route.polyline.pointCount >= 2 else { return nil }

            var points = Array(
                repeating: CLLocationCoordinate2D(), count: route.polyline.pointCount
            )
            route.polyline.getCoordinates(
                &points, range: NSRange(location: 0, length: points.count)
            )
            let coordinates = points.map {
                RouteCoordinate(latitude: $0.latitude, longitude: $0.longitude)
            }
            guard coordinates.allSatisfy(\.isValid) else { return nil }
            let instructions = route.steps.map(\.instructions).filter {
                !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            }

            return Route(
                title: route.name.isEmpty ? "Route" : route.name,
                distanceKm: route.distance / 1_000,
                durationMinutes: Int((route.expectedTravelTime / 60).rounded(.up)),
                intersections: instructions.count,
                routeKindTitle: mode.rawValue,
                overview: "\(start.name) to \(finish.name)",
                startLocation: start,
                finishLocation: finish,
                transportMode: mode,
                coordinates: coordinates,
                instructions: instructions,
                isPreview: false
            )
        }
        guard !options.isEmpty else { throw MapKitRouteGenerationError.noRoutes }
        return options.sorted { $0.distanceKm < $1.distanceKm }
    }

    func cancel() {
        activeDirections?.cancel()
    }
}
