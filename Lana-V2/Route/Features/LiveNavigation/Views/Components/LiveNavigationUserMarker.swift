//
//  LiveNavigationUserMarker.swift
//  Lana-V2
//

import SwiftUI

struct LiveNavigationUserMarker: View {
    let headingDegrees: Double

    @State private var isPulsing = false

    var body: some View {
        ZStack {
            Circle()
                .fill(RouteTheme.accent.opacity(0.25))
                .frame(width: 58, height: 58)
                .scaleEffect(isPulsing ? 1 : 0.65)
                .opacity(isPulsing ? 0.08 : 0.7)

            Circle()
                .fill(RouteTheme.accent)
                .frame(width: 34, height: 34)
                .overlay {
                    Image(systemName: "location.north.fill")
                        .font(.system(size: 17, weight: .bold))
                        .foregroundStyle(.black)
                        .rotationEffect(.degrees(headingDegrees))
                }
                .overlay {
                    Circle()
                        .stroke(.black.opacity(0.38), lineWidth: 2)
                }
        }
        .frame(width: 60, height: 60)
        .onAppear {
            withAnimation(
                .easeInOut(duration: 1.3)
                    .repeatForever(autoreverses: true)
            ) {
                isPulsing = true
            }
        }
        .accessibilityLabel("Current location")
    }
}
