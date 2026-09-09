import SwiftUI

struct RouteInputField: View {
    @Binding var text: String

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                TextField(
                    "Target Distance",
                    text: $text
                )
                .keyboardType(.decimalPad)

                Spacer()

                Text("km")
                    .font(.subheadline)
            }
            .padding()
            .frame(height: 50)
            .background(.white)
            .clipShape(
                RoundedRectangle(cornerRadius: 14)
            )
        }
    }
}

#Preview {
    @Previewable @State var text = "98"

    RouteInputField(
        text: $text
    )
    .padding()
    .background(
        Color(.systemGroupedBackground)
    )
}
