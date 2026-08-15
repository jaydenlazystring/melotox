import Foundation

protocol AudioRepository: Sendable {
    func getAvailableTracks() -> [AudioTrack]
    func playTrack(_ track: AudioTrack) async throws
    func stopPlayback()
    func currentPlaybackTime() -> TimeInterval
    /// Normalized (0...1) output loudness of the currently playing track.
    func currentLevel() -> Float
}
