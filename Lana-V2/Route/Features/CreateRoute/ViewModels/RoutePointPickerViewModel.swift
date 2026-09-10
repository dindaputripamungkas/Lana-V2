//
//  RoutePointPickerViewModel.swift
//  Lana-V2
//

import Foundation
import Observation

@MainActor
@Observable
final class RoutePointPickerViewModel {
    var query = ""
    private(set) var suggestions: [PlaceSearchSuggestion] = []
    private(set) var selectedLocation: RouteLocation?
    private(set) var visibleRegion: PlaceSearchRegion?
    private(set) var isSearching = false
    private(set) var isResolvingLocation = false
    private(set) var isLocating = false
    private(set) var errorMessage: String?
    private(set) var canOpenSettings = false
    private(set) var hasCompletedSearch = false

    private let placeSearchService: any PlaceSearching
    private let locationService: any LocationProviding
    private let locationNamingService: any LocationNaming

    @ObservationIgnored private var searchTask: Task<Void, Never>?
    @ObservationIgnored private var resolveTask: Task<Void, Never>?
    @ObservationIgnored private var locationTask: Task<Void, Never>?
    @ObservationIgnored private var searchRequestID = UUID()
    @ObservationIgnored private var resolveRequestID = UUID()
    @ObservationIgnored private var locationRequestID = UUID()

    init(
        initialLocation: RouteLocation?,
        placeSearchService: any PlaceSearching,
        locationService: any LocationProviding,
        locationNamingService: any LocationNaming
    ) {
        selectedLocation = initialLocation
        query = initialLocation?.name ?? ""
        self.placeSearchService = placeSearchService
        self.locationService = locationService
        self.locationNamingService = locationNamingService
    }

    var canConfirm: Bool {
        selectedLocation != nil && !isResolvingLocation && !isLocating
    }

    func updateQuery(_ newValue: String) {
        cancelLocationRequest()
        cancelResolution()

        let text = newValue.trimmingCharacters(in: .whitespacesAndNewlines)
        if selectedLocation?.name != text {
            selectedLocation = nil
        }

        query = newValue
        errorMessage = nil
        canOpenSettings = false
        hasCompletedSearch = false
        scheduleSearch()
    }

    func updateVisibleRegion(_ region: PlaceSearchRegion) {
        guard visibleRegion != region else { return }
        visibleRegion = region

        if query.trimmingCharacters(in: .whitespacesAndNewlines).count >= 2,
           !suggestions.isEmpty {
            scheduleSearch()
        }
    }

    func selectSuggestion(_ suggestion: PlaceSearchSuggestion) async {
        cancelSearch()
        cancelResolution()
        isResolvingLocation = true
        errorMessage = nil

        let requestID = UUID()
        resolveRequestID = requestID

        do {
            let location = try await placeSearchService.resolve(
                suggestion,
                in: visibleRegion
            )
            try Task.checkCancellation()
            guard resolveRequestID == requestID else { return }

            selectedLocation = location
            query = location.name
            suggestions = []
        } catch {
            guard !(error is CancellationError),
                  resolveRequestID == requestID else { return }
            errorMessage = error.localizedDescription
        }

        if resolveRequestID == requestID {
            isResolvingLocation = false
        }
    }

    func selectCoordinate(_ coordinate: RouteCoordinate) {
        resolveCoordinate(coordinate, fallbackName: nil)
    }

    func movePin(to coordinate: RouteCoordinate) {
        guard coordinate.isValid else { return }
        cancelResolution()
        selectedLocation = RouteLocation(
            name: "Pinned Location",
            coordinate: coordinate
        )
        query = ""
        errorMessage = nil
    }

    func finishMovingPin(to coordinate: RouteCoordinate) {
        resolveCoordinate(coordinate, fallbackName: nil)
    }

    func useCurrentLocation() async {
        guard !isLocating else { return }

        cancelSearch()
        cancelResolution()
        cancelLocationRequest()
        isLocating = true
        errorMessage = nil
        canOpenSettings = false
        let requestID = UUID()
        locationRequestID = requestID

        let task = Task { [weak self] in
            guard let self else { return }

            do {
                let location = try await self.locationService
                    .requestCurrentLocation()
                try Task.checkCancellation()
                guard self.locationRequestID == requestID else { return }
                self.resolveCoordinate(
                    location.coordinate,
                    fallbackName: location.name
                )
            } catch {
                guard !Task.isCancelled,
                      !(error is CancellationError),
                      self.locationRequestID == requestID else { return }
                self.errorMessage = error.localizedDescription
                if let locationError = error as? LocationRequestError {
                    self.canOpenSettings = locationError == .denied
                }
            }

            if self.locationRequestID == requestID {
                self.isLocating = false
                self.locationTask = nil
            }
        }
        locationTask = task
        await task.value
    }

    func cancelRequests() {
        cancelSearch()
        cancelResolution()
        cancelLocationRequest()
    }

    private func scheduleSearch() {
        cancelSearch()

        let text = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard text.count >= 2,
              selectedLocation?.name != text else { return }

        let requestID = UUID()
        searchRequestID = requestID
        isSearching = true

        searchTask = Task { [weak self] in
            guard let self else { return }

            do {
                try await Task.sleep(for: .milliseconds(300))
                let values = try await self.placeSearchService.suggestions(
                    for: text,
                    in: self.visibleRegion
                )
                try Task.checkCancellation()
                guard self.searchRequestID == requestID,
                      self.query.trimmingCharacters(
                        in: .whitespacesAndNewlines
                      ) == text else { return }
                self.suggestions = Array(values.prefix(10))
                self.hasCompletedSearch = true
            } catch {
                guard !Task.isCancelled,
                      !(error is CancellationError),
                      self.searchRequestID == requestID else { return }
                self.errorMessage = error.localizedDescription
            }

            if self.searchRequestID == requestID {
                self.isSearching = false
                self.searchTask = nil
            }
        }
    }

    private func resolveCoordinate(
        _ coordinate: RouteCoordinate,
        fallbackName: String?
    ) {
        guard coordinate.isValid else { return }

        cancelSearch()
        cancelResolution()
        let requestID = UUID()
        resolveRequestID = requestID
        isResolvingLocation = true
        errorMessage = nil
        canOpenSettings = false
        selectedLocation = RouteLocation(
            name: fallbackName ?? "Finding place...",
            coordinate: coordinate
        )

        resolveTask = Task { [weak self] in
            guard let self else { return }

            let nearbyTask = Task {
                try? await self.placeSearchService.nearbyLocation(
                    at: coordinate,
                    maximumDistanceMeters: 25
                )
            }
            let geocodeTask = Task {
                await self.locationNamingService.name(for: coordinate)
            }

            let nearbyLocation = await nearbyTask.value
            let geocodedName = await geocodeTask.value
            guard !Task.isCancelled,
                  self.resolveRequestID == requestID else { return }

            let resolvedLocation = nearbyLocation ?? RouteLocation(
                name: geocodedName
                    ?? fallbackName
                    ?? "Pinned Location",
                coordinate: coordinate
            )
            self.selectedLocation = resolvedLocation
            self.query = resolvedLocation.name
            self.isResolvingLocation = false
            self.resolveTask = nil
        }
    }

    private func cancelSearch() {
        searchRequestID = UUID()
        searchTask?.cancel()
        searchTask = nil
        placeSearchService.cancel()
        suggestions = []
        isSearching = false
    }

    private func cancelResolution() {
        resolveRequestID = UUID()
        resolveTask?.cancel()
        resolveTask = nil
        placeSearchService.cancel()
        locationNamingService.cancel()
        isResolvingLocation = false
    }

    private func cancelLocationRequest() {
        locationRequestID = UUID()
        locationTask?.cancel()
        locationTask = nil
        locationService.cancel()
        isLocating = false
    }
}
