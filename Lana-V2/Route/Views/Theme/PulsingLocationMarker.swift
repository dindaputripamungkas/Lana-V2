//
//  PulsingLocationMarker.swift
//  Lana-V2
//

import SwiftUI

struct PulsingLocationMarker: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var isExpanded = false

    var body: some View {
        ZStack {
            Circle()
                .fill(RouteTheme.accent.opacity(0.25))
                .frame(width: 58, height: 58)
                .scaleEffect(isExpanded ? 1.15 : 0.70)
                .opacity(isExpanded ? 0.15 : 0.55)

            Circle()
                .fill(RouteTheme.accent.opacity(0.30))
                .frame(width: 38, height: 38)

            Circle()
                .fill(RouteTheme.accent)
                .frame(width: 16, height: 16)
                .overlay {
                    Circle()
                        .stroke(Color.black.opacity(0.35), lineWidth: 1)
                }
        }
        .frame(width: 72, height: 72)
        .shadow(color: RouteTheme.accent.opacity(0.18), radius: 10)
        .accessibilityLabel("Start location")
        .onAppear {
            guard !reduceMotion else { return }
            withAnimation(
                .easeInOut(duration: 1.25)
                .repeatForever(autoreverses: true)
            ) {
                isExpanded = true
            }
        }
    }
}

#Preview {
    ZStack {
        RouteTheme.background
        PulsingLocationMarker()
    }
    .frame(width: 180, height: 180)
}
