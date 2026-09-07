//
//  WaypointInputView.swift.swift
//  Lana-V2
//
//  Created by Imam on 01/09/26.
//

import SwiftUI

struct WaypointInputView: View {
    @Binding var startLocation: String
    @Binding var finishLocation: String

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Waypoints")
                .font(.headline)

            locationField(
                icon: "circle.fill",
                placeholder: "Start from...",
                text: $startLocation
            )

            locationField(
                icon: "mappin.circle.fill",
                placeholder: "Finish at...",
                text: $finishLocation
            )
        }
    }

    private func locationField(
        icon: String,
        placeholder: String,
        text: Binding<String>
    ) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 12))

            TextField(
                placeholder,
                text: text
            )
        }
        .padding(.horizontal, 16)
        .frame(height: 50)
        .background(.white)
        .clipShape(
            RoundedRectangle(cornerRadius: 14)
        )
    }
    }

#Preview {
    @Previewable @State var startLocation = ""
    @Previewable @State var finishLocation = ""

    WaypointInputView(
        startLocation: $startLocation,
        finishLocation: $finishLocation
    )
    .padding()
    .background(
        Color(.systemGroupedBackground)
    )
}
