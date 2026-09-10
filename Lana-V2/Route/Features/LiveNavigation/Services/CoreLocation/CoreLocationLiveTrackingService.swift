//
//  CoreLocationLiveTrackingService.swift
//  Lana-V2
//

import CoreLocation
import Foundation

@MainActor
final class CoreLocationLiveTrackingService: NSObject,
    LiveLocationProviding,
    CLLocationManagerDelegate {

    private let manager: CLLocationManager
    private var continuation: AsyncStream<NavigationLocationEvent>.Continuation?
    private var latestHeadingDegrees: Double?

    override init() {
        manager = CLLocationManager()
        super.init()

        manager.delegate = self
        manager.activityType = .fitness
        manager.desiredAccuracy = kCLLocationAccuracyBestForNavigation
        manager.distanceFilter = 3
        manager.pausesLocationUpdatesAutomatically = false
    }

    func events() -> AsyncStream<NavigationLocationEvent> {
        continuation?.finish()

        return AsyncStream { continuation in
            self.continuation = continuation
            continuation.yield(.authorizationChanged(
                authorization(from: manager.authorizationStatus)
            ))
        }
    }

    func start() {
        switch manager.authorizationStatus {
        case .notDetermined:
            manager.requestWhenInUseAuthorization()
        case .authorizedAlways, .authorizedWhenInUse:
            startFrameworkUpdates()
        case .denied:
            continuation?.yield(.authorizationChanged(.denied))
        case .restricted:
            continuation?.yield(.authorizationChanged(.restricted))
        @unknown default:
            continuation?.yield(.failure(
                "Location authorization is unavailable."
            ))
        }
    }

    func stop() {
        manager.stopUpdatingLocation()
        manager.stopUpdatingHeading()
        continuation?.finish()
        continuation = nil
        latestHeadingDegrees = nil
    }

    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        let status = authorization(from: manager.authorizationStatus)
        continuation?.yield(.authorizationChanged(status))

        if status == .authorized {
            startFrameworkUpdates()
        } else if status == .denied || status == .restricted {
            manager.stopUpdatingLocation()
            manager.stopUpdatingHeading()
        }
    }

    func locationManager(
        _ manager: CLLocationManager,
        didUpdateLocations locations: [CLLocation]
    ) {
        guard let location = locations.max(by: {
            $0.timestamp < $1.timestamp
        }), CLLocationCoordinate2DIsValid(location.coordinate) else {
            return
        }

        let course = location.course >= 0 && location.course <= 360
            ? location.course
            : nil
        let speed = location.speed >= 0 ? location.speed : 0

        continuation?.yield(.sample(NavigationLocationSample(
            coordinate: RouteCoordinate(
                latitude: location.coordinate.latitude,
                longitude: location.coordinate.longitude
            ),
            timestamp: location.timestamp,
            horizontalAccuracyMeters: location.horizontalAccuracy,
            verticalAccuracyMeters: location.verticalAccuracy,
            altitudeMeters: location.altitude,
            speedMetersPerSecond: speed,
            courseDegrees: course,
            headingDegrees: latestHeadingDegrees
        )))
    }

    func locationManager(
        _ manager: CLLocationManager,
        didUpdateHeading newHeading: CLHeading
    ) {
        guard newHeading.headingAccuracy >= 0 else { return }

        if newHeading.trueHeading >= 0 {
            latestHeadingDegrees = newHeading.trueHeading
        } else if newHeading.magneticHeading >= 0 {
            latestHeadingDegrees = newHeading.magneticHeading
        }
    }

    func locationManager(
        _ manager: CLLocationManager,
        didFailWithError error: Error
    ) {
        if (error as? CLError)?.code == .denied {
            continuation?.yield(.authorizationChanged(.denied))
        } else {
            continuation?.yield(.failure(error.localizedDescription))
        }
    }

    private func startFrameworkUpdates() {
        manager.startUpdatingLocation()
        if CLLocationManager.headingAvailable() {
            manager.startUpdatingHeading()
        }
    }

    private func authorization(
        from status: CLAuthorizationStatus
    ) -> NavigationLocationAuthorization {
        switch status {
        case .notDetermined:
            return .notDetermined
        case .authorizedAlways, .authorizedWhenInUse:
            return .authorized
        case .denied:
            return .denied
        case .restricted:
            return .restricted
        @unknown default:
            return .denied
        }
    }
}
