import Foundation

final class AuthRepositoryImpl: AuthRepository, @unchecked Sendable {

    private let googleAuth: GoogleAuthService
    private let appleSignIn: AppleSignInService
    private let sessionStorage: KeychainSessionStorage

    init(googleAuth: GoogleAuthService, appleSignIn: AppleSignInService, sessionStorage: KeychainSessionStorage) {
        self.googleAuth = googleAuth
        self.appleSignIn = appleSignIn
        self.sessionStorage = sessionStorage
    }

    func signInWithGoogle() async throws -> User {
        let result = try await googleAuth.signIn()
        let user = User(
            id: UUID(),
            provider: .google,
            email: result.email,
            displayName: result.displayName,
            createdAt: Date()
        )
        let dto = UserDTO.fromEntity(user)
        try sessionStorage.saveUser(dto)
        return user
    }

    func signInWithApple() async throws -> User {
        let result = try await appleSignIn.signIn()
        let user = User(
            id: UUID(),
            provider: .apple,
            email: result.email,
            displayName: result.displayName,
            createdAt: Date()
        )
        let dto = UserDTO.fromEntity(user)
        try sessionStorage.saveUser(dto)
        return user
    }

    func restoreSession() async throws -> User? {
        guard let dto = try sessionStorage.loadUser() else { return nil }
        return dto.toEntity()
    }

    func signOut() async throws {
        try sessionStorage.clear()
    }
}
