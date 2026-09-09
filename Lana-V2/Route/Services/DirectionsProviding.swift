//
//  DirectionsProviding.swift
//  Lana-V2
//

import Foundation

@MainActor
protocol DirectionsProviding {
    func routes(
        from start: RouteLocation,
        to finish: RouteLocation,
        profile: RoutingProfile,
        requestsAlternateRoutes: Bool
    ) async throws -> [RouteLeg]

    func cancel()
}

enum DirectionsServiceError: LocalizedError {
    case noRoutes
    case requestFailed(Error)

    var errorDescription: String? {
        switch self {
        case .noRoutes:
            return "No route is available between these points."
        case .requestFailed(let error):
            return error.localizedDescription
        }
    }
}
