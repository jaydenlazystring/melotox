import Foundation

protocol AudioRepository: Sendable {
    func getAvailableTracks() -> [AudioTrack]
    func playTrack(_ track: AudioTrack) async throws
    func stopPlayback()
    func currentPlaybackTime() -> TimeInterval
}
