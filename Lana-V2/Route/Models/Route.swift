//
//  Route.swift
//  Lana-V2
//
//  Created by Dinda Putri Pamungkas  on 07/09/26.
//

import Foundation

struct Route: Identifiable, Hashable {
    var id: UUID = UUID()
    var title: String
    var distanceKm: Double
    var durationMinutes: Int
    var intersections: Int = 0
    var badgeTitle: String? = nil
    var routeKindTitle: String = "Loop Route"
    var warningMessage: String = ""
    var currentWeather: String = "26°C"
    var windSpeed: String = "13 km/h"
    var overview: String = ""
    var isFavorite: Bool = false
    var startLocation: RouteLocation? = nil
    var finishLocation: RouteLocation? = nil
    var transportMode: RouteTransportMode? = nil
    var coordinates: [RouteCoordinate] = []
    var instructions: [String] = []
    var isPreview: Bool = false
}
