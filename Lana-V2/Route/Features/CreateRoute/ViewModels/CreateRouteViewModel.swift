//
//  CreateRouteViewModel.swift
//  Lana-V2
//

import Foundation
import Observation

@MainActor
@Observable
final class CreateRouteViewModel {
    var selectedRouteType: RouteType = .loop {
        didSet {
            if selectedRouteType == .loop {
                selectedFinish = nil
            }
            errorMessage = nil
            scheduleDistanceValidation()
        }
    }
    var distanceText = "" {
        didSet {
            errorMessage = nil
            scheduleDistanceValidation()
        }
    }
    var activePointPicker: RoutePointPickerKind?
    var isShowingRouteOptions = false

    private(set) var selectedStart: RouteLocation?
    private(set) var selectedFinish: RouteLocation?
    private(set) var generatedOptions: [Route] = []
    private(set) var errorMessage: String?
    private(set) var isGenerating = false
    private(set) var isLocating = false
    private(set) var isValidatingDistance = false
    private(set) var distanceValidationMessage: String?
    private(set) var canOpenSettings = false

    private let routeService: any RouteGenerating
    private let placeSearchService: any PlaceSearching
    private let locationService: any LocationProviding
    private let locationNamingService: any LocationNaming

    @ObservationIgnored private var routeTask: Task<Void, Never>?
    @ObservationIgnored private var locationTask: Task<Void, Never>?
    @ObservationIgnored private var distanceValidationTask: Task<Void, Never>?
    @ObservationIgnored private var distanceValidationRequestID = UUID()

    init(
        routeService: any RouteGenerating,
        placeSearchService: any PlaceSearching,
        locationService: any LocationProviding,
        locationNamingService: any LocationNaming
    ) {
        self.routeService = routeService
        self.placeSearchService = placeSearchService
        self.locationService = locationService
        self.locationNamingService = locationNamingService
    }

    var canGenerateRoute: Bool {
        guard targetDistanceKm != nil,
              selectedStart != nil,
              !isGenerating,
              !isLocating,
              !isValidatingDistance,
              distanceValidationMessage == nil else { return false }

        return selectedRouteType == .loop || selectedFinish != nil
    }

    var targetDistanceKm: Double? {
        guard let distance = Double(
            distanceText.replacingOccurrences(of: ",", with: ".")
        ), distance >= 1, distance <= 200 else {
            return nil
        }
        return distance
    }

    var pointInstructionMessage: String {
        switch selectedRouteType {
        case .loop:
            return "The same point is used for the start and finish."
        case .pointToPoint:
            return "Choose both points so Lana can check the real road distance."
        }
    }

    func chooseStartPoint() {
        activePointPicker = .start
    }

    func chooseFinishPoint() {
        guard selectedRouteType == .pointToPoint else { return }
        activePointPicker = .finish
    }

    func setLocation(
        _ location: RouteLocation,
        for kind: RoutePointPickerKind
    ) {
        switch kind {
        case .start:
            selectedStart = location
        case .finish:
            selectedFinish = location
        }

        errorMessage = nil
        canOpenSettings = false
        generatedOptions = []
        isShowingRouteOptions = false
        scheduleDistanceValidation()
    }

    func location(for kind: RoutePointPickerKind) -> RouteLocation? {
        switch kind {
        case .start:
            return selectedStart
        case .finish:
            return selectedFinish
        }
    }

    func makePointPickerViewModel(
        for kind: RoutePointPickerKind
    ) -> RoutePointPickerViewModel {
        RoutePointPickerViewModel(
            initialLocation: location(for: kind),
            placeSearchService: placeSearchService,
            locationService: locationService,
            locationNamingService: locationNamingService
        )
    }

    func swapLocations() {
        guard selectedRouteType == .pointToPoint else { return }
        swap(&selectedStart, &selectedFinish)
        errorMessage = nil
        scheduleDistanceValidation()
    }

    func useCurrentLocation() {
        guard !isLocating else { return }

        locationTask?.cancel()
        isLocating = true
        errorMessage = nil
        canOpenSettings = false

        locationTask = Task { [weak self] in
            guard let self else { return }
            defer {
                self.isLocating = false
                self.locationTask = nil
            }

            do {
                let location = try await self.locationService
                    .requestCurrentLocation()
                try Task.checkCancellation()
                let nearbyLocation = try? await self.placeSearchService
                    .nearbyLocation(
                        at: location.coordinate,
                        maximumDistanceMeters: 25
                    )
                let resolvedName: String?
                if nearbyLocation == nil {
                    resolvedName = await self.locationNamingService.name(
                        for: location.coordinate
                    )
                } else {
                    resolvedName = nil
                }
                try Task.checkCancellation()
                self.selectedStart = nearbyLocation ?? RouteLocation(
                    name: resolvedName ?? location.name,
                    coordinate: location.coordinate
                )
                self.scheduleDistanceValidation()
            } catch {
                guard !Task.isCancelled,
                      !(error is CancellationError) else { return }
                self.errorMessage = error.localizedDescription
                if let locationError = error as? LocationRequestError {
                    self.canOpenSettings = locationError == .denied
                }
            }
        }
    }

    func generateOptions() {
        guard !isGenerating else { return }

        errorMessage = nil
        canOpenSettings = false
        generatedOptions = []
        isShowingRouteOptions = false
        cancelDistanceValidation()

        guard let distanceKm = targetDistanceKm else {
            errorMessage = "Enter a target distance from 1 to 200 km."
            return
        }
        guard let selectedStart else {
            errorMessage = "Choose a start point on the map."
            return
        }
        guard selectedRouteType == .loop || selectedFinish != nil else {
            errorMessage = "Choose a finish point on the map."
            return
        }

        let request = RouteGenerationRequest(
            routeType: selectedRouteType,
            targetDistanceMeters: distanceKm * 1_000,
            start: selectedStart,
            finish: selectedRouteType == .pointToPoint
                ? selectedFinish
                : nil
        )

        isGenerating = true
        routeTask?.cancel()
        routeTask = Task { [weak self] in
            guard let self else { return }
            defer {
                self.isGenerating = false
                self.routeTask = nil
            }

            do {
                if self.selectedRouteType == .pointToPoint,
                   let finish = self.selectedFinish {
                    let minimumDistance = try await self.routeService
                        .minimumDistance(
                            from: selectedStart,
                            to: finish
                        )
                    guard distanceKm * 1_000 + 100 >= minimumDistance else {
                        throw RouteGenerationError.targetDistanceTooShort(
                            minimumMeters: minimumDistance
                        )
                    }
                }

                self.generatedOptions = try await self.routeService
                    .generateBestRoutes(for: request)
                try Task.checkCancellation()
                self.isShowingRouteOptions = true
            } catch {
                guard !Task.isCancelled,
                      !(error is CancellationError) else { return }
                self.errorMessage = error.localizedDescription
            }
        }
    }

    func cancelRequests() {
        routeTask?.cancel()
        locationTask?.cancel()
        distanceValidationTask?.cancel()
        routeService.cancel()
        placeSearchService.cancel()
        locationService.cancel()
        locationNamingService.cancel()
    }

    private func scheduleDistanceValidation() {
        cancelDistanceValidation()

        guard selectedRouteType == .pointToPoint,
              let targetDistanceKm,
              let selectedStart,
              let selectedFinish else { return }

        let requestID = UUID()
        distanceValidationRequestID = requestID
        isValidatingDistance = true

        distanceValidationTask = Task { [weak self] in
            guard let self else { return }
            defer {
                if self.distanceValidationRequestID == requestID {
                    self.isValidatingDistance = false
                    self.distanceValidationTask = nil
                }
            }

            do {
                try await Task.sleep(for: .milliseconds(450))
                let minimumDistance = try await self.routeService
                    .minimumDistance(
                        from: selectedStart,
                        to: selectedFinish
                    )
                try Task.checkCancellation()
                guard self.distanceValidationRequestID == requestID else {
                    return
                }

                if targetDistanceKm * 1_000 + 100 < minimumDistance {
                    self.distanceValidationMessage = String(
                        format: "These places need at least %.1f km by road.",
                        minimumDistance / 1_000
                    )
                } else {
                    self.distanceValidationMessage = nil
                }
            } catch {
                guard !Task.isCancelled,
                      !(error is CancellationError),
                      self.distanceValidationRequestID == requestID else {
                    return
                }
                self.distanceValidationMessage = nil
            }
        }
    }

    private func cancelDistanceValidation() {
        distanceValidationRequestID = UUID()
        distanceValidationTask?.cancel()
        distanceValidationTask = nil
        distanceValidationMessage = nil
        isValidatingDistance = false
    }
}
