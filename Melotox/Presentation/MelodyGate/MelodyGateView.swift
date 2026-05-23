import SpriteKit
import SwiftUI

struct MelodyGateView: View {
    @ObservedObject var viewModel: MelodyGateViewModel
    var onComplete: () -> Void
    var onQuit: () -> Void

    @State private var showQuitAlert = false

    var body: some View {
        ZStack {
            // MARK: - Background
            Color(hex: "0D0D0D")
                .ignoresSafeArea()

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
            VStack(spacing: 0) {
                // Top bar: quit button + track name
                HStack {
                    Button {
                        showQuitAlert = true
                    } label: {
                        Image(systemName: "xmark")
                            .font(.title3)
                            .fontWeight(.semibold)
                            .foregroundStyle(.white.opacity(0.7))
                            .frame(width: 40, height: 40)
                            .background(Color.white.opacity(0.1))
                            .clipShape(Circle())
                    }

                    Spacer()

                    if let track = viewModel.currentTrack {
                        Text(track.title)
                            .font(.headline)
                            .foregroundStyle(Color(hex: "A78BFA"))
                    }

                    Spacer()
                    // Spacer to balance the X button
                    Color.clear.frame(width: 40, height: 40)
                }
                .padding(.horizontal, 16)
                .padding(.top, 56)

                Spacer()

                // Bottom: instruction + progress
                VStack(spacing: 12) {
                    Text(viewModel.isWaitingForStart ? "Touch to begin" : "Follow the light")
                        .font(.title3)
                        .fontWeight(.medium)
                        .foregroundStyle(.white.opacity(viewModel.isWaitingForStart ? 1.0 : 0.7))
                        .animation(.easeInOut, value: viewModel.isWaitingForStart)

                    ProgressBarView(progress: viewModel.progress, color: Color(hex: "7C3AED"))
                        .padding(.horizontal, 40)

                    let remaining = max(0, Int(60.0 * (1.0 - viewModel.progress)))
                    Text("\(remaining)s")
                        .font(.caption)
                        .foregroundStyle(Color.white.opacity(0.4))
                        .monospacedDigit()
                }
                .padding(.bottom, 40)
            }
            .allowsHitTesting(false)

            // Make only the quit button tappable
            VStack {
                HStack {
                    Button {
                        showQuitAlert = true
                    } label: {
                        Color.clear.frame(width: 40, height: 40)
                    }
                    .padding(.leading, 16)
                    .padding(.top, 56)
                    Spacer()
                }
                Spacer()
            }

            // MARK: - Failure Overlay
            if viewModel.isFailed {
                failureOverlay
            }
        }
        .onAppear {
            viewModel.startGate()
        }
        .onChange(of: viewModel.isCompleted) { _, completed in
            if completed { onComplete() }
        }
        .alert("Give up?", isPresented: $showQuitAlert) {
            Button("Keep going", role: .cancel) {}
            Button("Quit", role: .destructive) {
                viewModel.stopGate()
                onQuit()
            }
        } message: {
            Text("Your progress will be lost.")
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
            let repo = PreviewSessionRepo()
            let vm = MelodyGateViewModel(
                audioRepository: PreviewAudioRepo(),
                completeMelodyGateUseCase: CompleteMelodyGateUseCase(
                    sessionRepository: repo
                ),
                sessionRepository: repo
            )
            vm.currentTrack = AudioTrack(id: UUID(), title: "Ocean Breeze", fileName: "ocean.mp3", category: "ambient")
            vm.progress = 0.35
            return vm
        }(),
        onComplete: {},
        onQuit: {}
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
        [AudioTrack(id: UUID(), title: "Ocean Breeze", fileName: "ocean.mp3", category: "ambient")]
    }
    func playTrack(_ track: AudioTrack) async throws {}
    func stopPlayback() {}
    func currentPlaybackTime() -> TimeInterval { 0 }
}
