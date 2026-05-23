import SwiftUI

struct InterventionQuestionView: View {
    @ObservedObject var viewModel: InterventionViewModel

    var body: some View {
        ZStack {
            // MARK: - Ambient Background
            LinearGradient(
                colors: [
                    Color(hex: "0D0D0D"),
                    Color(hex: "1A1A2E"),
                    Color(hex: "0D0D0D"),
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            // Subtle radial glow
            RadialGradient(
                colors: [
                    Color(hex: "7C3AED").opacity(0.08),
                    Color.clear,
                ],
                center: .center,
                startRadius: 50,
                endRadius: 300
            )
            .ignoresSafeArea()

            VStack(spacing: 40) {
                Spacer()

                // MARK: - Icon
                Image(systemName: "hand.raised.fill")
                    .font(.system(size: 56))
                    .foregroundStyle(Color(hex: "C4B5FD"))

                // MARK: - Question
                VStack(spacing: 12) {
                    Text("Do you really need\nthis app right now?")
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundStyle(.white)
                        .multilineTextAlignment(.center)

                    Text("Take a moment to consider")
                        .font(.subheadline)
                        .foregroundStyle(Color.white.opacity(0.4))
                }

                Spacer()

                // MARK: - Buttons
                if viewModel.isLoading {
                    ProgressView()
                        .tint(Color(hex: "A78BFA"))
                        .padding(.bottom, 40)
                } else {
                    VStack(spacing: 14) {
                        MelotoxButton(
                            title: "Yes, I need it",
                            action: { viewModel.submitAnswer(.yes) },
                            style: .primary
                        )

                        MelotoxButton(
                            title: "No, I'll pass",
                            action: { viewModel.submitAnswer(.no) },
                            style: .secondary
                        )
                    }
                    .padding(.horizontal, 32)
                    .padding(.bottom, 40)
                }

                // MARK: - Error
                if let errorMessage = viewModel.errorMessage {
                    Text(errorMessage)
                        .font(.footnote)
                        .foregroundStyle(.red.opacity(0.9))
                        .padding(.bottom, 16)
                }
            }
        }
    }
}

#Preview {
    let repo = PreviewSessionRepo()
    InterventionQuestionView(
        viewModel: InterventionViewModel(
            startInterventionUseCase: StartInterventionUseCase(
                sessionRepository: repo,
                audioRepository: PreviewAudioRepo()
            ),
            sessionRepository: repo
        )
    )
}

// MARK: - Preview Helpers

private struct PreviewSessionRepo: SessionRepository {
    func saveSession(_ session: InterventionSession) async throws {}
    func loadCurrentSession() async throws -> InterventionSession? { nil }
    func clearCurrentSession() async throws {}
    func recordActivity(_ record: ActivityRecord) async throws {}
    func loadActivityHistory() async throws -> [ActivityRecord] { [] }
}

private struct PreviewAudioRepo: AudioRepository {
    func getAvailableTracks() -> [AudioTrack] {
        [AudioTrack(id: UUID(), title: "Calm", fileName: "calm.mp3", category: "ambient")]
    }
    func playTrack(_ track: AudioTrack) async throws {}
    func stopPlayback() {}
    func currentPlaybackTime() -> TimeInterval { 0 }
}
