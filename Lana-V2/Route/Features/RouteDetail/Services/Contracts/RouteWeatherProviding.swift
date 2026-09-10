//
//  RouteWeatherProviding.swift
//  Lana-V2
//

@MainActor
protocol RouteWeatherProviding {
    func currentWeather(
        at coordinate: RouteCoordinate
    ) async throws -> RouteWeatherSnapshot
}
