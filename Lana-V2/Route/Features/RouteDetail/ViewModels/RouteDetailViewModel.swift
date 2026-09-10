//
//  RouteDetailViewModel.swift
//  Lana-V2
//

import Foundation
import Observation

@MainActor
@Observable
final class RouteDetailViewModel {
    private(set) var route: Route
    var isDetailSheetPresented = true
    var isShowingLiveNavigation = false
    var isNamingRoute = false
    var routeName = ""
    private(set) var weather = RouteWeatherDisplay.loading

    @ObservationIgnored private let weatherService: any RouteWeatherProviding
    @ObservationIgnored private var weatherTask: Task<Void, Never>?
    @ObservationIgnored private var shouldStartAfterSheetDismiss = false
    @ObservationIgnored private var favoriteAfterSave = false

    init(
        route: Route,
        weatherService: any RouteWeatherProviding
    ) {
        self.route = route
        self.weatherService = weatherService
    }

    convenience init(route: Route) {
        self.init(
            route: route,
            weatherService: WeatherKitRouteWeatherService()
        )
    }

    var targetGapText: String {
        let prefix = route.distanceKm >= route.targetDistanceKm ? "+" : "-"
        return "\(prefix)\(String(format: "%.1f", route.distanceGapKm)) km"
    }

    var roadTitle: String {
        route.routingModeUsed == .cycling
            ? "Cycling route"
            : "Road fallback"
    }

    var roadMessage: String {
        switch route.routingModeUsed {
        case .cycling:
            return "MapKit found roads that support cycling directions."
        case .automobileFallback:
            return "Cycling directions were unavailable, so Lana used road geometry. Ride with extra care."
        }
    }

    func refreshWeather() async {
        weatherTask?.cancel()
        weather = .loading

        guard let coordinate = route.startLocation?.coordinate
            ?? route.coordinates.first else {
            weather = .unavailable
            return
        }

        let task = Task { [weak self] in
            guard let self else { return }

            do {
                let snapshot = try await self.weatherService
                    .currentWeather(at: coordinate)
                try Task.checkCancellation()
                self.weather = RouteWeatherDisplay(
                    temperatureText: "\(Int(snapshot.temperatureCelsius.rounded())) °C",
                    windSpeedText: "\(Int(snapshot.windSpeedKilometersPerHour.rounded())) km/h",
                    symbolName: snapshot.symbolName,
                    isLoading: false
                )
            } catch {
                guard !Task.isCancelled else { return }
                self.weather = .unavailable
            }

            self.weatherTask = nil
        }
        weatherTask = task
        await task.value
    }

    func prepareNavigation() {
        shouldStartAfterSheetDismiss = true
        isDetailSheetPresented = false
    }

    func handleDetailSheetDismiss() {
        guard shouldStartAfterSheetDismiss else { return }
        shouldStartAfterSheetDismiss = false
        isShowingLiveNavigation = true
    }

    func showDetails() {
        isDetailSheetPresented = true
    }

    func requestSave(using routeStore: any RouteSaving) {
        guard !routeStore.isSaved(route) else { return }
        favoriteAfterSave = false
        routeName = route.title
        isNamingRoute = true
    }

    func requestFavorite(using routeStore: any RouteSaving) {
        if routeStore.isSaved(route) {
            routeStore.toggleFavorite(for: route)
            return
        }

        favoriteAfterSave = true
        routeName = route.title
        isNamingRoute = true
    }

    func saveNamedRoute(using routeStore: any RouteSaving) {
        let trimmedName = routeName.trimmingCharacters(
            in: .whitespacesAndNewlines
        )
        guard !trimmedName.isEmpty else { return }

        route.title = trimmedName
        route.isFavorite = favoriteAfterSave
        routeStore.save(route)
        favoriteAfterSave = false
        isNamingRoute = false
    }

    func cancelNaming() {
        favoriteAfterSave = false
        routeName = ""
        isNamingRoute = false
    }

    func isSaved(in routeStore: any RouteSaving) -> Bool {
        routeStore.isSaved(route)
    }

    func isFavorite(in routeStore: any RouteSaving) -> Bool {
        routeStore.savedRoute(matching: route)?.isFavorite
            ?? route.isFavorite
    }

    func savedRideStats(
        in routeStore: any RouteSaving
    ) -> (elevation: Double?, speed: Double?) {
        let storedRoute = routeStore.savedRoute(matching: route)
        return (
            storedRoute?.averageElevationMeters
                ?? route.averageElevationMeters,
            storedRoute?.averageSpeedKmh
                ?? route.averageSpeedKmh
        )
    }

    func cancelRequests() {
        weatherTask?.cancel()
        weatherTask = nil
    }
}
