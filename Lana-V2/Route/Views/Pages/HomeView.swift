//
//  HomeView.swift
//  Lana-V2
//
//  Created by Dinda Putri Pamungkas  on 31/08/26.
//

import SwiftUI
import MapKit

struct HomeView: View {
    @State private var cameraPosition: MapCameraPosition = .userLocation(fallback: .automatic)
    @State private var locationManager = LocationManager()
    @State private var hasZoomed = false
    @State private var viewModel = CreateRouteViewModel(
        service: PreviewRouteGenerationService()
    )

    
    var body: some View {
        NavigationStack {
            ZStack {
                Map(position: $cameraPosition){
                    UserAnnotation()
                }
                
                VStack(alignment: .leading) {
                    Spacer()
                    @Bindable var viewModel = viewModel

                    RouteTypeSelector(
                        selectedRouteType: $viewModel.selectedRouteType
                    )

                    RouteInputField(
                        text: $viewModel.distanceText
                    )

                    if viewModel.selectedRouteType == .pointToPoint {
                        WaypointInputView(
                            startLocation: $viewModel.startLocation,
                            finishLocation: $viewModel.finishLocation
                        )
                    }

                    PrimaryRouteButton(
                        title: "Create Route",
                        isEnabled: true,
                        action: {
                            viewModel.generateOptions()
                        }
                    )

                    
                }
                .padding()
                .navigationTitle("Routes")
                .toolbarTitleDisplayMode(.inlineLarge)
                .toolbar {
                    ToolbarItem (placement: .topBarTrailing){
                        NavigationLink{
                            SavedRoutesView()
                        } label: {
                            Image(systemName: "bookmark")
                        }
                    }
                }
            }
            .onAppear {
                hasZoomed = false
                locationManager.requestPermission()
                zoomToUser()
            }
            .onChange(of: locationManager.userLocation) { _, _ in
                if !hasZoomed {
                    zoomToUser()
                }
            }
        }
    }
    
    private func zoomToUser() {
        guard let location = locationManager.userLocation else { return }
        
        withAnimation(.easeInOut(duration: 1.2)) {
            cameraPosition = .camera(
                MapCamera(
                    centerCoordinate: location.coordinate,
                    distance: 1000
                )
            )
        }
        hasZoomed = true
    }
}

#Preview {
    HomeView()
}
