//
//  MapKitDirectionsService.swift
//  Lana-V2
//

import CoreLocation
import MapKit

@MainActor
final class MapKitDirectionsService: DirectionsProviding {
    private var activeDirections: [ObjectIdentifier: MKDirections] = [:]

    func routes(
        from start: RouteLocation,
        to finish: RouteLocation,
        profile: RoutingProfile,
        requestsAlternateRoutes: Bool
    ) async throws -> [RouteLeg] {
        try Task.checkCancellation()

        let request = MKDirections.Request()
        request.source = mapItem(for: start)
        request.destination = mapItem(for: finish)
        request.transportType = profile.mapKitValue
        request.requestsAlternateRoutes = requestsAlternateRoutes

        let directions = MKDirections(request: request)
        let identifier = ObjectIdentifier(directions)
        activeDirections[identifier] = directions
        defer { activeDirections[identifier] = nil }

        do {
            let response = try await directions.calculate()
            try Task.checkCancellation()

            let legs = response.routes.compactMap(makeLeg)
            guard !legs.isEmpty else { throw DirectionsServiceError.noRoutes }
            return legs
        } catch is CancellationError {
            throw CancellationError()
        } catch let error as DirectionsServiceError {
            throw error
        } catch let error as MKError where error.code == .directionsNotFound {
            throw DirectionsServiceError.noRoutes
        } catch {
            throw DirectionsServiceError.requestFailed(error)
        }
    }

    func cancel() {
        activeDirections.values.forEach { $0.cancel() }
    }

    private func mapItem(for location: RouteLocation) -> MKMapItem {
        let coordinate = location.coordinate
        return MKMapItem(
            location: CLLocation(
                latitude: coordinate.latitude,
                longitude: coordinate.longitude
            ),
            address: nil
        )
    }

    private func makeLeg(from route: MKRoute) -> RouteLeg? {
        guard route.distance.isFinite,
              route.distance > 0,
              route.expectedTravelTime.isFinite,
              route.expectedTravelTime > 0,
              route.polyline.pointCount >= 2 else { return nil }

        var points = Array(
            repeating: CLLocationCoordinate2D(),
            count: route.polyline.pointCount
        )
        route.polyline.getCoordinates(
            &points,
            range: NSRange(location: 0, length: points.count)
        )

        let coordinates = points.map {
            RouteCoordinate(latitude: $0.latitude, longitude: $0.longitude)
        }
        guard coordinates.allSatisfy(\.isValid) else { return nil }

        let instructions = route.steps.map(\.instructions).filter {
            !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        }

        return RouteLeg(
            distanceMeters: route.distance,
            durationSeconds: route.expectedTravelTime,
            coordinates: coordinates,
            instructions: instructions
        )
    }
}

private extension RoutingProfile {
    var mapKitValue: MKDirectionsTransportType {
        switch self {
        case .cycling:
            return .cycling
        case .automobile:
            return .automobile
        }
    }
}
