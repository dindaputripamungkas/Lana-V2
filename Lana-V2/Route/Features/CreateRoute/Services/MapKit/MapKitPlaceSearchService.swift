//
//  MapKitPlaceSearchService.swift
//  Lana-V2
//

import MapKit

@MainActor
final class MapKitPlaceSearchService: NSObject, PlaceSearching {
    private let completer = MKLocalSearchCompleter()
    private var completions: [String: MKLocalSearchCompletion] = [:]
    private var suggestionContinuation: CheckedContinuation<
        [PlaceSearchSuggestion], Error
    >?
    private var pendingSuggestionQuery: String?
    private var suggestionTimeoutTask: Task<Void, Never>?
    private var activeSearch: MKLocalSearch?

    override init() {
        super.init()
        completer.delegate = self
        completer.resultTypes = [.address, .pointOfInterest]
    }

    func suggestions(
        for query: String,
        in region: PlaceSearchRegion?
    ) async throws -> [PlaceSearchSuggestion] {
        let text = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { return [] }

        cancelSuggestionRequest(with: CancellationError())
        try Task.checkCancellation()

        if let region {
            completer.region = mapRegion(from: region)
        }

        return try await withTaskCancellationHandler {
            try await withCheckedThrowingContinuation { continuation in
                suggestionContinuation = continuation
                pendingSuggestionQuery = text
                completer.queryFragment = text
                suggestionTimeoutTask = Task { [weak self] in
                    do {
                        try await Task.sleep(for: .seconds(8))
                    } catch {
                        return
                    }
                    self?.cancelSuggestionRequest(
                        with: PlaceSearchError.timedOut
                    )
                }
            }
        } onCancel: {
            Task { @MainActor [weak self] in
                self?.cancelSuggestionRequest(with: CancellationError())
            }
        }
    }

    func resolve(
        _ suggestion: PlaceSearchSuggestion,
        in region: PlaceSearchRegion?
    ) async throws -> RouteLocation {
        let request: MKLocalSearch.Request

        if let completion = completions[suggestion.id] {
            request = MKLocalSearch.Request(completion: completion)
        } else {
            request = MKLocalSearch.Request()
            request.naturalLanguageQuery = [
                suggestion.title,
                suggestion.subtitle
            ]
            .filter { !$0.isEmpty }
            .joined(separator: ", ")
        }

        if let region {
            request.region = mapRegion(from: region)
        }
        request.resultTypes = [.address, .pointOfInterest]

        guard let item = try await start(request).mapItems.first,
              let location = routeLocation(
                from: item,
                fallbackName: suggestion.title
              ) else {
            throw PlaceSearchError.noResult
        }
        return location
    }

    func nearbyLocation(
        at coordinate: RouteCoordinate,
        maximumDistanceMeters: Double
    ) async throws -> RouteLocation? {
        let request = MKLocalSearch.Request()
        request.region = MKCoordinateRegion(
            center: coordinate.clCoordinate,
            span: MKCoordinateSpan(
                latitudeDelta: 0.0015,
                longitudeDelta: 0.0015
            )
        )
        request.resultTypes = .pointOfInterest
        request.pointOfInterestFilter = .includingAll

        let response = try await start(request)
        let selectedPoint = MKMapPoint(coordinate.clCoordinate)

        return response.mapItems
            .compactMap { item -> (RouteLocation, Double)? in
                guard let location = routeLocation(from: item) else {
                    return nil
                }
                let distance = selectedPoint.distance(
                    to: MKMapPoint(location.coordinate.clCoordinate)
                )
                return (location, distance)
            }
            .filter { $0.1 <= maximumDistanceMeters }
            .min { $0.1 < $1.1 }?
            .0
    }

    func cancel() {
        cancelSuggestionRequest(with: CancellationError())
        activeSearch?.cancel()
        activeSearch = nil
    }

    private func start(
        _ request: MKLocalSearch.Request
    ) async throws -> MKLocalSearch.Response {
        activeSearch?.cancel()
        let search = MKLocalSearch(request: request)
        activeSearch = search
        defer {
            if activeSearch === search { activeSearch = nil }
        }

        let response = try await search.start()
        try Task.checkCancellation()
        return response
    }

    private func routeLocation(
        from item: MKMapItem,
        fallbackName: String? = nil
    ) -> RouteLocation? {
        let coordinate = item.location.coordinate
        let routeCoordinate = RouteCoordinate(
            latitude: coordinate.latitude,
            longitude: coordinate.longitude
        )
        guard routeCoordinate.isValid else { return nil }

        let name = clean(item.name)
            ?? clean(fallbackName)
            ?? "Pinned Location"
        return RouteLocation(name: name, coordinate: routeCoordinate)
    }

    private func mapRegion(
        from region: PlaceSearchRegion
    ) -> MKCoordinateRegion {
        MKCoordinateRegion(
            center: region.center.clCoordinate,
            span: MKCoordinateSpan(
                latitudeDelta: region.latitudeDelta,
                longitudeDelta: region.longitudeDelta
            )
        )
    }

    private func clean(_ value: String?) -> String? {
        guard let value = value?.trimmingCharacters(
            in: .whitespacesAndNewlines
        ), !value.isEmpty else { return nil }
        return value
    }

    private func cancelSuggestionRequest(with error: Error) {
        suggestionTimeoutTask?.cancel()
        suggestionTimeoutTask = nil
        suggestionContinuation?.resume(throwing: error)
        suggestionContinuation = nil
        pendingSuggestionQuery = nil
        completer.queryFragment = ""
    }

    private func completeSuggestions(
        _ suggestions: [PlaceSearchSuggestion],
        for query: String
    ) {
        guard pendingSuggestionQuery == query else { return }
        suggestionTimeoutTask?.cancel()
        suggestionTimeoutTask = nil
        suggestionContinuation?.resume(returning: suggestions)
        suggestionContinuation = nil
        pendingSuggestionQuery = nil
    }
}

extension MapKitPlaceSearchService: MKLocalSearchCompleterDelegate {
    nonisolated func completerDidUpdateResults(
        _ completer: MKLocalSearchCompleter
    ) {
        let query = completer.queryFragment
        let values = completer.results.map { completion in
            let id = Self.identifier(for: completion)
            return (id, completion, PlaceSearchSuggestion(
                id: id,
                title: completion.title,
                subtitle: completion.subtitle
            ))
        }

        Task { @MainActor in
            guard self.pendingSuggestionQuery == query else { return }
            self.completions = Dictionary(
                uniqueKeysWithValues: values.map { ($0.0, $0.1) }
            )
            self.completeSuggestions(values.map(\.2), for: query)
        }
    }

    nonisolated func completer(
        _ completer: MKLocalSearchCompleter,
        didFailWithError error: Error
    ) {
        let query = completer.queryFragment
        Task { @MainActor in
            guard self.pendingSuggestionQuery == query else { return }
            self.cancelSuggestionRequest(with: error)
        }
    }

    nonisolated private static func identifier(
        for completion: MKLocalSearchCompletion
    ) -> String {
        "\(completion.title)|\(completion.subtitle)"
    }
}

private enum PlaceSearchError: LocalizedError {
    case noResult
    case timedOut

    var errorDescription: String? {
        switch self {
        case .noResult:
            return "That place could not be found. Try another result."
        case .timedOut:
            return "Place suggestions took too long. Please try again."
        }
    }
}
