//
//  RouteGenerationCache.swift
//  Lana-V2
//

@MainActor
protocol RouteGenerationCaching {
    func routes(for request: RouteGenerationRequest) -> [Route]?
    func insert(_ routes: [Route], for request: RouteGenerationRequest)
}

@MainActor
final class MemoryRouteGenerationCache: RouteGenerationCaching {
    private let capacity: Int
    private var storage: [RouteGenerationRequest: [Route]] = [:]
    private var accessOrder: [RouteGenerationRequest] = []

    init(capacity: Int = 32) {
        self.capacity = max(1, capacity)
    }

    func routes(for request: RouteGenerationRequest) -> [Route]? {
        guard let routes = storage[request] else { return nil }
        touch(request)
        return routes
    }

    func insert(_ routes: [Route], for request: RouteGenerationRequest) {
        storage[request] = routes
        touch(request)

        while accessOrder.count > capacity {
            storage[accessOrder.removeFirst()] = nil
        }
    }

    private func touch(_ request: RouteGenerationRequest) {
        accessOrder.removeAll { $0 == request }
        accessOrder.append(request)
    }
}
