//
//  RideSummaryViewModel.swift
//  Lana-V2
//

import Observation

@MainActor
@Observable
final class RideSummaryViewModel {
    let summary: RideSummary

    init(summary: RideSummary) {
        self.summary = summary
    }

    func save(using routeStore: any RouteSaving) {
        var completedRoute = summary.route
        completedRoute.averageElevationMeters = summary.averageElevationMeters
        completedRoute.averageSpeedKmh = summary.averageSpeedKmh
        routeStore.save(completedRoute)
    }

    func isSaved(in routeStore: any RouteSaving) -> Bool {
        routeStore.isSaved(summary.route)
    }
}
