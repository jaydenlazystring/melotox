import Foundation

final class AudioRepositoryImpl: AudioRepository, @unchecked Sendable {

    private let audioPlayer: AudioPlayerService

    init(audioPlayer: AudioPlayerService) {
        self.audioPlayer = audioPlayer
    }

    func getAvailableTracks() -> [AudioTrack] {
        // Auto-scan bundle for mp3 files and sort by name (01, 02, 03...)
        guard let urls = Bundle.main.urls(forResourcesWithExtension: "mp3", subdirectory: nil) else {
            return []
        }

        return urls
            .sorted { $0.lastPathComponent < $1.lastPathComponent }
            .enumerated()
            .map { index, url in
                let fileName = url.lastPathComponent
                let name = url.deletingPathExtension().lastPathComponent
                let paddedIndex = String(format: "%02d", index + 1)

                return AudioTrack(
                    id: UUID(uuidString: "00000000-0000-0000-0000-\(String(repeating: "0", count: 12 - paddedIndex.count))\(paddedIndex)")
                        ?? UUID(),
                    title: "Melotox \(name)",
                    duration: 60,
                    fileName: fileName,
                    category: "ambient"
                )
            }
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
