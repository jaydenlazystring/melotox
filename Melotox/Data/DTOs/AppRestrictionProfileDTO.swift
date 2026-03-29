import Foundation

struct AppRestrictionProfileDTO: Codable, Sendable {
    let id: UUID
    var selectedApplicationTokens: [String]
    var defaultUnlockDurations: [Int]
    var isActive: Bool

    func toEntity() -> AppRestrictionProfile {
        AppRestrictionProfile(
            id: id,
            selectedApplicationTokens: selectedApplicationTokens,
            defaultUnlockDurations: defaultUnlockDurations,
            isActive: isActive
        )
    }

    static func fromEntity(_ profile: AppRestrictionProfile) -> AppRestrictionProfileDTO {
        AppRestrictionProfileDTO(
            id: profile.id,
            selectedApplicationTokens: profile.selectedApplicationTokens,
            defaultUnlockDurations: profile.defaultUnlockDurations,
            isActive: profile.isActive
        )
    }
}
