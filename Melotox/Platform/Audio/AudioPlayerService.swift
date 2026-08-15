import AVFoundation
import Foundation

// MARK: - AudioPlayerService

/// Plays audio files from the app bundle using AVAudioPlayer.
final class AudioPlayerService: @unchecked Sendable {

    // MARK: - Errors

    enum AudioPlayerError: Error, Sendable {
        case fileNotFound(name: String)
        case playerInitFailed(underlying: String)
    }

    // MARK: - Private State

    private var player: AVAudioPlayer?

    // MARK: - Public Properties

    /// The current playback position in seconds.
    var currentTime: TimeInterval {
        player?.currentTime ?? 0
    }

    /// Whether the player is currently playing audio.
    var isPlaying: Bool {
        player?.isPlaying ?? false
    }

    /// A normalized (0...1) representation of the current output loudness,
    /// derived from the player's average power meter. Returns 0 when idle.
    var level: Float {
        guard let player, player.isPlaying else { return 0 }
        player.updateMeters()
        let db = player.averagePower(forChannel: 0) // roughly -160...0 dBFS
        let floorDb: Float = -50
        guard db > floorDb else { return 0 }
        return min(max((db - floorDb) / -floorDb, 0), 1)
    }

    // MARK: - Init

    init() {}

    // MARK: - Public Methods

    /// Loads and plays the audio file with the given name from the main bundle.
    ///
    /// - Parameter fileName: The file name including extension (e.g. "track.mp3").
    func play(fileName: String) throws {
        let components = (fileName as NSString)
        let name = components.deletingPathExtension
        let ext = components.pathExtension

        guard let url = Bundle.main.url(forResource: name, withExtension: ext) else {
            throw AudioPlayerError.fileNotFound(name: fileName)
        }

        // Configure the session so playback is audible and metering is accurate.
        let session = AVAudioSession.sharedInstance()
        try? session.setCategory(.playback, mode: .default)
        try? session.setActive(true)

        do {
            let audioPlayer = try AVAudioPlayer(contentsOf: url)
            audioPlayer.isMeteringEnabled = true
            audioPlayer.prepareToPlay()
            audioPlayer.play()
            player = audioPlayer
        } catch {
            throw AudioPlayerError.playerInitFailed(underlying: error.localizedDescription)
        }
    }

    /// Stops playback and releases the player.
    func stop() {
        player?.stop()
        player = nil
    }
}
