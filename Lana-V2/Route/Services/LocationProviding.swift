//
//  LocationProviding.swift
//  Lana-V2
//

@MainActor
protocol LocationProviding {
    func requestCurrentLocation() async throws -> RouteLocation
    func cancel()
}
