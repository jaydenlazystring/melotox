import Foundation

struct UserDTO: Codable, Sendable {
    let id: String
    let provider: String
    let email: String
    let displayName: String
    var username: String?
    let createdAt: Date

    func toEntity() -> User {
        User(
            id: id,
            provider: AuthProvider(rawValue: provider) ?? .google,
            email: email,
            displayName: displayName,
            username: username,
            createdAt: createdAt
        )
    }

    static func fromEntity(_ user: User) -> UserDTO {
        UserDTO(
            id: user.id,
            provider: user.provider.rawValue,
            email: user.email,
            displayName: user.displayName,
            username: user.username,
            createdAt: user.createdAt
        )
    }
}
