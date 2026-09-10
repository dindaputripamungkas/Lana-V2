//
//  PlaceSearchSuggestion.swift
//  Lana-V2
//

import Foundation

struct PlaceSearchSuggestion: Identifiable, Hashable {
    let id: String
    let title: String
    let subtitle: String
}

struct PlaceSearchRegion: Equatable {
    let center: RouteCoordinate
    let latitudeDelta: Double
    let longitudeDelta: Double
}
