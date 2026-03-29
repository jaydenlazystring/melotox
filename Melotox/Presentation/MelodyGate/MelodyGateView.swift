import SpriteKit
import SwiftUI

struct MelodyGateView: View {
    @ObservedObject var viewModel: MelodyGateViewModel
    var onComplete: () -> Void

    var body: some View {
        ZStack {
            // MARK: - Background
            Color(hex: "0D0D0D")
                .ignoresSafeArea()

            // Ambient radial backdrop
            RadialGradient(
                colors: [
                    Color(hex: "5B21B6").opacity(0.15),
                    Color(hex: "0D0D0D"),
                ],
                center: .center,
                startRadius: 40,
                endRadius: 400
            )
            .ignoresSafeArea()

            // MARK: - SpriteKit Scene
            SpriteView(scene: viewModel.spriteScene, options: [.allowsTransparency])
                .ignoresSafeArea()
                .allowsHitTesting(true)

            // MARK: - UI Overlay
            VStack(spacing: 24) {
                // Track name at top
                if let track = viewModel.currentTrack {
                    Text(track.title)
                        .font(.headline)
                        .foregroundStyle(Color(hex: "A78BFA"))
                        .padding(.top, 60)
                }

                Spacer()

                // Tap instruction
                Text("Tap when the orb hits the bar")
                    .font(.title3)
                    .fontWeight(.medium)
                    .foregroundStyle(.white)

                // Progress bar
                ProgressBarView(progress: viewModel.progress, color: Color(hex: "7C3AED"))
                    .padding(.horizontal, 40)

                // Time remaining
                let remaining = max(0, Int(60.0 * (1.0 - viewModel.progress)))
                Text("\(remaining)s remaining")
                    .font(.caption)
                    .foregroundStyle(Color.white.opacity(0.4))
                    .monospacedDigit()

                Spacer()
                    .frame(height: 40)
            }
            .allowsHitTesting(false)

            // MARK: - Failure Overlay
            if viewModel.isFailed {
                failureOverlay
            }

            // MARK: - Error
            if let errorMessage = viewModel.errorMessage {
                VStack {
                    Spacer()
                    Text(errorMessage)
                        .font(.footnote)
                        .foregroundStyle(.red.opacity(0.9))
                        .padding(.bottom, 20)
                }
            }
        }
        .onAppear {
            viewModel.startGate()
        }
        .onChange(of: viewModel.isCompleted) { _, completed in
            if completed {
                onComplete()
            }
        }
    }

    // MARK: - Failure Overlay

    private var failureOverlay: some View {
        ZStack {
            Color.black.opacity(0.8)
                .ignoresSafeArea()

            VStack(spacing: 24) {
                Image(systemName: "xmark.circle")
                    .font(.system(size: 56))
                    .foregroundStyle(Color.red.opacity(0.7))

                Text("Rhythm lost")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundStyle(.white)

                Text("Stay focused and try again")
                    .font(.subheadline)
                    .foregroundStyle(Color.white.opacity(0.5))

                MelotoxButton(title: "Try Again", action: viewModel.retryGate, style: .primary)
                    .padding(.horizontal, 60)
            }
        }
    }
}

#Preview {
    MelodyGateView(
        viewModel: {
            let vm = MelodyGateViewModel(
                audioRepository: PreviewAudioRepo(),
                completeMelodyGateUseCase: CompleteMelodyGateUseCase(
                    sessionRepository: PreviewSessionRepo()
                )
            )
            vm.currentTrack = AudioTrack(id: UUID(), title: "Ocean Breeze", fileName: "ocean.mp3", category: "ambient")
            vm.progress = 0.35
            return vm
        }(),
        onComplete: {}
    )
}

// MARK: - Preview Helpers

private struct PreviewSessionRepo: SessionRepository {
    func saveSession(_ session: InterventionSession) async throws {}
    func loadCurrentSession() async throws -> InterventionSession? { nil }
    func clearCurrentSession() async throws {}
}

private struct PreviewAudioRepo: AudioRepository {
    func getAvailableTracks() -> [AudioTrack] {
        [AudioTrack(id: UUID(), title: "Ocean Breeze", fileName: "ocean.mp3", category: "ambient")]
    }
    func playTrack(_ track: AudioTrack) async throws {}
    func stopPlayback() {}
    func currentPlaybackTime() -> TimeInterval { 0 }
}
