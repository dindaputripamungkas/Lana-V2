//
//  LiveLocationProviding.swift
//  Lana-V2
//

@MainActor
protocol LiveLocationProviding {
    func events() -> AsyncStream<NavigationLocationEvent>
    func start()
    func stop()
}
