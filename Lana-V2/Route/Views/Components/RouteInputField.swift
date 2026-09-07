import SwiftUI

struct RouteInputField: View {
    @Binding var text: String

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Target Distance")
                .font(.headline)

            HStack {
                TextField(
                    "20",
                    text: $text
                )
                .keyboardType(.decimalPad)

                Spacer()

                Text("km")
                    .fontWeight(.semibold)
            }
            .padding(.horizontal, 16)
            .frame(height: 48)
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
