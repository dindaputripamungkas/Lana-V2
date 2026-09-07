//
//  GeneratedRouteOption.swift
//  Lana-V2
//
//  Created by Imam on 31/08/26.
//

import Foundation

struct GeneratedRouteOption: Identifiable, Hashable {
    let id = UUID()
    let title: String
    let distanceKm: Double
    let estimatedDurationMinutes: Int
    let estimatedTimeText: String
    let intersections: Int
    let badgeTitle: String?
    let routeKindTitle: String
    let warningMessage: String
    let currentWeather: String
    let windSpeed: String
    let overview: String
}


