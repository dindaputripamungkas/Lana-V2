//
//  CreateRouteViewModel.swift
//  Lana-V2
//
//  Created by Imam on 31/08/26.
//

import Foundation
import Observation

@Observable
final class CreateRouteViewModel {
    var selectedRouteType: RouteType = .loop
    var distanceText: String = ""
    var startLocation: String = ""
    var finishLocation: String = ""
    var generatedOptions: [Route] = []
    var selectedOption: Route?
    var isShowingRouteOptions = false
    var errorMessage: String?
    
    private let service: any RouteGenerating
    
    init(service: any RouteGenerating) {
        self.service = service
    }
    
    func generateOptions() {
        errorMessage = nil
        generatedOptions = []
        isShowingRouteOptions = false
    
        guard !distanceText.isEmpty else {
            errorMessage = "Please enter a distance"
            return
        }

        guard let distance = Double(distanceText) else {
            errorMessage = "Please enter a valid distance"
            return
        }
        
        guard distance > 0 else {
            errorMessage = "Distance must be greater than 0"
            return
        }

        if selectedRouteType == .pointToPoint {
            guard !startLocation.trimmingCharacters(in: .whitespaces).isEmpty else {
                errorMessage = "Please enter a start location"
                return
            }
            guard !finishLocation.trimmingCharacters(in: .whitespaces).isEmpty else {
                errorMessage = "Please enter a finish location"
                return
            }
        }
    
        generatedOptions = service.generateOptions(
            targetDistanceKm: distance,
            routeType: selectedRouteType,
            startLocation: selectedRouteType == .pointToPoint ? startLocation : nil,
            finishLocation: selectedRouteType == .pointToPoint ? finishLocation : nil
        )
        isShowingRouteOptions = true
    }
}
