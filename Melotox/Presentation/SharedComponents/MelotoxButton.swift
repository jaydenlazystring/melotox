import SwiftUI

enum MelotoxButtonStyle {
    case primary
    case secondary
}

struct MelotoxButton: View {
    let title: String
    let action: () -> Void
    var style: MelotoxButtonStyle = .primary

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.headline)
                .fontWeight(.semibold)
                .foregroundStyle(foregroundColor)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(backgroundView)
                .clipShape(RoundedRectangle(cornerRadius: 16))
                .shadow(color: glowColor.opacity(0.4), radius: 12, x: 0, y: 4)
        }
        .buttonStyle(.plain)
    }

    // MARK: - Style Helpers

    private var foregroundColor: Color {
        switch style {
        case .primary:
            .white
        case .secondary:
            Color(hex: "C4B5FD")
        }
    }

    @ViewBuilder
    private var backgroundView: some View {
        switch style {
        case .primary:
            LinearGradient(
                colors: [Color(hex: "7C3AED"), Color(hex: "5B21B6")],
                startPoint: .leading,
                endPoint: .trailing
            )
        case .secondary:
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color(hex: "7C3AED").opacity(0.6), lineWidth: 1.5)
                .background(Color(hex: "1A1A2E").clipShape(RoundedRectangle(cornerRadius: 16)))
        }
    }

    private var glowColor: Color {
        switch style {
        case .primary:
            Color(hex: "7C3AED")
        case .secondary:
            Color.clear
        }
    }
}

// MARK: - Color Hex Extension

extension Color {
    init(hex: String) {
        let scanner = Scanner(string: hex)
        var rgbValue: UInt64 = 0
        scanner.scanHexInt64(&rgbValue)

        let red = Double((rgbValue & 0xFF0000) >> 16) / 255.0
        let green = Double((rgbValue & 0x00FF00) >> 8) / 255.0
        let blue = Double(rgbValue & 0x0000FF) / 255.0

        self.init(red: red, green: green, blue: blue)
    }
}

#Preview {
    VStack(spacing: 20) {
        MelotoxButton(title: "Get Started", action: {}, style: .primary)
        MelotoxButton(title: "Maybe Later", action: {}, style: .secondary)
    }
    .padding()
    .background(Color(hex: "0D0D0D"))
}
