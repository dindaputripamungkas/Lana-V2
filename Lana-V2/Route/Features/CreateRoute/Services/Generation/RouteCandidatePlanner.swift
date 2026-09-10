//
//  RouteCandidatePlanner.swift
//  Lana-V2
//

import Foundation

struct RouteCandidatePlan: Hashable {
    let points: [RouteLocation]
    let requestsAlternateRoutes: Bool
}

struct RouteCandidateStage: Hashable {
    let plans: [RouteCandidatePlan]
}

protocol RouteCandidatePlanning {
    func stages(for request: RouteGenerationRequest) -> [RouteCandidateStage]
}

struct RouteCandidatePlanner: RouteCandidatePlanning {
    private let earthRadiusMeters = 6_371_000.0

    func stages(for request: RouteGenerationRequest) -> [RouteCandidateStage] {
        switch request.routeType {
        case .loop:
            return loopStages(for: request)
        case .pointToPoint:
            return pointToPointStages(for: request)
        }
    }

    private func loopStages(
        for request: RouteGenerationRequest
    ) -> [RouteCandidateStage] {
        let baseRadius = max(request.targetDistanceMeters / 3.73, 250)

        return [
            loopStage(
                request: request,
                baseRadius: baseRadius,
                radiusFactors: [1],
                bearings: [0, 90, 180, 270]
            ),
            loopStage(
                request: request,
                baseRadius: baseRadius,
                radiusFactors: [0.82, 1.18],
                bearings: [45, 225]
            ),
            loopStage(
                request: request,
                baseRadius: baseRadius,
                radiusFactors: [0.65, 1.42],
                bearings: [90, 270]
            )
        ]
    }

    private func loopStage(
        request: RouteGenerationRequest,
        baseRadius: Double,
        radiusFactors: [Double],
        bearings: [Double]
    ) -> RouteCandidateStage {
        let plans = radiusFactors.flatMap { factor in
            bearings.enumerated().map { index, bearing in
                let clockwise = index.isMultiple(of: 2)
                let secondBearing = bearing + (clockwise ? 120 : -120)
                let radius = min(max(baseRadius * factor, 250), 20_000)
                let first = location(
                    named: "Loop Waypoint 1",
                    from: request.start,
                    distanceMeters: radius,
                    bearingDegrees: bearing
                )
                let second = location(
                    named: "Loop Waypoint 2",
                    from: request.start,
                    distanceMeters: radius,
                    bearingDegrees: secondBearing
                )

                return RouteCandidatePlan(
                    points: [request.start, first, second, request.start],
                    requestsAlternateRoutes: false
                )
            }
        }
        return RouteCandidateStage(plans: plans)
    }

    private func pointToPointStages(
        for request: RouteGenerationRequest
    ) -> [RouteCandidateStage] {
        guard let finish = request.finish else { return [] }

        let direct = RouteCandidateStage(plans: [
            RouteCandidatePlan(
                points: [request.start, finish],
                requestsAlternateRoutes: true
            )
        ])
        let straightLineDistance = distance(
            from: request.start,
            to: finish
        )
        let targetDistance = max(
            request.targetDistanceMeters,
            straightLineDistance
        )
        let squaredOffset = max(
            targetDistance * targetDistance
                - straightLineDistance * straightLineDistance,
            0
        )
        let idealOffset = max(
            sqrt(squaredOffset) * 0.5,
            max(straightLineDistance * 0.12, 250)
        )

        return [
            direct,
            detourStage(
                request: request,
                finish: finish,
                baseOffset: idealOffset,
                factors: [0.55, 0.82, 1.08]
            ),
            detourStage(
                request: request,
                finish: finish,
                baseOffset: idealOffset,
                factors: [1.35, 1.7]
            )
        ]
    }

    private func detourStage(
        request: RouteGenerationRequest,
        finish: RouteLocation,
        baseOffset: Double,
        factors: [Double]
    ) -> RouteCandidateStage {
        let directDistance = distance(from: request.start, to: finish)
        let directBearing = bearing(from: request.start, to: finish)
        let midpoint = location(
            named: "Route Midpoint",
            from: request.start,
            distanceMeters: directDistance / 2,
            bearingDegrees: directBearing
        )

        let plans = [-1.0, 1.0].flatMap { side in
            factors.map { factor in
                let detour = location(
                    named: side < 0
                        ? "Left Detour Waypoint"
                        : "Right Detour Waypoint",
                    from: midpoint,
                    distanceMeters: min(
                        max(baseOffset * factor, 250),
                        42_000
                    ),
                    bearingDegrees: directBearing + (90 * side)
                )
                return RouteCandidatePlan(
                    points: [request.start, detour, finish],
                    requestsAlternateRoutes: false
                )
            }
        }
        return RouteCandidateStage(plans: plans)
    }

    private func distance(
        from start: RouteLocation,
        to finish: RouteLocation
    ) -> Double {
        let startLatitude = start.coordinate.latitude.radians
        let finishLatitude = finish.coordinate.latitude.radians
        let latitudeDelta = finishLatitude - startLatitude
        let longitudeDelta = (
            finish.coordinate.longitude - start.coordinate.longitude
        ).radians
        let haversine = pow(sin(latitudeDelta / 2), 2)
            + cos(startLatitude)
                * cos(finishLatitude)
                * pow(sin(longitudeDelta / 2), 2)
        let clampedHaversine = min(max(haversine, 0), 1)
        return earthRadiusMeters * 2 * atan2(
            sqrt(clampedHaversine),
            sqrt(1 - clampedHaversine)
        )
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
            cos(angularDistance)
                - sin(latitude) * sin(destinationLatitude)
        )

        return RouteLocation(
            name: name,
            coordinate: RouteCoordinate(
                latitude: destinationLatitude.degrees,
                longitude: normalizedLongitude(
                    destinationLongitude.degrees
                )
            )
        )
    }

    private func normalizedLongitude(_ longitude: Double) -> Double {
        (longitude + 540).truncatingRemainder(dividingBy: 360) - 180
    }
}

private extension Double {
    var radians: Double { self * .pi / 180 }
    var degrees: Double { self * 180 / .pi }
}
