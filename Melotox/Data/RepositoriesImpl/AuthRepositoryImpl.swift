import Foundation
#if canImport(FirebaseAuth)
import FirebaseAuth
#endif
#if canImport(GoogleSignIn)
import GoogleSignIn
#endif

final class AuthRepositoryImpl: AuthRepository, @unchecked Sendable {

    private let googleAuth: GoogleAuthService
    private let appleSignIn: AppleSignInService
    private let sessionStorage: KeychainSessionStorage
    private let userProfileRepository: any UserProfileRepository

    init(
        googleAuth: GoogleAuthService,
        appleSignIn: AppleSignInService,
        sessionStorage: KeychainSessionStorage,
        userProfileRepository: any UserProfileRepository
    ) {
        self.googleAuth = googleAuth
        self.appleSignIn = appleSignIn
        self.sessionStorage = sessionStorage
        self.userProfileRepository = userProfileRepository
    }

    // MARK: - Sign In

    func signInWithGoogle() async throws -> User {
        let result = try await googleAuth.signIn()
        let uid = try await googleFirebaseUID(
            idToken: result.idToken,
            accessToken: result.accessToken
        ) ?? result.id
        return try await resolveUser(
            uid: uid,
            provider: .google,
            email: result.email,
            displayName: result.displayName
        )
    }

    func signInWithApple() async throws -> User {
        let result = try await appleSignIn.signIn()
        let uid = try await appleFirebaseUID(
            idToken: result.idToken,
            rawNonce: result.rawNonce
        ) ?? result.id
        return try await resolveUser(
            uid: uid,
            provider: .apple,
            email: result.email,
            displayName: result.displayName
        )
    }

    // MARK: - Session

    func restoreSession() async throws -> User? {
        guard let dto = try sessionStorage.loadUser() else { return nil }
        // Refresh from the backend so a handle chosen elsewhere is reflected.
        if let refreshed = try? await userProfileRepository.fetchProfile(uid: dto.id) {
            try? sessionStorage.saveUser(UserDTO.fromEntity(refreshed))
            return refreshed
        }
        return dto.toEntity()
    }

    func signOut() async throws {
        try sessionStorage.clear()
        #if canImport(FirebaseAuth)
        try? Auth.auth().signOut()
        #endif
        #if canImport(GoogleSignIn)
        GIDSignIn.sharedInstance.signOut()
        #endif
    }

    // MARK: - Helpers

    /// Loads the backend profile (preserving an existing username) or creates a
    /// fresh record, then persists the session to the Keychain.
    private func resolveUser(
        uid: String,
        provider: AuthProvider,
        email: String,
        displayName: String
    ) async throws -> User {
        if let existing = try await userProfileRepository.fetchProfile(uid: uid) {
            try sessionStorage.saveUser(UserDTO.fromEntity(existing))
            return existing
        }

        let newUser = User(
            id: uid,
            provider: provider,
            email: email,
            displayName: displayName,
            username: nil,
            createdAt: Date()
        )
        try await userProfileRepository.upsertUser(newUser)
        try sessionStorage.saveUser(UserDTO.fromEntity(newUser))
        return newUser
    }

    private func appleFirebaseUID(idToken: String?, rawNonce: String?) async throws -> String? {
        #if canImport(FirebaseAuth)
        guard FirebaseConfigurator.isAvailable, let idToken, let rawNonce else { return nil }
        let credential = OAuthProvider.appleCredential(
            withIDToken: idToken,
            rawNonce: rawNonce,
            fullName: nil
        )
        let authResult = try await Auth.auth().signIn(with: credential)
        return authResult.user.uid
        #else
        return nil
        #endif
    }

    private func googleFirebaseUID(idToken: String?, accessToken: String?) async throws -> String? {
        #if canImport(FirebaseAuth)
        guard FirebaseConfigurator.isAvailable, let idToken, let accessToken else { return nil }
        let credential = GoogleAuthProvider.credential(
            withIDToken: idToken,
            accessToken: accessToken
        )
        let authResult = try await Auth.auth().signIn(with: credential)
        return authResult.user.uid
        #else
        return nil
        #endif
    }
}
