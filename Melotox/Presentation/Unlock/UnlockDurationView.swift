import SwiftUI

struct UnlockDurationView: View {
    @ObservedObject var viewModel: UnlockViewModel

    @State private var sliderValue: Double = 15

    var body: some View {
        ZStack {
            Color(hex: "0D0D0D")
                .ignoresSafeArea()

            VStack(spacing: 40) {
                Spacer()

                // MARK: - Header
                VStack(spacing: 12) {
                    Image(systemName: "lock.open.fill")
                        .font(.system(size: 48))
                        .foregroundStyle(Color(hex: "C4B5FD"))

                    Text("Choose Unlock Time")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundStyle(.white)

                    Text("How long do you need?")
                        .font(.subheadline)
                        .foregroundStyle(Color.white.opacity(0.5))
                }

                // MARK: - Circular Display
                ZStack {
                    Circle()
                        .stroke(Color(hex: "1A1A2E"), lineWidth: 8)
                        .frame(width: 180, height: 180)

                    Circle()
                        .trim(from: 0, to: sliderValue / 60.0)
                        .stroke(
                            LinearGradient(
                                colors: [Color(hex: "7C3AED"), Color(hex: "A78BFA")],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            style: StrokeStyle(lineWidth: 8, lineCap: .round)
                        )
                        .frame(width: 180, height: 180)
                        .rotationEffect(.degrees(-90))

                    VStack(spacing: 4) {
                        Text("\(Int(sliderValue))")
                            .font(.system(size: 56, weight: .bold, design: .rounded))
                            .foregroundStyle(.white)

                        Text("minutes")
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundStyle(Color.white.opacity(0.5))
                    }
                }

                // MARK: - Slider
                if viewModel.isLoading {
                    ProgressView()
                        .tint(Color(hex: "A78BFA"))
                } else {
                    VStack(spacing: 12) {
                        Slider(value: $sliderValue, in: 1...60, step: 1)
                            .tint(Color(hex: "7C3AED"))
                            .padding(.horizontal, 32)

                        HStack {
                            Text("1 min")
                                .font(.caption2)
                                .foregroundStyle(Color.white.opacity(0.35))
                            Spacer()
                            Text("60 min")
                                .font(.caption2)
                                .foregroundStyle(Color.white.opacity(0.35))
                        }
                        .padding(.horizontal, 36)
                    }
                }

                // MARK: - Error
                if let errorMessage = viewModel.errorMessage {
                    Text(errorMessage)
                        .font(.footnote)
                        .foregroundStyle(.red.opacity(0.9))
                }

                // MARK: - Confirm Button
                Button {
                    viewModel.selectDuration(Int(sliderValue))
                } label: {
                    Text("Confirm")
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(
                            LinearGradient(
                                colors: [Color(hex: "7C3AED"), Color(hex: "5B21B6")],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                }
                .padding(.horizontal, 32)
                .disabled(viewModel.isLoading)
                .opacity(viewModel.isLoading ? 0.5 : 1.0)

                Spacer()
            }
        }
    }
}

#Preview {
    UnlockDurationView(
        viewModel: UnlockViewModel(
            appToken: "com.instagram",
            grantUnlockTimeUseCase: GrantUnlockTimeUseCase(
                unlockRepository: PreviewUnlockRepo(),
                restrictionRepository: PreviewRestrictionRepo()
            )
        )
    )
}

// MARK: - Preview Helpers

private struct PreviewUnlockRepo: UnlockRepository {
    func grantUnlock(_ grant: UnlockGrant) async throws {}
    func getActiveGrant(for appToken: String) async throws -> UnlockGrant? { nil }
    func expireGrant(id: UUID) async throws {}
}

private struct PreviewRestrictionRepo: RestrictionRepository {
    func saveProfile(_ profile: AppRestrictionProfile) async throws {}
    func loadProfile() async throws -> AppRestrictionProfile? { nil }
    func applyRestrictions(for tokens: [String]) async throws {}
    func removeRestrictions() async throws {}
}
