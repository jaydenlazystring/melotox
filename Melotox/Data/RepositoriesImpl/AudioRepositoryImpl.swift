import Foundation

final class AudioRepositoryImpl: AudioRepository, @unchecked Sendable {

    private let audioPlayer: AudioPlayerService

    init(audioPlayer: AudioPlayerService) {
        self.audioPlayer = audioPlayer
    }

    func getAvailableTracks() -> [AudioTrack] {
        [
            AudioTrack(
                id: UUID(uuidString: "00000000-0000-0000-0000-000000000001")!,
                title: "Ambient Dawn",
                duration: 60,
                fileName: "ambient_dawn.mp3",
                category: "ambient"
            ),
            AudioTrack(
                id: UUID(uuidString: "00000000-0000-0000-0000-000000000002")!,
                title: "Calm Waves",
                duration: 60,
                fileName: "calm_waves.mp3",
                category: "nature"
            ),
            AudioTrack(
                id: UUID(uuidString: "00000000-0000-0000-0000-000000000003")!,
                title: "Quiet Forest",
                duration: 60,
                fileName: "quiet_forest.mp3",
                category: "nature"
            ),
        ]
    }

    func playTrack(_ track: AudioTrack) async throws {
        try audioPlayer.play(fileName: track.fileName)
    }

    func stopPlayback() {
        audioPlayer.stop()
    }

    func currentPlaybackTime() -> TimeInterval {
        audioPlayer.currentTime
    }
}
