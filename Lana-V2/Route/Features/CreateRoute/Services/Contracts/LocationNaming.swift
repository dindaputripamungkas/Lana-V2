//
//  LocationNaming.swift
//  Lana-V2
//

@MainActor
protocol LocationNaming {
    func name(for coordinate: RouteCoordinate) async -> String?
    func cancel()
}
