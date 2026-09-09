//
//  RouteGenerating.swift
//  Lana-V2
//

@MainActor
protocol RouteGenerating {
    func generateBestRoutes(
        for request: RouteGenerationRequest
    ) async throws -> [Route]

    func cancel()
}
