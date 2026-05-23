import Foundation
import SpriteKit

@MainActor
final class MelodyGateViewModel: ObservableObject, MelodyGateSceneDelegate {

    // MARK: - Published State

    @Published var progress: Double = 0.0
    @Published var isPlaying = false
    @Published var isWaitingForStart = true
    @Published var isFailed = false
    @Published var isCompleted = false
    @Published var currentTrack: AudioTrack?
    @Published var errorMessage: String?

    // MARK: - SpriteKit Scene

    let spriteScene: MelodyGateScene

    // MARK: - Dependencies

    private let audioRepository: any AudioRepository
    private let completeMelodyGateUseCase: CompleteMelodyGateUseCase
    private let sessionRepository: any SessionRepository

    // MARK: - Timer

    private var timer: Timer?
    private let gateDuration: TimeInterval = 60.0

    // MARK: - Init

    init(
        audioRepository: any AudioRepository,
        completeMelodyGateUseCase: CompleteMelodyGateUseCase,
        sessionRepository: any SessionRepository
    ) {
        self.audioRepository = audioRepository
        self.completeMelodyGateUseCase = completeMelodyGateUseCase
        self.sessionRepository = sessionRepository

        let scene = MelodyGateScene(size: UIScreen.main.bounds.size)
        scene.scaleMode = .resizeFill
        scene.backgroundColor = .clear
        self.spriteScene = scene

        scene.gateDelegate = self
    }

    nonisolated deinit {}

    // MARK: - Actions

    func startGate() {
        let tracks = audioRepository.getAvailableTracks()
        currentTrack = tracks.randomElement()
        isWaitingForStart = true
        isPlaying = false
        // Audio and timer start when user touches (didStart callback)
    }

    func onSessionComplete() {
        timer?.invalidate()
        audioRepository.stopPlayback()
        isPlaying = false

        Task {
            // Record activity
            let record = ActivityRecord(date: Date(), type: .completed)
            try? await sessionRepository.recordActivity(record)

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

    func stopGate() {
        timer?.invalidate()
        audioRepository.stopPlayback()
        isPlaying = false
    }

    func retryGate() {
        progress = 0.0
        isFailed = false
        isCompleted = false
        isWaitingForStart = true
        errorMessage = nil
        spriteScene.resetSession()
        startGate()
    }

    // MARK: - MelodyGateSceneDelegate

    nonisolated func didStart() {
        Task { @MainActor in
            isWaitingForStart = false
            isPlaying = true

            // Start audio
            if let track = currentTrack {
                do {
                    try await audioRepository.playTrack(track)
                } catch {
                    // Continue without music
                }
            }

            startTimer()
        }
    }

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
