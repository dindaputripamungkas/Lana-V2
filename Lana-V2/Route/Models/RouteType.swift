//
//  RouteType.swift
//  Lana-V2
//
//  Created by Imam on 01/09/26.
//

enum RouteType: String, Codable, Hashable {
    case loop
    case pointToPoint

    var title: String {
        switch self {
        case .loop:
            return "Loop"
        case .pointToPoint:
            return "A to B"
        }
    }
}
