//
//  LocationService.swift
//  Lana-V2
//
//  Created by Imam on 08/09/26.
//

import CoreLocation
import Foundation

enum LocationRequestError: LocalizedError, Equatable {
    case denied
    case restricted
    case unavailable
    case timedOut
    case busy
    case missingDescription

    var errorDescription: String? {
        switch self {
        case .denied:
            return "Location access is disabled. Choose a place manually or open Settings."
        case .restricted:
            return "Location access is restricted. Choose a place manually."
        case .unavailable:
            return "A recent location is unavailable. Try again or choose a place."
        case .timedOut:
            return "Getting your location timed out. Try again or choose a place."
        case .busy:
            return "A location request is already running."
        case .missingDescription:
            return "NSLocationWhenInUseUsageDescription is missing from the app target."
        }
    }
}

@MainActor
final class LocationService: NSObject, LocationProviding, CLLocationManagerDelegate {
    private let manager = CLLocationManager()
    private var continuation: CheckedContinuation<RouteLocation, Error>?
    private var timeoutTask: Task<Void, Never>?
    private var isRequestingLocation = false

    override init() {
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyBest
    }

    func requestCurrentLocation() async throws -> RouteLocation {
        guard continuation == nil else {
            throw LocationRequestError.busy
        }
        guard let description = Bundle.main.object(
            forInfoDictionaryKey: "NSLocationWhenInUseUsageDescription"
        ) as? String, !description.isEmpty else {
            throw LocationRequestError.missingDescription
        }

        return try await withTaskCancellationHandler {
            try await withCheckedThrowingContinuation { continuation in
                self.continuation = continuation
                proceedWithAuthorization()
            }
        } onCancel: {
            Task { @MainActor [weak self] in
                self?.cancel()
            }
        }
    }

    func cancel() {
        finish(.failure(CancellationError()))
    }

    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        proceedWithAuthorization()
    }

    func locationManager(
        _ manager: CLLocationManager,
        didUpdateLocations locations: [CLLocation]
    ) {
        guard continuation != nil else { return }

        let recentLocation = locations.filter {
            $0.horizontalAccuracy >= 0
                && abs($0.timestamp.timeIntervalSinceNow) <= 30
                && CLLocationCoordinate2DIsValid($0.coordinate)
        }.max { $0.timestamp < $1.timestamp }

        guard let location = recentLocation else {
            finish(.failure(LocationRequestError.unavailable))
            return
        }

        finish(.success(RouteLocation(
            name: "Current Location",
            coordinate: RouteCoordinate(
                latitude: location.coordinate.latitude,
                longitude: location.coordinate.longitude
            )
        )))
    }

    func locationManager(
        _ manager: CLLocationManager,
        didFailWithError error: Error
    ) {
        if (error as? CLError)?.code == .denied {
            finish(.failure(LocationRequestError.denied))
        } else {
            finish(.failure(error))
        }
    }

    private func proceedWithAuthorization() {
        guard continuation != nil else { return }

        switch manager.authorizationStatus {
        case .notDetermined:
            manager.requestWhenInUseAuthorization()
        case .authorizedAlways, .authorizedWhenInUse:
            guard !isRequestingLocation else { return }
            isRequestingLocation = true
            timeoutTask?.cancel()
            timeoutTask = Task { [weak self] in
                do {
                    try await Task.sleep(for: .seconds(20))
                } catch {
                    return
                }
                self?.finish(.failure(LocationRequestError.timedOut))
            }
            manager.requestLocation()
        case .denied:
            finish(.failure(LocationRequestError.denied))
        case .restricted:
            finish(.failure(LocationRequestError.restricted))
        @unknown default:
            finish(.failure(LocationRequestError.unavailable))
        }
    }

    private func finish(_ result: Result<RouteLocation, Error>) {
        guard let continuation else { return }

        self.continuation = nil
        isRequestingLocation = false
        timeoutTask?.cancel()
        timeoutTask = nil

        switch result {
        case .success(let location):
            continuation.resume(returning: location)
        case .failure(let error):
            continuation.resume(throwing: error)
        }
    }
}
