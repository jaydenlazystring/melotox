import Foundation

struct UserDTO: Codable, Sendable {
    let id: UUID
    let provider: String
    let email: String
    let displayName: String
    let createdAt: Date

    func toEntity() -> User {
        User(
            id: id,
            provider: AuthProvider(rawValue: provider) ?? .google,
            email: email,
            displayName: displayName,
            createdAt: createdAt
        )
    }

    static func fromEntity(_ user: User) -> UserDTO {
        UserDTO(
            id: user.id,
            provider: user.provider.rawValue,
            email: user.email,
            displayName: user.displayName,
            createdAt: user.createdAt
        )
    }
}
