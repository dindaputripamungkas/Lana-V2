//
//  UserDefaultsRouteStore.swift
//  Lana-V2
//

import Foundation

enum RouteStoreError: LocalizedError {
    case unsupportedSchema(Int)

    var errorDescription: String? {
        switch self {
        case .unsupportedSchema(let version):
            return "Saved routes use unsupported schema version \(version)."
        }
    }
}

private struct StoredRoutesEnvelope: Codable {
    let schemaVersion: Int
    let routes: [Route]
}

@MainActor
final class UserDefaultsRouteStore: RoutePersisting {
    private let currentSchemaVersion = 1
    private let defaults: UserDefaults
    private let key: String
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()

    init(
        defaults: UserDefaults = .standard,
        key: String = "saved-routes-v1"
    ) {
        self.defaults = defaults
        self.key = key
    }

    func loadRoutes() throws -> [Route] {
        guard let data = defaults.data(forKey: key) else { return [] }

        if let envelope = try? decoder.decode(
            StoredRoutesEnvelope.self,
            from: data
        ) {
            guard envelope.schemaVersion <= currentSchemaVersion else {
                throw RouteStoreError.unsupportedSchema(
                    envelope.schemaVersion
                )
            }
            return envelope.routes
        }

        let migratedRoutes = try decoder.decode([Route].self, from: data)
        try saveRoutes(migratedRoutes)
        return migratedRoutes
    }

    func saveRoutes(_ routes: [Route]) throws {
        let envelope = StoredRoutesEnvelope(
            schemaVersion: currentSchemaVersion,
            routes: routes
        )
        defaults.set(try encoder.encode(envelope), forKey: key)
    }
}
