import SwiftUI

struct OnboardingView: View {
    @State private var currentPage = 0
    var onComplete: () -> Void

    var body: some View {
        ZStack {
            Color(hex: "0D0D0D")
                .ignoresSafeArea()

            TabView(selection: $currentPage) {
                // MARK: Page 1 - Take a Breath
                VStack(spacing: 32) {
                    Spacer()

                    ZStack {
                        Circle()
                            .fill(
                                RadialGradient(
                                    colors: [
                                        Color(hex: "7C3AED").opacity(0.3),
                                        Color.clear
                                    ],
                                    center: .center,
                                    startRadius: 20,
                                    endRadius: 100
                                )
                            )
                            .frame(width: 200, height: 200)

                        Image(systemName: "lungs.fill")
                            .font(.system(size: 64))
                            .foregroundStyle(Color(hex: "C4B5FD"))
                    }

                    VStack(spacing: 12) {
                        Text("Take a Breath")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                            .foregroundStyle(.white)

                        Text("Pause before you scroll")
                            .font(.title3)
                            .foregroundStyle(Color.white.opacity(0.6))
                    }

                    Spacer()
                    Spacer()
                }
                .tag(0)

                // MARK: Page 2 - Melody Gate
                VStack(spacing: 32) {
                    Spacer()

                    ZStack {
                        Circle()
                            .fill(
                                RadialGradient(
                                    colors: [
                                        Color(hex: "5B21B6").opacity(0.3),
                                        Color.clear
                                    ],
                                    center: .center,
                                    startRadius: 20,
                                    endRadius: 100
                                )
                            )
                            .frame(width: 200, height: 200)

                        Image(systemName: "waveform.path")
                            .font(.system(size: 64))
                            .foregroundStyle(Color(hex: "A78BFA"))
                    }

                    VStack(spacing: 12) {
                        Text("Melody Gate")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                            .foregroundStyle(.white)

                        Text("Listen to 1 minute of ambient sound\nand tap along to the rhythm")
                            .font(.title3)
                            .foregroundStyle(Color.white.opacity(0.6))
                            .multilineTextAlignment(.center)
                    }

                    Spacer()
                    Spacer()
                }
                .tag(1)

                // MARK: Page 3 - You Decide
                VStack(spacing: 32) {
                    Spacer()

                    ZStack {
                        Circle()
                            .fill(
                                RadialGradient(
                                    colors: [
                                        Color(hex: "7C3AED").opacity(0.3),
                                        Color.clear
                                    ],
                                    center: .center,
                                    startRadius: 20,
                                    endRadius: 100
                                )
                            )
                            .frame(width: 200, height: 200)

                        Image(systemName: "clock.badge.checkmark")
                            .font(.system(size: 64))
                            .foregroundStyle(Color(hex: "C4B5FD"))
                    }

                    VStack(spacing: 12) {
                        Text("You Decide")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                            .foregroundStyle(.white)

                        Text("Choose how long to unlock the app.\nStay in control of your screen time.")
                            .font(.title3)
                            .foregroundStyle(Color.white.opacity(0.6))
                            .multilineTextAlignment(.center)
                    }

                    Spacer()

                    MelotoxButton(title: "Get Started", action: onComplete, style: .primary)
                        .padding(.horizontal, 40)

                    Spacer()
                }
                .tag(2)
            }
            .tabViewStyle(.page(indexDisplayMode: .always))
            .indexViewStyle(.page(backgroundDisplayMode: .always))
        }
    }
}

#Preview {
    OnboardingView(onComplete: {})
}
