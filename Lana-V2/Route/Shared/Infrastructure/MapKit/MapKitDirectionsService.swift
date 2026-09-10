//
//  MapKitDirectionsService.swift
//  Lana-V2
//

import CoreLocation
import Foundation
import MapKit

@MainActor
final class MapKitDirectionsService: DirectionsProviding {
    private struct CacheKey: Hashable {
        let startLatitude: Int
        let startLongitude: Int
        let finishLatitude: Int
        let finishLongitude: Int
        let profile: RoutingProfile
        let includesAlternates: Bool
    }

    private let throttle: MapKitDirectionsRequestThrottle
    private let cacheLimit: Int
    private var activeDirections: [ObjectIdentifier: MKDirections] = [:]
    private var cache: [CacheKey: [RouteLeg]] = [:]
    private var cacheOrder: [CacheKey] = []

    init(
        throttle: MapKitDirectionsRequestThrottle = .shared,
        cacheLimit: Int = 220
    ) {
        self.throttle = throttle
        self.cacheLimit = max(1, cacheLimit)
    }

    func routes(
        from start: RouteLocation,
        to finish: RouteLocation,
        profile: RoutingProfile,
        requestsAlternateRoutes: Bool
    ) async throws -> [RouteLeg] {
        try Task.checkCancellation()

        let key = cacheKey(
            start: start,
            finish: finish,
            profile: profile,
            requestsAlternateRoutes: requestsAlternateRoutes
        )
        if let cached = cachedRoutes(for: key) {
            guard !cached.isEmpty else {
                throw DirectionsServiceError.noRoutes
            }
            return cached
        }

        for attempt in 0..<2 {
            try await throttle.acquire()

            do {
                let response = try await calculate(
                    start: start,
                    finish: finish,
                    profile: profile,
                    requestsAlternateRoutes: requestsAlternateRoutes
                )
                try Task.checkCancellation()

                let legs = response.routes.compactMap(makeLeg)
                guard !legs.isEmpty else {
                    insert([], for: key)
                    throw DirectionsServiceError.noRoutes
                }
                insert(legs, for: key)
                return legs
            } catch is CancellationError {
                throw CancellationError()
            } catch DirectionsServiceError.noRoutes {
                throw DirectionsServiceError.noRoutes
            } catch let error as DirectionsServiceError {
                throw error
            } catch {
                if attempt == 0, shouldRetry(error) {
                    try await Task.sleep(for: .milliseconds(800))
                    continue
                }
                throw mappedError(error)
            }
        }

        throw DirectionsServiceError.noRoutes
    }

    func cancel() {
        activeDirections.values.forEach { $0.cancel() }
    }

    private func calculate(
        start: RouteLocation,
        finish: RouteLocation,
        profile: RoutingProfile,
        requestsAlternateRoutes: Bool
    ) async throws -> MKDirections.Response {
        let request = MKDirections.Request()
        request.source = mapItem(for: start)
        request.destination = mapItem(for: finish)
        request.transportType = profile.mapKitValue
        request.requestsAlternateRoutes = requestsAlternateRoutes

        let directions = MKDirections(request: request)
        let identifier = ObjectIdentifier(directions)
        activeDirections[identifier] = directions
        defer { activeDirections[identifier] = nil }

        return try await withThrowingTaskGroup(
            of: MKDirections.Response.self
        ) { group in
            group.addTask {
                try await directions.calculate()
            }
            group.addTask {
                try await Task.sleep(for: .seconds(8))
                directions.cancel()
                throw DirectionsServiceError.timedOut
            }

            defer { group.cancelAll() }
            guard let response = try await group.next() else {
                throw DirectionsServiceError.noRoutes
            }
            return response
        }
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
              route.polyline.pointCount >= 2 else {
            return nil
        }

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

        let steps = route.steps.compactMap { step -> RouteStep? in
            let instruction = step.instructions
                .trimmingCharacters(in: .whitespacesAndNewlines)
            guard !instruction.isEmpty else { return nil }

            return RouteStep(
                instruction: instruction,
                distanceMeters: max(0, step.distance)
            )
        }

        return RouteLeg(
            distanceMeters: route.distance,
            durationSeconds: route.expectedTravelTime,
            coordinates: coordinates,
            steps: steps
        )
    }

    private func shouldRetry(_ error: Error) -> Bool {
        let nsError = error as NSError
        if nsError.domain == "GEOErrorDomain", nsError.code == -3 {
            return true
        }

        guard let mapError = error as? MKError else { return false }
        return mapError.code == .loadingThrottled
            || mapError.code == .serverFailure
    }

    private func mappedError(_ error: Error) -> Error {
        if let mapError = error as? MKError,
           mapError.code == .directionsNotFound {
            return DirectionsServiceError.noRoutes
        }
        return DirectionsServiceError.requestFailed(error)
    }

    private func cacheKey(
        start: RouteLocation,
        finish: RouteLocation,
        profile: RoutingProfile,
        requestsAlternateRoutes: Bool
    ) -> CacheKey {
        CacheKey(
            startLatitude: quantized(start.coordinate.latitude),
            startLongitude: quantized(start.coordinate.longitude),
            finishLatitude: quantized(finish.coordinate.latitude),
            finishLongitude: quantized(finish.coordinate.longitude),
            profile: profile,
            includesAlternates: requestsAlternateRoutes
        )
    }

    private func quantized(_ value: Double) -> Int {
        Int((value * 1_000_000).rounded())
    }

    private func cachedRoutes(for key: CacheKey) -> [RouteLeg]? {
        guard let routes = cache[key] else { return nil }
        touch(key)
        return routes
    }

    private func insert(_ routes: [RouteLeg], for key: CacheKey) {
        cache[key] = routes
        touch(key)

        while cacheOrder.count > cacheLimit {
            cache[cacheOrder.removeFirst()] = nil
        }
    }

    private func touch(_ key: CacheKey) {
        cacheOrder.removeAll { $0 == key }
        cacheOrder.append(key)
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
