import Foundation
import SpriteKit

@MainActor
final class MelodyGateViewModel: ObservableObject, MelodyGateSceneDelegate {

    // MARK: - Published State

    @Published var progress: Double = 0.0
    @Published var isPlaying = false
    @Published var isFailed = false
    @Published var isCompleted = false
    @Published var currentTrack: AudioTrack?
    @Published var errorMessage: String?

    // MARK: - SpriteKit Scene

    let spriteScene: MelodyGateScene

    // MARK: - Dependencies

    private let audioRepository: any AudioRepository
    private let completeMelodyGateUseCase: CompleteMelodyGateUseCase

    // MARK: - Timer

    private var timer: Timer?
    private let gateDuration: TimeInterval = 60.0

    // MARK: - Init

    init(
        audioRepository: any AudioRepository,
        completeMelodyGateUseCase: CompleteMelodyGateUseCase
    ) {
        self.audioRepository = audioRepository
        self.completeMelodyGateUseCase = completeMelodyGateUseCase

        let scene = MelodyGateScene(size: UIScreen.main.bounds.size)
        scene.scaleMode = .resizeFill
        scene.backgroundColor = .clear
        self.spriteScene = scene

        // Wire up delegate after self is available.
        scene.gateDelegate = self
    }

    nonisolated deinit {
        // Timer cleanup handled by MainActor-isolated methods
    }

    // MARK: - Actions

    func startGate() {
        let tracks = audioRepository.getAvailableTracks()
        currentTrack = tracks.randomElement()

        // Try to play audio, but proceed even if files are missing
        if let track = currentTrack {
            Task {
                do {
                    try await audioRepository.playTrack(track)
                } catch {
                    // Audio file not found — continue without music
                }
            }
        }

        isPlaying = true
        startTimer()
    }

    func onTapResult(success: Bool) {
        if !success {
            onSessionFailed()
        }
    }

    func onSessionComplete() {
        timer?.invalidate()
        audioRepository.stopPlayback()
        isPlaying = false

        Task {
            do {
                _ = try await completeMelodyGateUseCase.execute()
                isCompleted = true
            } catch {
                errorMessage = "Failed to complete session."
            }
        }
    }

    func onSessionFailed() {
        timer?.invalidate()
        audioRepository.stopPlayback()
        isPlaying = false
        isFailed = true
    }

    func retryGate() {
        progress = 0.0
        isFailed = false
        isCompleted = false
        errorMessage = nil
        spriteScene.resetSession()
        startGate()
    }

    // MARK: - MelodyGateSceneDelegate

    nonisolated func didComplete() {
        Task { @MainActor in
            onSessionComplete()
        }
    }

    nonisolated func didFail() {
        Task { @MainActor in
            onSessionFailed()
        }
    }

    // MARK: - Private

    private func startTimer() {
        let startTime = Date()

        timer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
            Task { @MainActor in
                guard let self else { return }
                let elapsed = Date().timeIntervalSince(startTime)
                self.progress = min(elapsed / self.gateDuration, 1.0)

                if self.progress >= 1.0 {
                    self.timer?.invalidate()
                }
            }
        }
    }
}
