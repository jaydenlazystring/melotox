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

    /// A calming phrase shown at the top of the play screen, rotated over time.
    @Published var relaxPhrase: String = ""
    /// Normalized (0...1) audio loudness, driving the on-screen equalizer.
    @Published var audioLevel: CGFloat = 0

    // MARK: - Relax Phrases

    private let relaxPhrases: [String] = [
        "Take a deep breath",
        "Relax your shoulders",
        "You are safe here",
        "Let the tension go",
        "Just be present",
        "Slow down for a moment",
        "Unclench your jaw",
        "Feel your breath",
        "Soften your gaze",
        "This moment is enough",
    ]

    // MARK: - SpriteKit Scene

    let spriteScene: MelodyGateScene

    // MARK: - Dependencies

    private let audioRepository: any AudioRepository
    private let completeMelodyGateUseCase: CompleteMelodyGateUseCase
    private let sessionRepository: any SessionRepository

    // MARK: - Timer

    private var timer: Timer?
    private var phraseTimer: Timer?
    private var levelTimer: Timer?
    private let gateDuration: TimeInterval = 60.0
    private let phraseInterval: TimeInterval = 4.5

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
        startPhraseRotation()
        // Audio and timer start when user touches (didStart callback)
    }

    func onSessionComplete() {
        timer?.invalidate()
        stopEffects()
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
        stopEffects()
        audioRepository.stopPlayback()
        isPlaying = false
        isFailed = true
    }

    func stopGate() {
        timer?.invalidate()
        stopEffects()
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
                    startLevelMetering()
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

    private func startPhraseRotation() {
        phraseTimer?.invalidate()
        relaxPhrase = relaxPhrases.randomElement() ?? ""
        phraseTimer = Timer.scheduledTimer(withTimeInterval: phraseInterval, repeats: true) { [weak self] _ in
            Task { @MainActor in
                guard let self else { return }
                var next = self.relaxPhrases.randomElement() ?? self.relaxPhrase
                // Avoid repeating the same phrase back-to-back.
                if self.relaxPhrases.count > 1 {
                    while next == self.relaxPhrase {
                        next = self.relaxPhrases.randomElement() ?? next
                    }
                }
                self.relaxPhrase = next
            }
        }
    }

    private func startLevelMetering() {
        levelTimer?.invalidate()
        levelTimer = Timer.scheduledTimer(withTimeInterval: 0.05, repeats: true) { [weak self] _ in
            Task { @MainActor in
                guard let self else { return }
                let level = CGFloat(self.audioRepository.currentLevel())
                self.audioLevel = level
                self.spriteScene.audioLevel = level
            }
        }
    }

    private func stopEffects() {
        phraseTimer?.invalidate()
        phraseTimer = nil
        levelTimer?.invalidate()
        levelTimer = nil
        audioLevel = 0
        spriteScene.audioLevel = 0
    }

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
