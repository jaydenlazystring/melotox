import Foundation

struct UnlockGrantDTO: Codable, Sendable {
    let id: UUID
    let appToken: String
    let grantedMinutes: Int
    let startAt: Date
    let endAt: Date

    func toEntity() -> UnlockGrant {
        UnlockGrant(
            id: id,
            appToken: appToken,
            grantedMinutes: grantedMinutes,
            startAt: startAt,
            endAt: endAt
        )
    }

    static func fromEntity(_ grant: UnlockGrant) -> UnlockGrantDTO {
        UnlockGrantDTO(
            id: grant.id,
            appToken: grant.appToken,
            grantedMinutes: grant.grantedMinutes,
            startAt: grant.startAt,
            endAt: grant.endAt
        )
    }
}
