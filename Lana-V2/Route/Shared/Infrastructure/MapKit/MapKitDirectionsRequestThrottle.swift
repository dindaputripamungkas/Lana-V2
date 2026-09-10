//
//  MapKitDirectionsRequestThrottle.swift
//  Lana-V2
//

import Foundation

actor MapKitDirectionsRequestThrottle {
    static let shared = MapKitDirectionsRequestThrottle()

    private let requestLimit = 80
    private let windowDuration: TimeInterval = 60
    private var requestDates: [Date] = []

    func acquire() async throws {
        while true {
            try Task.checkCancellation()
            let now = Date()
            requestDates.removeAll {
                now.timeIntervalSince($0) >= windowDuration
            }

            if requestDates.count < requestLimit {
                requestDates.append(now)
                return
            }

            guard let oldest = requestDates.first else { continue }
            let wait = max(
                0.2,
                oldest.addingTimeInterval(windowDuration)
                    .timeIntervalSince(now) + 0.1
            )
            try await Task.sleep(for: .seconds(wait))
        }
    }
}
