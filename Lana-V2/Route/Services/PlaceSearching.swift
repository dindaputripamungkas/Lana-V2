//
//  PlaceSearching.swift
//  Lana-V2
//
//  Created by Imam on 08/09/26.
//

@MainActor
protocol PlaceSearching {
    func search(_ query: String) async throws -> [RouteLocation]
    func cancel()
}
