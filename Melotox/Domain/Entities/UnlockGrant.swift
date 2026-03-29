import Foundation

struct UnlockGrant: Identifiable, Codable, Sendable {
    let id: UUID
    let appToken: String
    let grantedMinutes: Int
    let startAt: Date
    let endAt: Date

    var isExpired: Bool {
        Date() >= endAt
    }
}
