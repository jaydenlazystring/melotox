import Foundation

/// Firestore representation of a `users/{uid}` document. Kept independent of the
/// Firebase SDK so it compiles with or without FirebaseFirestore linked.
struct UserProfileFirestoreDTO: Codable, Sendable {
    var uid: String
    var provider: String
    var email: String
    var displayName: String
    var username: String?
    var usernameLower: String?
    var createdAt: Date
    var updatedAt: Date

    func toEntity() -> User {
        User(
            id: uid,
            provider: AuthProvider(rawValue: provider) ?? .google,
            email: email,
            displayName: displayName,
            username: username,
            createdAt: createdAt
        )
    }

    static func fromEntity(_ user: User, updatedAt: Date) -> UserProfileFirestoreDTO {
        UserProfileFirestoreDTO(
            uid: user.id,
            provider: user.provider.rawValue,
            email: user.email,
            displayName: user.displayName,
            username: user.username,
            usernameLower: user.username?.lowercased(),
            createdAt: user.createdAt,
            updatedAt: updatedAt
        )
    }
}
