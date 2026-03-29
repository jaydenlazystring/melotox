import Foundation

enum SessionResult: String, Codable, Sendable {
    case completed
    case failed
    case inProgress
}
