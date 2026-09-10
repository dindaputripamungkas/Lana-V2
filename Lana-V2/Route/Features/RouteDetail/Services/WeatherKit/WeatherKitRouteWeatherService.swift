//
//  WeatherKitRouteWeatherService.swift
//  Lana-V2
//

import CoreLocation
import WeatherKit

@MainActor
final class WeatherKitRouteWeatherService: RouteWeatherProviding {
    private let service = WeatherKit.WeatherService.shared

    func currentWeather(
        at coordinate: RouteCoordinate
    ) async throws -> RouteWeatherSnapshot {
        let location = CLLocation(
            latitude: coordinate.latitude,
            longitude: coordinate.longitude
        )
        let weather = try await service.weather(for: location)
        let current = weather.currentWeather

        return RouteWeatherSnapshot(
            temperatureCelsius: current.temperature
                .converted(to: .celsius)
                .value,
            windSpeedKilometersPerHour: current.wind.speed
                .converted(to: .kilometersPerHour)
                .value,
            symbolName: current.symbolName
        )
    }
}
