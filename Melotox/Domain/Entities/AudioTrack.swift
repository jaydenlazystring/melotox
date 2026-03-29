import Foundation

struct AudioTrack: Identifiable, Codable, Sendable {
    let id: UUID
    let title: String
    var duration: TimeInterval = 60
    let fileName: String
    let category: String
}
