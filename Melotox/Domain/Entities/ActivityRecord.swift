import Foundation

struct ActivityRecord: Codable, Sendable {
    let date: Date
    let type: RecordType

    enum RecordType: String, Codable, Sendable {
        case completed
        case declined
    }
}
