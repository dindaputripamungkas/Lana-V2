//
//  MapKitRouteProgressService.swift
//  Lana-V2
//

import MapKit

@MainActor
final class MapKitRouteProgressService: RouteProgressProjecting {
    private struct ProjectionCandidate {
        let progressMeters: Double
        let distanceFromRouteMeters: Double
        let segmentIndex: Int
        let point: MKMapPoint
    }

    private var routePoints: [MKMapPoint] = []
    private var cumulativeDistances: [Double] = []

    var routeLengthMeters: Double {
        cumulativeDistances.last ?? 0
    }

    func prepare(coordinates: [RouteCoordinate]) {
        routePoints = coordinates
            .filter(\.isValid)
            .map { MKMapPoint($0.clCoordinate) }

        guard !routePoints.isEmpty else {
            cumulativeDistances = []
            return
        }

        cumulativeDistances = [0]
        cumulativeDistances.reserveCapacity(routePoints.count)

        for index in 1..<routePoints.count {
            cumulativeDistances.append(
                cumulativeDistances[index - 1]
                    + routePoints[index - 1].distance(to: routePoints[index])
            )
        }
    }

    func project(
        _ coordinate: RouteCoordinate,
        minimumProgressMeters: Double
    ) -> RouteProgress? {
        guard coordinate.isValid,
              routePoints.count > 1,
              cumulativeDistances.count == routePoints.count else {
            return nil
        }

        let userPoint = MKMapPoint(coordinate.clCoordinate)
        var nearestForward: ProjectionCandidate?
        var nearestAbsolute: ProjectionCandidate?
        let maximumForwardJump = min(
            max(routeLengthMeters * 0.1, 250),
            1_000
        )

        for index in 0..<(routePoints.count - 1) {
            let start = routePoints[index]
            let finish = routePoints[index + 1]
            let dx = finish.x - start.x
            let dy = finish.y - start.y
            let squaredLength = dx * dx + dy * dy
            guard squaredLength > 0 else { continue }

            let rawPosition = (
                (userPoint.x - start.x) * dx
                    + (userPoint.y - start.y) * dy
            ) / squaredLength
            let position = min(max(rawPosition, 0), 1)
            let projectedPoint = MKMapPoint(
                x: start.x + position * dx,
                y: start.y + position * dy
            )
            let segmentLength = start.distance(to: finish)
            let candidate = ProjectionCandidate(
                progressMeters: cumulativeDistances[index]
                    + segmentLength * position,
                distanceFromRouteMeters: userPoint.distance(
                    to: projectedPoint
                ),
                segmentIndex: index,
                point: projectedPoint
            )

            if nearestAbsolute == nil
                || candidate.distanceFromRouteMeters
                    < nearestAbsolute!.distanceFromRouteMeters {
                nearestAbsolute = candidate
            }

            let backwardTolerance = 80.0
            if candidate.progressMeters
                >= minimumProgressMeters - backwardTolerance,
               candidate.progressMeters
                <= minimumProgressMeters + maximumForwardJump,
               nearestForward == nil
                || candidate.distanceFromRouteMeters
                    < nearestForward!.distanceFromRouteMeters {
                nearestForward = candidate
            }
        }

        guard let best = nearestForward ?? nearestAbsolute else { return nil }
        let coordinate = best.point.coordinate
        return RouteProgress(
            distanceAlongRouteMeters: best.progressMeters,
            distanceFromRouteMeters: best.distanceFromRouteMeters,
            segmentIndex: best.segmentIndex,
            snappedCoordinate: RouteCoordinate(
                latitude: coordinate.latitude,
                longitude: coordinate.longitude
            )
        )
    }

    func distance(
        from start: RouteCoordinate,
        to finish: RouteCoordinate
    ) -> Double {
        guard start.isValid, finish.isValid else { return 0 }
        return MKMapPoint(start.clCoordinate).distance(
            to: MKMapPoint(finish.clCoordinate)
        )
    }
}
