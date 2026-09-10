//
//  HomeView.swift
//  Lana-V2
//
//  Created by Dinda Putri Pamungkas on 31/08/26.
//

import MapKit
import SwiftUI

struct HomeView: View {
    @State private var cameraPosition: MapCameraPosition = .userLocation(
        fallback: .automatic
    )
    @State private var hasZoomed = false
    @State private var isComposerPresented = false
    @State private var composerDetent: PresentationDetent = .large
    @State private var viewModel = CreateRouteViewModel(
        routeService: RouteGenerationService(),
        placeSearchService: MapKitPlaceSearchService(),
        locationService: LocationService(),
        locationNamingService: MapKitLocationNamingService()
    )

    var body: some View {
        @Bindable var viewModel = viewModel

        NavigationStack {
            ZStack {
                RouteTheme.background
                    .ignoresSafeArea()

                routeMap(viewModel: viewModel)
                bottomShade

                VStack(spacing: 0) {
                    headerView
                    Spacer()
                    planRouteButton
                }
            }
            .toolbar(.hidden, for: .navigationBar)
            .sheet(isPresented: $isComposerPresented) {
                RouteComposerSheet(viewModel: viewModel)
                    .presentationDetents(
                        [.medium, .large],
                        selection: $composerDetent
                    )
                    .presentationDragIndicator(.visible)
                    .presentationCornerRadius(30)
                    .presentationBackground(RouteTheme.background)
                    .interactiveDismissDisabled(viewModel.isGenerating)
            }
            .navigationDestination(
                isPresented: $viewModel.isShowingRouteOptions
            ) {
                RouteOptionsView(
                    options: viewModel.generatedOptions
                )
            }
            .task {
                if viewModel.selectedStart == nil {
                    viewModel.useCurrentLocation()
                }
            }
            .onChange(of: viewModel.selectedStart) { _, location in
                guard let location else { return }
                zoom(to: location.coordinate)
            }
            .onChange(of: viewModel.isShowingRouteOptions) { _, isShowing in
                if isShowing {
                    isComposerPresented = false
                }
            }
        }
        .preferredColorScheme(.dark)
    }

    private func routeMap(
        viewModel: CreateRouteViewModel
    ) -> some View {
        Map(position: $cameraPosition) {
            if let start = viewModel.selectedStart {
                Annotation(
                    "",
                    coordinate: start.coordinate.clCoordinate
                ) {
                    PulsingLocationMarker()
                }
            }

            if viewModel.selectedRouteType == .pointToPoint,
               let finish = viewModel.selectedFinish {
                Marker(
                    "Finish",
                    coordinate: finish.coordinate.clCoordinate
                )
                .tint(RouteTheme.danger)
            }
        }
        .mapStyle(.standard(
            elevation: .flat,
            emphasis: .muted,
            pointsOfInterest: .excludingAll,
            showsTraffic: false
        ))
        .environment(\.colorScheme, .dark)
        .ignoresSafeArea()
    }

    private var bottomShade: some View {
        VStack(spacing: 0) {
            Spacer()
            LinearGradient(
                colors: [
                    .clear,
                    RouteTheme.background.opacity(0.72),
                    RouteTheme.background
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .frame(height: 260)
        }
        .ignoresSafeArea()
        .allowsHitTesting(false)
    }

    private var headerView: some View {
        HStack {
            Label("Cycle", systemImage: "bicycle")
                .font(.title2.weight(.bold))
                .foregroundStyle(RouteTheme.primaryText)

            Spacer()

            NavigationLink {
                SavedRoutesView()
            } label: {
                Image(systemName: "bookmark")
                    .font(.headline)
                    .foregroundStyle(RouteTheme.primaryText)
                    .frame(width: 44, height: 44)
                    .background(RouteTheme.surface)
                    .clipShape(Circle())
                    .overlay {
                        Circle()
                            .strokeBorder(RouteTheme.border)
                    }
            }
            .accessibilityLabel("Saved routes")
        }
        .padding(.horizontal, 20)
        .padding(.top, 8)
    }

    private var planRouteButton: some View {
        Button {
            isComposerPresented = true
        } label: {
            Label("Plan a Route", systemImage: "bicycle")
                .font(.headline)
                .frame(maxWidth: .infinity)
                .frame(minHeight: 32)
        }
        .buttonStyle(.borderedProminent)
        .buttonBorderShape(.capsule)
        .controlSize(.large)
        .tint(.white)
        .foregroundStyle(.black)
        .shadow(color: .black.opacity(0.24), radius: 18, y: 8)
        .padding(.horizontal, 20)
        .padding(.bottom, 14)
    }

    private func zoom(to coordinate: RouteCoordinate) {
        guard !hasZoomed else { return }

        withAnimation(.easeInOut(duration: 0.8)) {
            let visibleCenter = CLLocationCoordinate2D(
                latitude: max(
                    min(coordinate.latitude - 0.0012, 90),
                    -90
                ),
                longitude: coordinate.longitude
            )
            cameraPosition = .camera(
                MapCamera(
                    centerCoordinate: visibleCenter,
                    distance: 2_500
                )
            )
        }
        hasZoomed = true
    }
}

#Preview {
    HomeView()
        .environment(SavedRoutesViewModel.preview)
}
