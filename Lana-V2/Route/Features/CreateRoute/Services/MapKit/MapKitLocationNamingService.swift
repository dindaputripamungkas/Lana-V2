//
//  MapKitLocationNamingService.swift
//  Lana-V2
//

import CoreLocation
import MapKit

@MainActor
final class MapKitLocationNamingService: LocationNaming {
    private var activeRequest: MKReverseGeocodingRequest?

    func name(for coordinate: RouteCoordinate) async -> String? {
        guard coordinate.isValid else { return nil }

        activeRequest?.cancel()
        let location = CLLocation(
            latitude: coordinate.latitude,
            longitude: coordinate.longitude
        )
        guard let request = MKReverseGeocodingRequest(location: location) else {
            return nil
        }

        activeRequest = request
        defer {
            if activeRequest === request {
                activeRequest = nil
            }
        }

        do {
            guard let item = try await request.mapItems.first else {
                return nil
            }
            return clean(item.name)
                ?? clean(item.address?.shortAddress)
                ?? clean(item.addressRepresentations?.cityName)
        } catch {
            return nil
        }
    }

    func cancel() {
        activeRequest?.cancel()
        activeRequest = nil
    }

    private func clean(_ value: String?) -> String? {
        guard let value = value?.trimmingCharacters(
            in: .whitespacesAndNewlines
        ), !value.isEmpty else { return nil }
        return value
    }
}
