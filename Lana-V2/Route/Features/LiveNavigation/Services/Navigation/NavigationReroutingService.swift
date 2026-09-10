//
//  NavigationReroutingService.swift
//  Lana-V2
//

import Foundation

@MainActor
final class NavigationReroutingService: NavigationRerouting {
    private let directionsService: any DirectionsProviding

    init(directionsService: any DirectionsProviding) {
        self.directionsService = directionsService
    }

    convenience init() {
        self.init(directionsService: MapKitDirectionsService())
    }

    func reroute(
        route: Route,
        from currentLocation: RouteLocation,
        to destination: RouteLocation
    ) async throws -> Route {
        let result: (leg: RouteLeg, mode: RoutingModeUsed)

        do {
            guard let leg = try await directionsService.routes(
                from: currentLocation,
                to: destination,
                profile: .cycling,
                requestsAlternateRoutes: true
            ).first else {
                throw DirectionsServiceError.noRoutes
            }
            result = (leg, .cycling)
        } catch DirectionsServiceError.noRoutes {
            guard let leg = try await directionsService.routes(
                from: currentLocation,
                to: destination,
                profile: .automobile,
                requestsAlternateRoutes: true
            ).first else {
                throw DirectionsServiceError.noRoutes
            }
            result = (leg, .automobileFallback)
        }

        var updatedRoute = route
        updatedRoute.startLocation = currentLocation
        updatedRoute.finishLocation = destination
        updatedRoute.distanceKm = result.leg.distanceMeters / 1_000
        updatedRoute.durationMinutes = Int(
            (result.leg.durationSeconds / 60).rounded(.up)
        )
        updatedRoute.intersections = result.leg.steps.count
        updatedRoute.routingModeUsed = result.mode
        updatedRoute.coordinates = result.leg.coordinates
        updatedRoute.steps = result.leg.steps
        updatedRoute.instructions = result.leg.instructions
        updatedRoute.badgeTitle = nil
        updatedRoute.warningMessage = result.mode == .automobileFallback
            ? "Cycling directions are unavailable here. Road directions are used as an approximation."
            : ""
        updatedRoute.overview = "Updated from your current location to rejoin the ride."
        return updatedRoute
    }

    func cancel() {
        directionsService.cancel()
    }
}
