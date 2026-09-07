//
//  RouteGenerating.swift
//  Lana-V2
//
//  Created by Imam on 01/09/26.
//

protocol RouteGenerating {
    func generateOptions(
        targetDistanceKm: Double,
        routeType: RouteType,
        startLocation: String?,
        finishLocation: String?
    ) -> [GeneratedRouteOption]
}
