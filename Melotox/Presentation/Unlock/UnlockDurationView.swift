import SwiftUI

struct UnlockDurationView: View {
    @ObservedObject var viewModel: UnlockViewModel

    private let durations = [5, 10, 15]

    var body: some View {
        ZStack {
            Color(hex: "0D0D0D")
                .ignoresSafeArea()

            VStack(spacing: 32) {
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

                // MARK: - Duration Cards
                if viewModel.isLoading {
                    ProgressView()
                        .tint(Color(hex: "A78BFA"))
                } else {
                    HStack(spacing: 16) {
                        ForEach(durations, id: \.self) { minutes in
                            DurationCard(
                                minutes: minutes,
                                isSelected: viewModel.selectedDuration == minutes
                            ) {
                                viewModel.selectDuration(minutes)
                            }
                        }
                    }
                    .padding(.horizontal, 20)
                }

                // MARK: - Error
                if let errorMessage = viewModel.errorMessage {
                    Text(errorMessage)
                        .font(.footnote)
                        .foregroundStyle(.red.opacity(0.9))
                }

                Spacer()
                Spacer()
            }
        }
    }
}

// MARK: - Duration Card

private struct DurationCard: View {
    let minutes: Int
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Text("\(minutes)")
                    .font(.system(size: 36, weight: .bold, design: .rounded))
                    .foregroundStyle(isSelected ? .white : Color(hex: "C4B5FD"))

                Text("min")
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundStyle(Color.white.opacity(0.5))
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 24)
            .background(
                isSelected
                    ? AnyShapeStyle(
                        LinearGradient(
                            colors: [Color(hex: "7C3AED"), Color(hex: "5B21B6")],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    : AnyShapeStyle(Color(hex: "1A1A2E"))
            )
            .clipShape(RoundedRectangle(cornerRadius: 20))
            .overlay(
                RoundedRectangle(cornerRadius: 20)
                    .stroke(
                        isSelected ? Color(hex: "A78BFA").opacity(0.6) : Color.clear,
                        lineWidth: 1.5
                    )
            )
            .shadow(
                color: isSelected ? Color(hex: "7C3AED").opacity(0.4) : Color.clear,
                radius: 12,
                x: 0,
                y: 4
            )
        }
        .buttonStyle(.plain)
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
