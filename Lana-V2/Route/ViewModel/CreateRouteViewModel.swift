//
//  CreateRouteViewModel.swift
//  Lana-V2
//
//  Created by Imam on 31/08/26.
//

import Foundation
import Observation

enum RouteLocationField: Hashable {
    case start
    case finish
}

@MainActor
@Observable
final class CreateRouteViewModel {
    var selectedRouteType: RouteType = .loop
    var distanceText = ""
    var startQuery = ""
    var finishQuery = ""
    var selectedOption: Route?
    var isShowingRouteOptions = false

    private(set) var selectedStart: RouteLocation?
    private(set) var selectedFinish: RouteLocation?
    private(set) var generatedOptions: [Route] = []
    private(set) var searchResults: [RouteLocation] = []
    private(set) var activeSearchField: RouteLocationField?
    private(set) var searchMessage: String?
    private(set) var errorMessage: String?
    private(set) var isGenerating = false
    private(set) var isSearching = false
    private(set) var isLocating = false
    private(set) var canOpenSettings = false

    private let routeService: any RouteGenerating
    private let placeSearchService: any PlaceSearching
    private let locationService: any LocationProviding

    @ObservationIgnored private var routeTask: Task<Void, Never>?
    @ObservationIgnored private var searchTask: Task<Void, Never>?
    @ObservationIgnored private var locationTask: Task<Void, Never>?
    @ObservationIgnored private var searchRequestID = UUID()

    init(
        routeService: any RouteGenerating,
        placeSearchService: any PlaceSearching,
        locationService: any LocationProviding
    ) {
        self.routeService = routeService
        self.placeSearchService = placeSearchService
        self.locationService = locationService
    }

    var canGenerateRoute: Bool {
        guard targetDistanceKm != nil,
              selectedStart != nil,
              !isGenerating,
              !isLocating else { return false }

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

    func updateQuery(
        _ query: String,
        for field: RouteLocationField
    ) {
        switch field {
        case .start:
            startQuery = query
            if selectedStart?.name != query {
                selectedStart = nil
            }
        case .finish:
            finishQuery = query
            if selectedFinish?.name != query {
                selectedFinish = nil
            }
        }

        errorMessage = nil
        scheduleSearch(query, for: field)
    }

    func focusSearch(on field: RouteLocationField) {
        activeSearchField = field
        scheduleSearch(query(for: field), for: field)
    }

    func selectLocation(
        _ location: RouteLocation,
        for field: RouteLocationField
    ) {
        cancelSearch()
        activeSearchField = nil
        errorMessage = nil

        switch field {
        case .start:
            selectedStart = location
            startQuery = location.name
        case .finish:
            selectedFinish = location
            finishQuery = location.name
        }
    }

    func swapLocations() {
        guard selectedRouteType == .pointToPoint else { return }
        cancelSearch()
        activeSearchField = nil
        swap(&selectedStart, &selectedFinish)
        swap(&startQuery, &finishQuery)
    }

    func useCurrentLocation() {
        guard !isLocating else { return }

        cancelSearch()
        activeSearchField = nil
        isLocating = true
        errorMessage = nil
        canOpenSettings = false

        locationTask?.cancel()
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
                self.selectedStart = location
                self.startQuery = location.name
            } catch {
                guard !Task.isCancelled, !(error is CancellationError) else {
                    return
                }
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
        cancelSearch()

        guard let distanceKm = targetDistanceKm else {
            errorMessage = "Enter a target distance from 1 to 200 km."
            return
        }
        guard let selectedStart else {
            errorMessage = "Choose a start location from the search results."
            return
        }
        guard selectedRouteType == .loop || selectedFinish != nil else {
            errorMessage = "Choose a finish location from the search results."
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
                self.generatedOptions = try await self.routeService
                    .generateBestRoutes(for: request)
                try Task.checkCancellation()
                self.isShowingRouteOptions = true
            } catch {
                guard !Task.isCancelled, !(error is CancellationError) else {
                    return
                }
                self.errorMessage = error.localizedDescription
            }
        }
    }

    func cancelRequests() {
        routeTask?.cancel()
        searchTask?.cancel()
        locationTask?.cancel()
        routeService.cancel()
        placeSearchService.cancel()
        locationService.cancel()
    }

    private func scheduleSearch(
        _ query: String,
        for field: RouteLocationField
    ) {
        cancelSearch()
        activeSearchField = field

        let text = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard text.count >= 2,
              selectedLocation(for: field)?.name != query else {
            return
        }

        let requestID = UUID()
        searchRequestID = requestID
        isSearching = true

        searchTask = Task { [weak self] in
            guard let self else { return }
            defer {
                if self.searchRequestID == requestID {
                    self.isSearching = false
                    self.searchTask = nil
                }
            }

            do {
                try await Task.sleep(for: .milliseconds(350))
                let results = try await self.placeSearchService.search(text)
                try Task.checkCancellation()

                guard self.searchRequestID == requestID,
                      self.activeSearchField == field,
                      self.query(for: field)
                        .trimmingCharacters(in: .whitespacesAndNewlines) == text
                else { return }

                self.searchResults = Array(results.prefix(8))
                self.searchMessage = results.isEmpty
                    ? "No places found."
                    : nil
            } catch {
                guard !Task.isCancelled,
                      !(error is CancellationError),
                      self.searchRequestID == requestID else {
                    return
                }
                self.searchMessage = error.localizedDescription
            }
        }
    }

    private func cancelSearch() {
        searchRequestID = UUID()
        searchTask?.cancel()
        searchTask = nil
        placeSearchService.cancel()
        searchResults = []
        searchMessage = nil
        isSearching = false
    }

    private func query(for field: RouteLocationField) -> String {
        field == .start ? startQuery : finishQuery
    }

    private func selectedLocation(
        for field: RouteLocationField
    ) -> RouteLocation? {
        field == .start ? selectedStart : selectedFinish
    }
}
