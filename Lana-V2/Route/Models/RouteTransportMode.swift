//
//  RouteTransportMode.swift
//  Lana-V2
//
//  Created by Imam on 08/09/26.
//

import MapKit

enum RouteTransportMode: String, CaseIterable, Identifiable, Codable {
    case cycling = "Cycling"
    case walking = "Walking"

    var id: String { rawValue }

    var mapKitValue: MKDirectionsTransportType {
        switch self {
        case .cycling: return .cycling
        case .walking: return .walking
        }
    }
}
