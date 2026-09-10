//
//  RouteGenerating.swift
//  Lana-V2
//

@MainActor
protocol RouteGenerating {
    func minimumDistance(
        from start: RouteLocation,
        to finish: RouteLocation
    ) async throws -> Double

    func generateBestRoutes(
        for request: RouteGenerationRequest
    ) async throws -> [Route]

    func cancel()
}
