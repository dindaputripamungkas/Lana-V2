//
//  RouteRankingService.swift
//  Lana-V2
//

import Foundation

protocol RouteRanking {
    func ranked(
        _ routes: [Route],
        targetDistanceKm: Double
    ) -> [Route]
}

struct RouteRankingService: RouteRanking {
    func ranked(
        _ routes: [Route],
        targetDistanceKm: Double
    ) -> [Route] {
        let uniqueRoutes = deduplicated(routes)
        let maximumIntersections = max(
            uniqueRoutes.map(\.intersections).max() ?? 1,
            1
        )
        let maximumDuration = max(
            uniqueRoutes.map(\.durationMinutes).max() ?? 1,
            1
        )

        return uniqueRoutes.sorted { first, second in
            let firstScore = score(
                for: first,
                targetDistanceKm: targetDistanceKm,
                maximumIntersections: maximumIntersections,
                maximumDuration: maximumDuration
            )
            let secondScore = score(
                for: second,
                targetDistanceKm: targetDistanceKm,
                maximumIntersections: maximumIntersections,
                maximumDuration: maximumDuration
            )

            if firstScore == secondScore {
                return first.durationMinutes < second.durationMinutes
            }
            return firstScore < secondScore
        }
    }

    private func score(
        for route: Route,
        targetDistanceKm: Double,
        maximumIntersections: Int,
        maximumDuration: Int
    ) -> Double {
        let safeTarget = max(targetDistanceKm, 0.1)
        let distanceGapRatio = abs(route.distanceKm - safeTarget) / safeTarget
        let intersectionRatio = Double(route.intersections)
            / Double(maximumIntersections)
        let durationRatio = Double(max(route.durationMinutes, 1))
            / Double(maximumDuration)

        return (distanceGapRatio * 0.85)
            + (intersectionRatio * 0.10)
            + (durationRatio * 0.05)
    }

    private func deduplicated(_ routes: [Route]) -> [Route] {
        var seen = Set<String>()
        return routes.filter { route in
            seen.insert(geometryKey(for: route)).inserted
        }
    }

    private func geometryKey(for route: Route) -> String {
        guard route.coordinates.count > 2 else {
            return "\(route.distanceKm)-\(route.durationMinutes)-\(route.intersections)"
        }

        let lastIndex = route.coordinates.count - 1
        let sampleIndices = (0...6).map {
            Int((Double(lastIndex) * Double($0) / 6).rounded())
        }

        return sampleIndices.map { index in
            let coordinate = route.coordinates[index]
            let latitude = Int((coordinate.latitude * 10_000).rounded())
            let longitude = Int((coordinate.longitude * 10_000).rounded())
            return "\(latitude):\(longitude)"
        }.joined(separator: "|")
    }
}
