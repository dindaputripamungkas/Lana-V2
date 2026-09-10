//
//  Route.swift
//  Lana-V2
//
//  Created by Dinda Putri Pamungkas  on 07/09/26.
//

import Foundation

struct Route: Identifiable, Hashable, Codable {
    var id: UUID = UUID()
    var title: String
    var routeType: RouteType = .loop
    var targetDistanceKm: Double = 0
    var distanceKm: Double
    var durationMinutes: Int
    var intersections: Int = 0
    var badgeTitle: String? = nil
    var warningMessage: String = ""
    var overview: String = ""
    var isFavorite: Bool = false
    var startLocation: RouteLocation? = nil
    var finishLocation: RouteLocation? = nil
    var routingModeUsed: RoutingModeUsed = .cycling
    var coordinates: [RouteCoordinate] = []
    var instructions: [String] = []
    var steps: [RouteStep] = []
    var averageElevationMeters: Double? = nil
    var averageSpeedKmh: Double? = nil
    var isPreview: Bool = false

    var distanceGapKm: Double {
        abs(distanceKm - targetDistanceKm)
    }

    var routeKindTitle: String {
        routeType == .loop ? "Loop Route" : "A to B Route"
    }

    var durationText: String {
        let hours = durationMinutes / 60
        let minutes = durationMinutes % 60
        return hours > 0 ? "\(hours) hr \(minutes) min" : "\(minutes) min"
    }

    var navigationSteps: [RouteStep] {
        guard steps.isEmpty, !instructions.isEmpty else { return steps }

        let fallbackDistance = distanceKm * 1_000
            / Double(max(instructions.count, 1))
        return instructions.map {
            RouteStep(
                instruction: $0,
                distanceMeters: fallbackDistance
            )
        }
    }

    static var preview: Route {
        let start = RouteLocation(
            name: "Apple Park",
            coordinate: RouteCoordinate(latitude: 37.3349, longitude: -122.0090)
        )
        let finish = RouteLocation(
            name: "Cupertino",
            coordinate: RouteCoordinate(latitude: 37.3230, longitude: -122.0322)
        )

        return Route(
            title: "Loop Option 1",
            targetDistanceKm: 15,
            distanceKm: 15.1,
            durationMinutes: 42,
            intersections: 10,
            badgeTitle: "Closest to Target",
            overview: "A route close to your target distance with a manageable number of turns.",
            startLocation: start,
            finishLocation: finish,
            coordinates: [start.coordinate, finish.coordinate],
            instructions: ["Head north", "Turn right", "Return to the start"],
            steps: [
                RouteStep(instruction: "Head north", distanceMeters: 5_000),
                RouteStep(instruction: "Turn right", distanceMeters: 5_000),
                RouteStep(
                    instruction: "Return to the start",
                    distanceMeters: 5_100
                )
            ],
            isPreview: true
        )
    }
}

extension Route {
    private enum CodingKeys: String, CodingKey {
        case id
        case title
        case routeType
        case targetDistanceKm
        case distanceKm
        case durationMinutes
        case intersections
        case badgeTitle
        case warningMessage
        case overview
        case isFavorite
        case startLocation
        case finishLocation
        case routingModeUsed
        case coordinates
        case instructions
        case steps
        case averageElevationMeters
        case averageSpeedKmh
        case isPreview
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let distanceKm = try container.decodeIfPresent(
            Double.self,
            forKey: .distanceKm
        ) ?? 0

        id = try container.decodeIfPresent(UUID.self, forKey: .id) ?? UUID()
        title = try container.decodeIfPresent(String.self, forKey: .title)
            ?? "Saved Route"
        routeType = try container.decodeIfPresent(
            RouteType.self,
            forKey: .routeType
        ) ?? .loop
        targetDistanceKm = try container.decodeIfPresent(
            Double.self,
            forKey: .targetDistanceKm
        ) ?? distanceKm
        self.distanceKm = distanceKm
        durationMinutes = try container.decodeIfPresent(
            Int.self,
            forKey: .durationMinutes
        ) ?? 0
        intersections = try container.decodeIfPresent(
            Int.self,
            forKey: .intersections
        ) ?? 0
        badgeTitle = try container.decodeIfPresent(
            String.self,
            forKey: .badgeTitle
        )
        warningMessage = try container.decodeIfPresent(
            String.self,
            forKey: .warningMessage
        ) ?? ""
        overview = try container.decodeIfPresent(
            String.self,
            forKey: .overview
        ) ?? ""
        isFavorite = try container.decodeIfPresent(
            Bool.self,
            forKey: .isFavorite
        ) ?? false
        startLocation = try container.decodeIfPresent(
            RouteLocation.self,
            forKey: .startLocation
        )
        finishLocation = try container.decodeIfPresent(
            RouteLocation.self,
            forKey: .finishLocation
        )
        routingModeUsed = try container.decodeIfPresent(
            RoutingModeUsed.self,
            forKey: .routingModeUsed
        ) ?? .cycling
        coordinates = try container.decodeIfPresent(
            [RouteCoordinate].self,
            forKey: .coordinates
        ) ?? []
        instructions = try container.decodeIfPresent(
            [String].self,
            forKey: .instructions
        ) ?? []
        steps = try container.decodeIfPresent(
            [RouteStep].self,
            forKey: .steps
        ) ?? []
        averageElevationMeters = try container.decodeIfPresent(
            Double.self,
            forKey: .averageElevationMeters
        )
        averageSpeedKmh = try container.decodeIfPresent(
            Double.self,
            forKey: .averageSpeedKmh
        )
        isPreview = try container.decodeIfPresent(
            Bool.self,
            forKey: .isPreview
        ) ?? false
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(title, forKey: .title)
        try container.encode(routeType, forKey: .routeType)
        try container.encode(targetDistanceKm, forKey: .targetDistanceKm)
        try container.encode(distanceKm, forKey: .distanceKm)
        try container.encode(durationMinutes, forKey: .durationMinutes)
        try container.encode(intersections, forKey: .intersections)
        try container.encodeIfPresent(badgeTitle, forKey: .badgeTitle)
        try container.encode(warningMessage, forKey: .warningMessage)
        try container.encode(overview, forKey: .overview)
        try container.encode(isFavorite, forKey: .isFavorite)
        try container.encodeIfPresent(startLocation, forKey: .startLocation)
        try container.encodeIfPresent(finishLocation, forKey: .finishLocation)
        try container.encode(routingModeUsed, forKey: .routingModeUsed)
        try container.encode(coordinates, forKey: .coordinates)
        try container.encode(instructions, forKey: .instructions)
        try container.encode(steps, forKey: .steps)
        try container.encodeIfPresent(
            averageElevationMeters,
            forKey: .averageElevationMeters
        )
        try container.encodeIfPresent(
            averageSpeedKmh,
            forKey: .averageSpeedKmh
        )
        try container.encode(isPreview, forKey: .isPreview)
    }
}
