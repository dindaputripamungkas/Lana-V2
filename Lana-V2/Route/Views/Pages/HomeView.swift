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
    
    var body: some View {
        NavigationStack {
            ZStack {
                Map(position: $cameraPosition){
                    UserAnnotation()
                }
                
                
                VStack(alignment: .leading) {
//                    VStack(alignment: .leading) {
//                        Text("Design a new route")
//                            .font(.headline)
//                        Text("Ready for a new challenge? Set a new distance and craft another perfect ride")
//                            .font(.subheadline)
//                        NavigationLink {
//                            CreateRouteView()
//                        } label: {
//                            Text("Create a new route")
//                                .fontWeight(.semibold)
//                                .frame(maxWidth: .infinity)
//                                .padding(.vertical, 12)
//                                .background(Color(red: 0.59, green: 0.29, blue: 0.28))
//                                .foregroundStyle(.white)
//                                .clipShape(RoundedRectangle(cornerRadius: 10))
//                        }
//                        .padding(.top, 6)
//                    }
//                    .padding()
//                    .background(Color(.systemGray6))
//                    .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                .padding()
                .navigationTitle("Routes")
                .toolbarTitleDisplayMode(.inlineLarge)
            }
            .onAppear {
                hasZoomed = false
                locationManager.requestPermission()
                zoomToUser()
            }
            .onChange(of: locationManager.userLocation) { _, _ in
                // Zooms in when GPS first acquires coordinates
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
                    distance: 1000 // 1000m altitude = street/neighborhood level zoom
                )
            )
        }
        hasZoomed = true
    }
}

#Preview {
    HomeView()
}
