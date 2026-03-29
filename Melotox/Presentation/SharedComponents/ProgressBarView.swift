import SwiftUI

struct ProgressBarView: View {
    let progress: Double
    var color: Color = Color(hex: "7C3AED")

    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.white.opacity(0.08))
                    .frame(height: 8)

                RoundedRectangle(cornerRadius: 8)
                    .fill(
                        LinearGradient(
                            colors: [color, color.opacity(0.7)],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .frame(
                        width: geometry.size.width * min(max(progress, 0), 1),
                        height: 8
                    )
                    .shadow(color: color.opacity(0.5), radius: 6, x: 0, y: 0)
                    .animation(.easeInOut(duration: 0.3), value: progress)
            }
        }
        .frame(height: 8)
    }
}

#Preview {
    VStack(spacing: 24) {
        ProgressBarView(progress: 0.0)
        ProgressBarView(progress: 0.3)
        ProgressBarView(progress: 0.7, color: Color(hex: "A78BFA"))
        ProgressBarView(progress: 1.0)
    }
    .padding()
    .background(Color(hex: "0D0D0D"))
}
