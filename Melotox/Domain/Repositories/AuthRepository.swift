import Foundation

protocol AuthRepository: Sendable {
    func signInWithGoogle() async throws -> User
    func signInWithApple() async throws -> User
    func restoreSession() async throws -> User?
    func signOut() async throws
}
