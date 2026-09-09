//
//  RouteGenerationService.swift
//  Lana-V2
//

import Foundation

enum RouteGenerationError: LocalizedError {
    case invalidRequest
    case noRoutes

    var errorDescription: String? {
        switch self {
        case .invalidRequest:
            return "The route request is incomplete or invalid."
        case .noRoutes:
            return "No usable route options were found. Try another distance or location."
        }
    }
}

@MainActor
final class RouteGenerationService: RouteGenerating {
    private let directionsService: any DirectionsProviding
    private let candidatePlanner: any RouteCandidatePlanning
    private let rankingService: any RouteRanking

    init(
        directionsService: any DirectionsProviding,
        candidatePlanner: any RouteCandidatePlanning,
        rankingService: any RouteRanking
    ) {
        self.directionsService = directionsService
        self.candidatePlanner = candidatePlanner
        self.rankingService = rankingService
    }

    convenience init() {
        self.init(
            directionsService: MapKitDirectionsService(),
            candidatePlanner: RouteCandidatePlanner(),
            rankingService: RouteRankingService()
        )
    }

    func generateBestRoutes(
        for request: RouteGenerationRequest
    ) async throws -> [Route] {
        guard request.targetDistanceMeters > 0,
              request.start.coordinate.isValid,
              request.routeType == .loop
                || request.finish?.coordinate.isValid == true else {
            throw RouteGenerationError.invalidRequest
        }

        let plans = candidatePlanner.plans(for: request)
        guard !plans.isEmpty else { throw RouteGenerationError.invalidRequest }

        let cyclingRoutes = try await generateCandidates(
            from: plans,
            request: request,
            profile: .cycling
        )

        let selected: [Route]
        if cyclingRoutes.count >= 3 {
            selected = Array(
                rankingService.ranked(
                    cyclingRoutes,
                    targetDistanceKm: request.targetDistanceKm
                ).prefix(3)
            )
        } else {
            let automobileRoutes = try await generateCandidates(
                from: plans,
                request: request,
                profile: .automobile
            )
            let allRanked = rankingService.ranked(
                cyclingRoutes + automobileRoutes,
                targetDistanceKm: request.targetDistanceKm
            )
            let rankedCycling = allRanked.filter {
                $0.routingModeUsed == .cycling
            }
            let rankedFallback = allRanked.filter {
                $0.routingModeUsed == .automobileFallback
            }
            selected = Array((rankedCycling + rankedFallback).prefix(3))
        }

        guard !selected.isEmpty else { throw RouteGenerationError.noRoutes }
        return decorate(selected)
    }

    func cancel() {
        directionsService.cancel()
    }

    private func generateCandidates(
        from plans: [RouteCandidatePlan],
        request: RouteGenerationRequest,
        profile: RoutingProfile
    ) async throws -> [Route] {
        var routes: [Route] = []

        for plan in plans {
            try Task.checkCancellation()

            do {
                routes.append(contentsOf: try await generateRoutes(
                    from: plan,
                    request: request,
                    profile: profile
                ))
            } catch DirectionsServiceError.noRoutes {
                continue
            }
        }

        return routes
    }

    private func generateRoutes(
        from plan: RouteCandidatePlan,
        request: RouteGenerationRequest,
        profile: RoutingProfile
    ) async throws -> [Route] {
        guard let start = plan.points.first,
              let finish = plan.points.last else {
            throw RouteGenerationError.invalidRequest
        }

        if plan.points.count == 2, plan.requestsAlternateRoutes {
            let alternatives = try await directionsService.routes(
                from: start,
                to: finish,
                profile: profile,
                requestsAlternateRoutes: true
            )
            return alternatives.map {
                makeRoute(from: [$0], request: request, profile: profile)
            }
        }

        var legs: [RouteLeg] = []
        for (legStart, legFinish) in zip(
            plan.points,
            plan.points.dropFirst()
        ) {
            guard let leg = try await directionsService.routes(
                from: legStart,
                to: legFinish,
                profile: profile,
                requestsAlternateRoutes: false
            ).first else {
                throw DirectionsServiceError.noRoutes
            }
            legs.append(leg)
        }

        return [makeRoute(from: legs, request: request, profile: profile)]
    }

    private func makeRoute(
        from legs: [RouteLeg],
        request: RouteGenerationRequest,
        profile: RoutingProfile
    ) -> Route {
        let distanceMeters = legs.reduce(0) { $0 + $1.distanceMeters }
        let durationSeconds = legs.reduce(0) { $0 + $1.durationSeconds }
        let instructions = legs.flatMap(\.instructions)
        let coordinates = joinedCoordinates(from: legs)
        let modeUsed: RoutingModeUsed = profile == .cycling
            ? .cycling
            : .automobileFallback

        return Route(
            title: request.routeType.title,
            routeType: request.routeType,
            targetDistanceKm: request.targetDistanceKm,
            distanceKm: distanceMeters / 1_000,
            durationMinutes: Int((durationSeconds / 60).rounded(.up)),
            intersections: instructions.count,
            warningMessage: modeUsed == .automobileFallback
                ? "Cycling directions are unavailable for this route. Road directions are used as an approximation."
                : "",
            overview: overview(for: request, modeUsed: modeUsed),
            startLocation: request.start,
            finishLocation: request.routeType == .loop
                ? request.start
                : request.finish,
            routingModeUsed: modeUsed,
            coordinates: coordinates,
            instructions: instructions
        )
    }

    private func joinedCoordinates(from legs: [RouteLeg]) -> [RouteCoordinate] {
        legs.reduce(into: [RouteCoordinate]()) { result, leg in
            if result.last == leg.coordinates.first {
                result.append(contentsOf: leg.coordinates.dropFirst())
            } else {
                result.append(contentsOf: leg.coordinates)
            }
        }
    }

    private func overview(
        for request: RouteGenerationRequest,
        modeUsed: RoutingModeUsed
    ) -> String {
        let routeDescription = request.routeType == .loop
            ? "A loop starting and finishing at \(request.start.name)."
            : "A route from \(request.start.name) to \(request.finish?.name ?? "the destination")."
        return "\(routeDescription) Generated using \(modeUsed.title.lowercased()) directions."
    }

    private func decorate(_ routes: [Route]) -> [Route] {
        let closestID = routes.min {
            $0.distanceGapKm < $1.distanceGapKm
        }?.id
        let fewestTurnsID = routes.min {
            $0.intersections < $1.intersections
        }?.id
        let fastestID = routes.min {
            $0.durationMinutes < $1.durationMinutes
        }?.id

        return routes.enumerated().map { index, route in
            var decorated = route
            decorated.title = "\(route.routeType.title) Option \(index + 1)"

            if route.id == closestID {
                decorated.badgeTitle = "Closest to Target"
            } else if route.id == fewestTurnsID {
                decorated.badgeTitle = "Fewest Turns"
            } else if route.id == fastestID {
                decorated.badgeTitle = "Fastest"
            }

            return decorated
        }
    }
}
