//
//  RouteCardView.swift
//  Lana-V2
//
//  Created by Dinda Putri Pamungkas  on 08/09/26.
//

import SwiftUI
import MapKit

struct RouteCardView: View {
    let route: Route
    
    // Mode & Accessory Flags
    var showFavoriteButton: Bool = false
    var showBadge: Bool = true
    var showMapPreview: Bool = true
    
    // Callbacks
    var onFavoriteToggle: (() -> Void)? = nil
    var onSelect: (() -> Void)? = nil

    var body: some View {
        Group {
            if let onSelect {
                Button(action: onSelect) { cardContent }
                    .buttonStyle(.plain)
            } else {
                cardContent
            }
        }
    }

    private var cardContent: some View {
        VStack(alignment: .leading, spacing: 12) {
            // 1. Dummy Map Preview Header
            if showMapPreview {
                dummyMapHeader
            }

            // 2. Title + Accessory (Badge or Favorite Button)
            HStack(alignment: .top, spacing: 8) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(route.title)
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundStyle(.primary)

                    statsSubtitle
                }

                Spacer()

                if showFavoriteButton {
                    Button {
                        onFavoriteToggle?()
                    } label: {
                        Image(systemName: route.isFavorite ? "star.fill" : "star")
                            .foregroundStyle(route.isFavorite ? .yellow : .secondary)
                            .font(.title3)
                    }
                    .buttonStyle(.plain)
                } else if showBadge, let badgeTitle = route.badgeTitle {
                    Text(badgeTitle)
                        .font(.caption2)
                        .fontWeight(.semibold)
                        .foregroundStyle(.white)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(.black)
                        .clipShape(Capsule())
                }
            }
        }
        .padding(16)
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: Color.black.opacity(0.06), radius: 6, x: 0, y: 2)
    }

    // Stats line (handles optional intersections cleanly)
    private var statsSubtitle: some View {
        var items: [String] = [
            String(format: "%.1f km", route.distanceKm),
            "\(route.durationMinutes) mins"
        ]
        if route.intersections > 0 {
            items.append("\(route.intersections) Intersections")
        }

        return Text(items.joined(separator: " | "))
            .font(.subheadline)
            .fontWeight(.medium)
            .foregroundStyle(.primary)
    }

    // Dummy Map View
    private var dummyMapHeader: some View {
        // Dummy region (e.g. Cupertino or user default)
        let dummyPosition = MapCameraPosition.region(
            MKCoordinateRegion(
                center: CLLocationCoordinate2D(latitude: -6.2088, longitude: 106.8456), // Jakarta / Dummy center
                span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
            )
        )

        return Map(initialPosition: dummyPosition) {
            // Optional: UserAnnotation or dummy Marker
            Marker("Start", coordinate: CLLocationCoordinate2D(latitude: -6.2088, longitude: 106.8456))
        }
        .frame(height: 120)
        .clipShape(RoundedRectangle(cornerRadius: 10))
        .allowsHitTesting(false) // Best practice: disable gestures inside scrollable list card
    }
}


#Preview {
    RouteCardView(
        route: Route(
        title: "Loop Route 1",
        distanceKm: 15.2,
        durationMinutes: 41,
        isFavorite: true
    ),
    onFavoriteToggle: {
        print("Toggled favorite!")
    })
}
