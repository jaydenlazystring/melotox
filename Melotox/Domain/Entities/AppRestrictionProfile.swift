import Foundation

struct AppRestrictionProfile: Identifiable, Codable, Sendable {
    let id: UUID
    var selectedApplicationTokens: [String]
    var defaultUnlockDurations: [Int] = [5, 10, 15]
    var isActive: Bool
}
