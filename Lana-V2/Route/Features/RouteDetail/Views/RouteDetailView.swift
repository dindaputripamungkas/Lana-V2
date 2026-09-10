//
//  RouteDetailView.swift
//  Lana-V2
//

import MapKit
import SwiftUI

struct RouteDetailView: View {
    @State private var viewModel: RouteDetailViewModel
    @State private var detailDetent: PresentationDetent = .fraction(0.46)

    init(option: Route) {
        _viewModel = State(initialValue: RouteDetailViewModel(route: option))
    }

    var body: some View {
        @Bindable var viewModel = viewModel

        routeMap
            .ignoresSafeArea(edges: .bottom)
            .navigationTitle(viewModel.route.title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(RouteTheme.background, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .overlay(alignment: .bottom) {
                if !viewModel.isDetailSheetPresented {
                    Button {
                        viewModel.showDetails()
                    } label: {
                        Label("Route Details", systemImage: "info.circle.fill")
                            .font(.subheadline.weight(.semibold))
                            .padding(.horizontal, 16)
                            .frame(height: 46)
                    }
                    .buttonStyle(.borderedProminent)
                    .buttonBorderShape(.capsule)
                    .tint(RouteTheme.background.opacity(0.9))
                    .foregroundStyle(RouteTheme.primaryText)
                    .padding(.bottom, 18)
                }
            }
            .sheet(
                isPresented: $viewModel.isDetailSheetPresented,
                onDismiss: viewModel.handleDetailSheetDismiss
            ) {
                RouteDetailsSheet(viewModel: viewModel)
                    .presentationDetents(
                        [.fraction(0.46), .large],
                        selection: $detailDetent
                    )
                    .presentationDragIndicator(.visible)
                    .presentationCornerRadius(28)
                    .presentationBackground(RouteTheme.background)
                    .presentationBackgroundInteraction(
                        .enabled(upThrough: .fraction(0.46))
                    )
            }
            .fullScreenCover(
                isPresented: $viewModel.isShowingLiveNavigation
            ) {
                LiveNavigationView(route: viewModel.route)
            }
            .task(id: viewModel.route.id) {
                await viewModel.refreshWeather()
            }
            .onDisappear {
                viewModel.cancelRequests()
            }
    }

    private var routeMap: some View {
        Map(initialPosition: mapPosition) {
            if viewModel.route.coordinates.count >= 2 {
                MapPolyline(
                    coordinates: viewModel.route.coordinates.map(\.clCoordinate)
                )
                .stroke(
                    RouteTheme.accent,
                    style: StrokeStyle(
                        lineWidth: 7,
                        lineCap: .round,
                        lineJoin: .round
                    )
                )
            }

            if let start = viewModel.route.startLocation {
                Marker(
                    viewModel.route.routeType == .loop
                        ? "Start / Finish"
                        : "Start",
                    coordinate: start.coordinate.clCoordinate
                )
                .tint(RouteTheme.accent)
            }

            if viewModel.route.routeType == .pointToPoint,
               let finish = viewModel.route.finishLocation {
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
            pointsOfInterest: .all,
            showsTraffic: false
        ))
        .mapControls {
            MapCompass()
            MapScaleView()
        }
        .environment(\.colorScheme, .dark)
        .accessibilityLabel("Generated route map")
    }

    private var mapPosition: MapCameraPosition {
        let coordinates = viewModel.route.coordinates.map(\.clCoordinate)

        guard coordinates.count >= 2 else {
            if let coordinate = coordinates.first
                ?? viewModel.route.startLocation?.coordinate.clCoordinate {
                return .camera(MapCamera(
                    centerCoordinate: coordinate,
                    distance: 2_000
                ))
            }
            return .automatic
        }

        let polyline = MKPolyline(
            coordinates: coordinates,
            count: coordinates.count
        )
        let rect = polyline.boundingMapRect
        return .rect(rect.insetBy(
            dx: -max(rect.size.width * 0.22, 1),
            dy: -max(rect.size.height * 0.22, 1)
        ))
    }
}

#Preview {
    NavigationStack {
        RouteDetailView(option: .preview)
    }
    .environment(SavedRoutesViewModel.preview)
    .preferredColorScheme(.dark)
}
