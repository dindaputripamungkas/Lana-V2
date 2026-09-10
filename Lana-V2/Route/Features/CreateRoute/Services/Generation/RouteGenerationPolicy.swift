//
//  RouteGenerationPolicy.swift
//  Lana-V2
//

import Foundation

protocol RouteGenerationPolicyEvaluating {
    func isTargetTooShort(
        targetMeters: Double,
        minimumMeters: Double
    ) -> Bool
    func acceptableRoutes(
        from routes: [Route],
        for request: RouteGenerationRequest
    ) -> [Route]
    func isAcceptable(
        _ route: Route,
        for request: RouteGenerationRequest
    ) -> Bool
}

struct RouteGenerationPolicy: RouteGenerationPolicyEvaluating {
    func isTargetTooShort(
        targetMeters: Double,
        minimumMeters: Double
    ) -> Bool {
        targetMeters + 100 < minimumMeters
    }

    func acceptableRoutes(
        from routes: [Route],
        for request: RouteGenerationRequest
    ) -> [Route] {
        routes.filter { isAcceptable($0, for: request) }
    }

    func isAcceptable(
        _ route: Route,
        for request: RouteGenerationRequest
    ) -> Bool {
        let target = request.targetDistanceMeters
        let routeDistance = route.distanceKm * 1_000

        switch request.routeType {
        case .loop:
            let shortfall = max(1_200, min(3_500, target * 0.22))
            let overage = max(1_200, min(3_500, target * 0.18))
            return routeDistance >= max(0, target - shortfall)
                && routeDistance <= target + overage
        case .pointToPoint:
            let shortfall = max(800, min(3_000, target * 0.16))
            let overage = max(800, min(2_500, target * 0.12))
            return routeDistance >= max(0, target - shortfall)
                && routeDistance <= target + overage
        }
    }
}
