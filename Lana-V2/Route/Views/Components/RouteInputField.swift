import SwiftUI

struct RouteInputField: View {
    @Binding var text: String
    var showsTitle = true

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            if showsTitle {
                Text("Target Distance")
                    .font(.headline)
            }

            HStack {
                TextField(
                    "20",
                    text: $text
                )
                .keyboardType(.decimalPad)
                .foregroundStyle(RouteTheme.primaryText)
                .tint(RouteTheme.accent)

                Spacer()

                Text("km")
                    .fontWeight(.semibold)
                    .foregroundStyle(RouteTheme.secondaryText)
            }
            .padding(.horizontal, 16)
            .frame(height: 48)
            .background(RouteTheme.surface)
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
    }
}

#Preview {
    @Previewable @State var text = "98"

    RouteInputField(
        text: $text
    )
    .padding()
    .background(RouteTheme.background)
    .preferredColorScheme(.dark)
}
