//
//  LiveNavigationViewModel.swift
//  Lana-V2
//

import Foundation
import Observation

@MainActor
@Observable
final class LiveNavigationViewModel {
    private enum VoicePromptThreshold: Double, CaseIterable {
        case far = 300
        case near = 100
        case now = 30
    }

    private(set) var activeRoute: Route
    private(set) var latestLocation: NavigationLocationSample?
    private(set) var authorization: NavigationLocationAuthorization = .notDetermined
    private(set) var locationErrorMessage: String?
    private(set) var isPaused = false
    private(set) var isFinished = false
    private(set) var isRerouting = false
    private(set) var isVoiceEnabled = true
    private(set) var elapsedTime: TimeInterval = 0
    private(set) var distanceRiddenMeters = 0.0
    private(set) var estimatedRouteProgressMeters = 0.0
    private(set) var currentStepIndex = 0
    private(set) var elevationGainMeters = 0.0
    private(set) var averageElevationMeters = 0.0
    private(set) var summary: RideSummary?

    private let locationService: any LiveLocationProviding
    private let progressService: any RouteProgressProjecting
    private let speaker: any NavigationSpeaking
    private let reroutingService: any NavigationRerouting
    private let destination: RouteLocation?

    @ObservationIgnored private var locationTask: Task<Void, Never>?
    @ObservationIgnored private var timerTask: Task<Void, Never>?
    @ObservationIgnored private var rerouteTask: Task<Void, Never>?
    @ObservationIgnored private var rideStartedAt: Date?
    @ObservationIgnored private var pauseStartedAt: Date?
    @ObservationIgnored private var accumulatedPauseDuration: TimeInterval = 0
    @ObservationIgnored private var lastOdometerCoordinate: RouteCoordinate?
    @ObservationIgnored private var lastAltitudeMeters: Double?
    @ObservationIgnored private var elevationSampleSumMeters = 0.0
    @ObservationIgnored private var elevationSampleCount = 0
    @ObservationIgnored private var stepEndDistances: [Double] = []
    @ObservationIgnored private var spokenPromptKeys: Set<String> = []
    @ObservationIgnored private var consecutiveOffRouteSamples = 0
    @ObservationIgnored private var lastRerouteAt = Date.distantPast
    @ObservationIgnored private var didSpeakFirstInstruction = false
    @ObservationIgnored private var didAnnounceArrival = false

    init(
        route: Route,
        locationService: any LiveLocationProviding,
        progressService: any RouteProgressProjecting,
        speaker: any NavigationSpeaking,
        reroutingService: any NavigationRerouting
    ) {
        activeRoute = route
        self.locationService = locationService
        self.progressService = progressService
        self.speaker = speaker
        self.reroutingService = reroutingService
        destination = route.routeType == .loop
            ? route.startLocation
            : route.finishLocation

        progressService.prepare(coordinates: route.coordinates)
        rebuildStepDistances()
    }

    convenience init(route: Route) {
        self.init(
            route: route,
            locationService: CoreLocationLiveTrackingService(),
            progressService: MapKitRouteProgressService(),
            speaker: AVSpeechNavigationService(),
            reroutingService: NavigationReroutingService()
        )
    }

    var routeCoordinates: [RouteCoordinate] {
        activeRoute.coordinates
    }

    var currentInstruction: String {
        let steps = activeRoute.navigationSteps
        guard !steps.isEmpty else {
            return "Follow the highlighted route"
        }
        return steps[min(currentStepIndex, steps.count - 1)].instruction
    }

    var distanceToNextStepMeters: Double {
        guard currentStepIndex < stepEndDistances.count else { return 0 }
        return max(
            0,
            stepEndDistances[currentStepIndex]
                - estimatedRouteProgressMeters
        )
    }

    var routeLengthMeters: Double {
        let measuredLength = progressService.routeLengthMeters
        return measuredLength > 0
            ? measuredLength
            : activeRoute.distanceKm * 1_000
    }

    var distanceLeftMeters: Double {
        max(0, routeLengthMeters - estimatedRouteProgressMeters)
    }

    var routeProgressFraction: Double {
        guard routeLengthMeters > 0 else { return 0 }
        return min(max(estimatedRouteProgressMeters / routeLengthMeters, 0), 1)
    }

    var currentSpeedKmh: Double {
        guard !isPaused else { return 0 }
        return max(0, latestLocation?.speedMetersPerSecond ?? 0) * 3.6
    }

    var averageSpeedKmh: Double {
        guard elapsedTime > 0 else { return 0 }
        return distanceRiddenMeters / elapsedTime * 3.6
    }

    var formattedElapsedTime: String {
        let totalSeconds = max(0, Int(elapsedTime.rounded(.down)))
        let hours = totalSeconds / 3_600
        let minutes = (totalSeconds % 3_600) / 60
        let seconds = totalSeconds % 60

        if hours > 0 {
            return String(format: "%02d:%02d:%02d", hours, minutes, seconds)
        }
        return String(format: "%02d:%02d", minutes, seconds)
    }

    func start() {
        guard locationTask == nil, !isFinished else { return }

        rideStartedAt = rideStartedAt ?? Date()
        let events = locationService.events()
        locationService.start()
        startTimer()

        locationTask = Task { [weak self] in
            for await event in events {
                guard !Task.isCancelled else { break }
                self?.handle(event)
            }
        }
    }

    func stop() {
        locationTask?.cancel()
        timerTask?.cancel()
        rerouteTask?.cancel()
        locationTask = nil
        timerTask = nil
        rerouteTask = nil
        locationService.stop()
        reroutingService.cancel()
        speaker.stop()
    }

    func togglePause() {
        guard !isFinished else { return }

        if isPaused {
            if let pauseStartedAt {
                accumulatedPauseDuration += Date().timeIntervalSince(
                    pauseStartedAt
                )
            }
            self.pauseStartedAt = nil
            isPaused = false
            speakCurrentInstruction()
        } else {
            refreshElapsedTime()
            pauseStartedAt = Date()
            isPaused = true
            speaker.stop()
        }
    }

    func toggleVoice() {
        isVoiceEnabled.toggle()
        if isVoiceEnabled {
            speakCurrentInstruction()
        } else {
            speaker.stop()
        }
    }

    func repeatInstruction() {
        speakCurrentInstruction()
    }

    func finishRide() {
        guard !isFinished else { return }

        refreshElapsedTime()
        isFinished = true
        summary = RideSummary(
            route: activeRoute,
            distanceRiddenMeters: distanceRiddenMeters,
            elapsedTime: elapsedTime,
            averageSpeedKmh: averageSpeedKmh,
            elevationGainMeters: elevationGainMeters,
            averageElevationMeters: averageElevationMeters
        )
        stop()
    }

    func dismissSummary() {
        summary = nil
    }

    private func startTimer() {
        timerTask?.cancel()
        timerTask = Task { [weak self] in
            while !Task.isCancelled {
                do {
                    try await Task.sleep(for: .seconds(1))
                } catch {
                    break
                }
                self?.refreshElapsedTime()
            }
        }
    }

    private func refreshElapsedTime() {
        guard let rideStartedAt else { return }

        let activePauseDuration: TimeInterval
        if let pauseStartedAt {
            activePauseDuration = Date().timeIntervalSince(pauseStartedAt)
        } else {
            activePauseDuration = 0
        }

        elapsedTime = max(
            0,
            Date().timeIntervalSince(rideStartedAt)
                - accumulatedPauseDuration
                - activePauseDuration
        )
    }

    private func handle(_ event: NavigationLocationEvent) {
        switch event {
        case .authorizationChanged(let authorization):
            self.authorization = authorization
            switch authorization {
            case .denied:
                locationErrorMessage = "Location access is disabled. Enable it in Settings to use live navigation."
            case .restricted:
                locationErrorMessage = "Location access is restricted on this device."
            case .authorized, .notDetermined:
                locationErrorMessage = nil
            }
        case .sample(let sample):
            handle(sample)
        case .failure(let message):
            locationErrorMessage = message
        }
    }

    private func handle(_ sample: NavigationLocationSample) {
        guard sample.coordinate.isValid,
              sample.horizontalAccuracyMeters >= 0,
              sample.horizontalAccuracyMeters <= 45,
              abs(sample.timestamp.timeIntervalSinceNow) <= 30 else {
            return
        }

        latestLocation = sample
        if authorization == .authorized {
            locationErrorMessage = nil
        }
        guard !isPaused, !isFinished else { return }

        updateOdometer(with: sample)
        updateElevation(with: sample)
        updateRouteProgress(with: sample)

        if !didSpeakFirstInstruction {
            didSpeakFirstInstruction = true
            speakCurrentInstruction()
        } else {
            speakUpcomingInstructionIfNeeded()
        }
    }

    private func updateOdometer(with sample: NavigationLocationSample) {
        defer { lastOdometerCoordinate = sample.coordinate }
        guard let previous = lastOdometerCoordinate else { return }

        let movedMeters = progressService.distance(
            from: previous,
            to: sample.coordinate
        )
        guard movedMeters > 1.5,
              movedMeters < 200,
              sample.speedMetersPerSecond > 0.5 else {
            return
        }
        distanceRiddenMeters += movedMeters
    }

    private func updateElevation(with sample: NavigationLocationSample) {
        guard sample.verticalAccuracyMeters >= 0,
              sample.verticalAccuracyMeters <= 30,
              sample.altitudeMeters.isFinite else {
            return
        }

        elevationSampleSumMeters += sample.altitudeMeters
        elevationSampleCount += 1
        averageElevationMeters = elevationSampleSumMeters
            / Double(elevationSampleCount)

        if let previousAltitude = lastAltitudeMeters {
            let gain = sample.altitudeMeters - previousAltitude
            if gain > 0.5, gain < 20 {
                elevationGainMeters += gain
            }
        }
        lastAltitudeMeters = sample.altitudeMeters
    }

    private func updateRouteProgress(with sample: NavigationLocationSample) {
        guard !isRerouting,
              let projection = progressService.project(
                sample.coordinate,
                minimumProgressMeters: estimatedRouteProgressMeters
              ) else {
            return
        }

        if projection.distanceFromRouteMeters > 100 {
            consecutiveOffRouteSamples += 1
            if consecutiveOffRouteSamples >= 3 {
                triggerReroute(from: sample.coordinate)
            }
            return
        }

        consecutiveOffRouteSamples = 0
        estimatedRouteProgressMeters = max(
            estimatedRouteProgressMeters,
            projection.distanceAlongRouteMeters
        )
        updateCurrentStep()

        if distanceLeftMeters <= 20, !didAnnounceArrival {
            didAnnounceArrival = true
            speak("You have arrived at your destination.")
        }
    }

    private func updateCurrentStep() {
        guard !stepEndDistances.isEmpty else { return }

        let newIndex = stepEndDistances.firstIndex {
            estimatedRouteProgressMeters < $0
        } ?? (stepEndDistances.count - 1)

        guard newIndex != currentStepIndex else { return }
        currentStepIndex = newIndex
        spokenPromptKeys.removeAll()
        speakCurrentInstruction()
    }

    private func speakUpcomingInstructionIfNeeded() {
        let distance = distanceToNextStepMeters
        guard let threshold = VoicePromptThreshold.allCases
            .map(\.rawValue)
            .filter({ distance <= $0 })
            .min() else {
            return
        }

        let key = "\(currentStepIndex)-\(Int(threshold))"
        guard !spokenPromptKeys.contains(key) else { return }
        spokenPromptKeys.insert(key)
        speakCurrentInstruction()
    }

    private func speakCurrentInstruction() {
        let distance = distanceToNextStepMeters
        let text: String

        if distance >= 1_000 {
            text = String(
                format: "In %.1f kilometers, %@",
                distance / 1_000,
                currentInstruction
            )
        } else if distance > 10 {
            text = "In \(Int(distance.rounded())) meters, \(currentInstruction)"
        } else {
            text = currentInstruction
        }
        speak(text)
    }

    private func speak(_ text: String) {
        guard isVoiceEnabled else { return }
        speaker.speak(text)
    }

    private func triggerReroute(from coordinate: RouteCoordinate) {
        guard !isRerouting,
              let destination,
              Date().timeIntervalSince(lastRerouteAt) > 20 else {
            return
        }

        consecutiveOffRouteSamples = 0
        lastRerouteAt = Date()
        isRerouting = true
        speak("You are off route. Finding a new route.")

        let currentLocation = RouteLocation(
            name: "Current Location",
            coordinate: coordinate
        )
        rerouteTask?.cancel()
        rerouteTask = Task { [weak self] in
            guard let self else { return }
            defer {
                self.isRerouting = false
                self.rerouteTask = nil
            }

            do {
                let route = try await self.reroutingService.reroute(
                    route: self.activeRoute,
                    from: currentLocation,
                    to: destination
                )
                try Task.checkCancellation()
                self.applyReroutedRoute(route)
            } catch {
                guard !Task.isCancelled,
                      !(error is CancellationError) else {
                    return
                }
                self.locationErrorMessage = "Rerouting failed: \(error.localizedDescription)"
            }
        }
    }

    private func applyReroutedRoute(_ route: Route) {
        activeRoute = route
        progressService.prepare(coordinates: route.coordinates)
        estimatedRouteProgressMeters = 0
        currentStepIndex = 0
        spokenPromptKeys.removeAll()
        didAnnounceArrival = false
        rebuildStepDistances()
        speakCurrentInstruction()
    }

    private func rebuildStepDistances() {
        let steps = activeRoute.navigationSteps
        guard !steps.isEmpty else {
            stepEndDistances = []
            return
        }

        let rawDistances = steps.map { max(0, $0.distanceMeters) }
        let totalStepDistance = rawDistances.reduce(0, +)
        let availableRouteLength = routeLengthMeters
        let normalizedDistances: [Double]

        if totalStepDistance > 0, availableRouteLength > 0 {
            let scale = availableRouteLength / totalStepDistance
            normalizedDistances = rawDistances.map { $0 * scale }
        } else {
            let fallback = availableRouteLength / Double(steps.count)
            normalizedDistances = Array(
                repeating: fallback,
                count: steps.count
            )
        }

        var runningDistance = 0.0
        stepEndDistances = normalizedDistances.map {
            runningDistance += $0
            return runningDistance
        }
    }
}
