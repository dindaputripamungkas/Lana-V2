//
//  LocationService.swift
//  Lana-V2
//
//  Created by Imam on 08/09/26.
//

import CoreLocation
import Foundation

enum LocationRequestError: LocalizedError {
    case denied, restricted, approximate, unavailable, timedOut, busy, missingDescription

    var errorDescription: String? {
        switch self {
        case .denied:
            return "Location access is disabled. Choose a place manually or open Settings."
        case .restricted:
            return "Location access is restricted. Choose a place manually."
        case .approximate:
            return "Precise location is off. Choose a place manually or enable it in Settings."
        case .unavailable:
            return "A recent, accurate location is unavailable. Try again or choose a place."
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
    private var pending: ((Result<RouteLocation, Error>) -> Void)?
    private var timeout: Task<Void, Never>?
    private var isWaitingForFix = false

    override init() {
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyBest
    }

    func requestCurrentLocation(
        completion: @escaping (Result<RouteLocation, Error>) -> Void
    ) {
        guard pending == nil else {
            completion(.failure(LocationRequestError.busy))
            return
        }
        guard let description = Bundle.main.object(
            forInfoDictionaryKey: "NSLocationWhenInUseUsageDescription"
        ) as? String, !description.isEmpty else {
            completion(.failure(LocationRequestError.missingDescription))
            return
        }
        pending = completion
        proceedWithAuthorization()
    }

    private func proceedWithAuthorization() {
        guard pending != nil else { return }
        switch manager.authorizationStatus {
        case .notDetermined:
            manager.requestWhenInUseAuthorization()
        case .authorizedAlways, .authorizedWhenInUse:
            guard manager.accuracyAuthorization == .fullAccuracy else {
                finish(.failure(LocationRequestError.approximate))
                return
            }
            guard !isWaitingForFix else { return }
            isWaitingForFix = true
            timeout = Task { [weak self] in
                do { try await Task.sleep(for: .seconds(20)) }
                catch { return }
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

    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        proceedWithAuthorization()
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard pending != nil else { return }
        let recent = locations.filter {
            $0.horizontalAccuracy >= 0 && $0.horizontalAccuracy <= 100
                && abs($0.timestamp.timeIntervalSinceNow) <= 30
                && CLLocationCoordinate2DIsValid($0.coordinate)
        }.max { $0.timestamp < $1.timestamp }
        guard let location = recent else {
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

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        if (error as? CLError)?.code == .denied {
            finish(.failure(LocationRequestError.denied))
        } else {
            finish(.failure(error))
        }
    }

    func cancel() {
        finish(.failure(CancellationError()))
    }

    private func finish(_ result: Result<RouteLocation, Error>) {
        guard let completion = pending else { return }
        pending = nil
        isWaitingForFix = false
        timeout?.cancel()
        timeout = nil
        manager.stopUpdatingLocation()
        completion(result)
    }
}
