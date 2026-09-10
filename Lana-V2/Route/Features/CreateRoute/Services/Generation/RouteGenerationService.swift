//
//  RouteGenerationService.swift
//  Lana-V2
//

import Foundation

enum RouteGenerationError: LocalizedError {
    case invalidRequest
    case targetDistanceTooShort(minimumMeters: Double)
    case noRoutes

    var errorDescription: String? {
        switch self {
        case .invalidRequest:
            return "Complete the route type, distance, and required waypoints."
        case .targetDistanceTooShort(let minimumMeters):
            return String(
                format: "The selected places need at least %.1f km. Increase the target distance.",
                minimumMeters / 1_000
            )
        case .noRoutes:
            return "No usable route options were found. Try another distance or move the waypoint closer to a public road."
        }
    }
}

@MainActor
final class RouteGenerationService: RouteGenerating {
    private let directionsService: any DirectionsProviding
    private let candidatePlanner: any RouteCandidatePlanning
    private let rankingService: any RouteRanking
    private let policy: any RouteGenerationPolicyEvaluating
    private let cache: any RouteGenerationCaching
    private let fallbackCyclingSpeedMetersPerSecond = 18.0 / 3.6

    init(
        directionsService: any DirectionsProviding,
        candidatePlanner: any RouteCandidatePlanning,
        rankingService: any RouteRanking,
        policy: any RouteGenerationPolicyEvaluating,
        cache: any RouteGenerationCaching
    ) {
        self.directionsService = directionsService
        self.candidatePlanner = candidatePlanner
        self.rankingService = rankingService
        self.policy = policy
        self.cache = cache
    }

    convenience init(
        directionsService: any DirectionsProviding,
        candidatePlanner: any RouteCandidatePlanning,
        rankingService: any RouteRanking
    ) {
        self.init(
            directionsService: directionsService,
            candidatePlanner: candidatePlanner,
            rankingService: rankingService,
            policy: RouteGenerationPolicy(),
            cache: MemoryRouteGenerationCache()
        )
    }

    convenience init() {
        self.init(
            directionsService: MapKitDirectionsService(),
            candidatePlanner: RouteCandidatePlanner(),
            rankingService: RouteRankingService()
        )
    }

    func minimumDistance(
        from start: RouteLocation,
        to finish: RouteLocation
    ) async throws -> Double {
        guard start.coordinate.isValid, finish.coordinate.isValid else {
            throw RouteGenerationError.invalidRequest
        }

        do {
            let cycling = try await directionsService.routes(
                from: start,
                to: finish,
                profile: .cycling,
                requestsAlternateRoutes: false
            )
            if let shortest = cycling.map(\.distanceMeters).min() {
                return shortest
            }
        } catch DirectionsServiceError.noRoutes {
            // Continue with road directions when cycling is unavailable.
        }

        let roadRoutes = try await directionsService.routes(
            from: start,
            to: finish,
            profile: .automobile,
            requestsAlternateRoutes: false
        )
        guard let shortest = roadRoutes.map(\.distanceMeters).min() else {
            throw RouteGenerationError.noRoutes
        }
        return shortest
    }

    func generateBestRoutes(
        for request: RouteGenerationRequest
    ) async throws -> [Route] {
        try validate(request)

        if let cachedRoutes = cache.routes(for: request) {
            return cachedRoutes
        }

        if request.routeType == .pointToPoint,
           let finish = request.finish {
            let minimum = try await minimumDistance(
                from: request.start,
                to: finish
            )
            if policy.isTargetTooShort(
                targetMeters: request.targetDistanceMeters,
                minimumMeters: minimum
            ) {
                throw RouteGenerationError.targetDistanceTooShort(
                    minimumMeters: minimum
                )
            }
        }

        let stages = candidatePlanner.stages(for: request)
        guard !stages.isEmpty else {
            throw RouteGenerationError.invalidRequest
        }

        var candidates: [Route] = []
        var consecutiveEmptyCyclingStages = 0
        for stage in stages {
            try Task.checkCancellation()
            let generated = await generateCandidates(
                from: stage,
                request: request,
                profile: .cycling
            )
            candidates.append(contentsOf: generated)
            consecutiveEmptyCyclingStages = generated.isEmpty
                ? consecutiveEmptyCyclingStages + 1
                : 0

            let acceptableCycling = policy.acceptableRoutes(
                from: candidates.filter {
                    $0.routingModeUsed == .cycling
                },
                for: request
            )
            if rankingService.ranked(
                acceptableCycling,
                targetDistanceKm: request.targetDistanceKm
            ).count >= 3 {
                let routes = selectedRoutes(
                    from: candidates,
                    for: request
                )
                cache.insert(routes, for: request)
                return routes
            }

            if consecutiveEmptyCyclingStages >= 2 {
                break
            }
        }

        for stage in stages {
            try Task.checkCancellation()
            candidates.append(contentsOf: await generateCandidates(
                from: stage,
                request: request,
                profile: .automobile
            ))

            let acceptable = policy.acceptableRoutes(
                from: candidates,
                for: request
            )
            if rankingService.ranked(
                acceptable,
                targetDistanceKm: request.targetDistanceKm
            ).count >= 3 {
                break
            }
        }

        try Task.checkCancellation()
        guard !candidates.isEmpty else {
            throw RouteGenerationError.noRoutes
        }

        let routes = selectedRoutes(from: candidates, for: request)
        guard !routes.isEmpty else { throw RouteGenerationError.noRoutes }
        cache.insert(routes, for: request)
        return routes
    }

    func cancel() {
        directionsService.cancel()
    }

    private func validate(_ request: RouteGenerationRequest) throws {
        guard request.targetDistanceMeters >= 1_000,
              request.targetDistanceMeters <= 200_000,
              request.start.coordinate.isValid,
              request.routeType == .loop
                || request.finish?.coordinate.isValid == true else {
            throw RouteGenerationError.invalidRequest
        }
    }

    private func generateCandidates(
        from stage: RouteCandidateStage,
        request: RouteGenerationRequest,
        profile: RoutingProfile
    ) async -> [Route] {
        await withTaskGroup(of: [Route].self) { group in
            for plan in stage.plans {
                group.addTask { @MainActor [self] in
                    do {
                        return try await generateRoutes(
                            from: plan,
                            request: request,
                            profile: profile
                        )
                    } catch {
                        return []
                    }
                }
            }

            var routes: [Route] = []
            for await generatedRoutes in group {
                routes.append(contentsOf: generatedRoutes)
            }
            return routes
        }
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
            return alternatives.prefix(3).map {
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
        let mapKitDuration = legs.reduce(0) { $0 + $1.durationSeconds }
        let durationSeconds = profile == .cycling
            ? mapKitDuration
            : distanceMeters / fallbackCyclingSpeedMetersPerSecond
        let steps = legs.flatMap(\.steps)
        let instructions = steps.map(\.instruction)
        let modeUsed: RoutingModeUsed = profile == .cycling
            ? .cycling
            : .automobileFallback

        return Route(
            title: request.routeType.title,
            routeType: request.routeType,
            targetDistanceKm: request.targetDistanceKm,
            distanceKm: distanceMeters / 1_000,
            durationMinutes: Int((durationSeconds / 60).rounded(.up)),
            intersections: steps.count,
            warningMessage: modeUsed == .automobileFallback
                ? "Cycling directions are unavailable for this option. Road geometry is used with cycling-time estimation."
                : "",
            overview: overview(for: request, modeUsed: modeUsed),
            startLocation: request.start,
            finishLocation: request.routeType == .loop
                ? request.start
                : request.finish,
            routingModeUsed: modeUsed,
            coordinates: joinedCoordinates(from: legs),
            instructions: instructions,
            steps: steps
        )
    }

    private func selectedRoutes(
        from candidates: [Route],
        for request: RouteGenerationRequest
    ) -> [Route] {
        let rankedCandidates = rankingService.ranked(
            candidates,
            targetDistanceKm: request.targetDistanceKm
        )
        let acceptable = rankedCandidates.filter {
            policy.isAcceptable($0, for: request)
        }
        var ordered = preferredModeOrder(acceptable)

        if ordered.count < 3 {
            let remaining = rankedCandidates.filter {
                !policy.isAcceptable($0, for: request)
            }
            ordered.append(contentsOf: preferredModeOrder(remaining))
        }

        return decorate(
            Array(ordered.prefix(3)),
            request: request
        )
    }

    private func preferredModeOrder(_ routes: [Route]) -> [Route] {
        routes.filter { $0.routingModeUsed == .cycling }
            + routes.filter { $0.routingModeUsed == .automobileFallback }
    }

    private func decorate(
        _ routes: [Route],
        request: RouteGenerationRequest
    ) -> [Route] {
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

            if !policy.isAcceptable(route, for: request) {
                let notice = "This is one of the closest available routes, but it is outside the preferred target range."
                decorated.warningMessage = [
                    decorated.warningMessage,
                    notice
                ]
                .filter { !$0.isEmpty }
                .joined(separator: " ")
            }
            return decorated
        }
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
}
