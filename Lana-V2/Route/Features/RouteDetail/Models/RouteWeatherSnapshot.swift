//
//  RouteWeatherSnapshot.swift
//  Lana-V2
//

struct RouteWeatherSnapshot: Equatable {
    let temperatureCelsius: Double
    let windSpeedKilometersPerHour: Double
    let symbolName: String
}

struct RouteWeatherDisplay: Equatable {
    let temperatureText: String
    let windSpeedText: String
    let symbolName: String
    let isLoading: Bool

    static let loading = RouteWeatherDisplay(
        temperatureText: "-- °C",
        windSpeedText: "-- km/h",
        symbolName: "cloud.sun.fill",
        isLoading: true
    )

    static let unavailable = RouteWeatherDisplay(
        temperatureText: "Unavailable",
        windSpeedText: "-- km/h",
        symbolName: "exclamationmark.triangle.fill",
        isLoading: false
    )
}
