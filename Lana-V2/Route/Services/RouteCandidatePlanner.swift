//
//  RouteCandidatePlanner.swift
//  Lana-V2
//

import CoreLocation
import Foundation

struct RouteCandidatePlan: Hashable {
    let points: [RouteLocation]
    let requestsAlternateRoutes: Bool
}

protocol RouteCandidatePlanning {
    func plans(for request: RouteGenerationRequest) -> [RouteCandidatePlan]
}

struct RouteCandidatePlanner: RouteCandidatePlanning {
    private let earthRadiusMeters = 6_371_000.0

    func plans(for request: RouteGenerationRequest) -> [RouteCandidatePlan] {
        switch request.routeType {
        case .loop:
            return loopPlans(for: request)
        case .pointToPoint:
            return pointToPointPlans(for: request)
        }
    }

    private func loopPlans(
        for request: RouteGenerationRequest
    ) -> [RouteCandidatePlan] {
        let radius = max(request.targetDistanceMeters / 3.73, 250)
        let bearings = stride(from: 0.0, to: 360.0, by: 120.0)
        let radiusFactors = [0.82, 1.05]

        return radiusFactors.flatMap { factor in
            bearings.map { bearing in
                let first = location(
                    named: "Loop Waypoint 1",
                    from: request.start,
                    distanceMeters: radius * factor,
                    bearingDegrees: bearing
                )
                let second = location(
                    named: "Loop Waypoint 2",
                    from: request.start,
                    distanceMeters: radius * factor,
                    bearingDegrees: bearing + 120
                )

                return RouteCandidatePlan(
                    points: [request.start, first, second, request.start],
                    requestsAlternateRoutes: false
                )
            }
        }
    }

    private func pointToPointPlans(
        for request: RouteGenerationRequest
    ) -> [RouteCandidatePlan] {
        guard let finish = request.finish else { return [] }

        var plans = [
            RouteCandidatePlan(
                points: [request.start, finish],
                requestsAlternateRoutes: true
            )
        ]

        let directDistance = distance(from: request.start, to: finish)
        let targetDistance = max(request.targetDistanceMeters, directDistance)
        let squaredOffset = max(
            targetDistance * targetDistance - directDistance * directDistance,
            0
        )
        let idealOffset = 0.5 * sqrt(squaredOffset)
        let baseOffset = max(idealOffset, max(directDistance * 0.12, 250))
        let midpoint = location(
            named: "Route Midpoint",
            from: request.start,
            distanceMeters: directDistance / 2,
            bearingDegrees: bearing(from: request.start, to: finish)
        )
        let directBearing = bearing(from: request.start, to: finish)

        for side in [-1.0, 1.0] {
            for factor in [0.65, 1.0, 1.3] {
                let detour = location(
                    named: "Detour Waypoint",
                    from: midpoint,
                    distanceMeters: baseOffset * factor,
                    bearingDegrees: directBearing + (90 * side)
                )
                plans.append(RouteCandidatePlan(
                    points: [request.start, detour, finish],
                    requestsAlternateRoutes: false
                ))
            }
        }

        return plans
    }

    private func distance(
        from start: RouteLocation,
        to finish: RouteLocation
    ) -> CLLocationDistance {
        CLLocation(
            latitude: start.coordinate.latitude,
            longitude: start.coordinate.longitude
        ).distance(from: CLLocation(
            latitude: finish.coordinate.latitude,
            longitude: finish.coordinate.longitude
        ))
    }

    private func bearing(
        from start: RouteLocation,
        to finish: RouteLocation
    ) -> Double {
        let startLatitude = start.coordinate.latitude.radians
        let finishLatitude = finish.coordinate.latitude.radians
        let longitudeDelta = (
            finish.coordinate.longitude - start.coordinate.longitude
        ).radians
        let y = sin(longitudeDelta) * cos(finishLatitude)
        let x = cos(startLatitude) * sin(finishLatitude)
            - sin(startLatitude) * cos(finishLatitude) * cos(longitudeDelta)
        return atan2(y, x).degrees
    }

    private func location(
        named name: String,
        from origin: RouteLocation,
        distanceMeters: Double,
        bearingDegrees: Double
    ) -> RouteLocation {
        let angularDistance = distanceMeters / earthRadiusMeters
        let bearing = bearingDegrees.radians
        let latitude = origin.coordinate.latitude.radians
        let longitude = origin.coordinate.longitude.radians

        let destinationLatitude = asin(
            sin(latitude) * cos(angularDistance)
                + cos(latitude) * sin(angularDistance) * cos(bearing)
        )
        let destinationLongitude = longitude + atan2(
            sin(bearing) * sin(angularDistance) * cos(latitude),
            cos(angularDistance) - sin(latitude) * sin(destinationLatitude)
        )

        return RouteLocation(
            name: name,
            coordinate: RouteCoordinate(
                latitude: destinationLatitude.degrees,
                longitude: destinationLongitude.degrees
            )
        )
    }
}

private extension Double {
    var radians: Double { self * .pi / 180 }
    var degrees: Double { self * 180 / .pi }
}
