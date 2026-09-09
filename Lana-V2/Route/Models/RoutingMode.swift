//
//  RoutingMode.swift
//  Lana-V2
//

enum RoutingProfile: Hashable {
    case cycling
    case automobile
}

enum RoutingModeUsed: String, Codable, Hashable {
    case cycling
    case automobileFallback

    var title: String {
        switch self {
        case .cycling:
            return "Cycling"
        case .automobileFallback:
            return "Road fallback"
        }
    }
}
