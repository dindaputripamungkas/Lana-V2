//
//  LocationProviding.swift
//  Lana-V2
//

@MainActor
protocol LocationProviding {
    func requestCurrentLocation(
        completion: @escaping (Result<RouteLocation, Error>) -> Void
    )

    func cancel()
}
