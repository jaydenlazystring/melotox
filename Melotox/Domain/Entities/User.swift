import Foundation

struct User: Identifiable, Codable, Sendable {
    let id: UUID
    let provider: AuthProvider
    let email: String
    let displayName: String
    let createdAt: Date
}
