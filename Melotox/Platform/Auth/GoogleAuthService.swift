import Foundation
#if canImport(GoogleSignIn)
import GoogleSignIn
#endif

// MARK: - GoogleAuthService

/// Wraps Google Sign-In SDK to provide async authentication.
final class GoogleAuthService: Sendable {

    // MARK: - Errors

    enum GoogleAuthError: Error, Sendable {
        case sdkNotAvailable
        case signInFailed(underlying: String)
        case missingProfile
    }

    // MARK: - Init

    init() {}

    // MARK: - Public

    /// Performs Google Sign-In and returns the authenticated user's info.
    func signIn() async throws -> (id: String, email: String, displayName: String) {
        #if canImport(GoogleSignIn)
        return try await withCheckedThrowingContinuation { continuation in
            // TODO: Get the root view controller from the active scene.
            // guard let presentingVC = ... else { ... }

            // TODO: Call GIDSignIn.sharedInstance.signIn(withPresenting:) and
            //       resume the continuation with the result or error.
            //
            // Example (requires GoogleSignIn 7.x):
            // GIDSignIn.sharedInstance.signIn(withPresenting: presentingVC) { result, error in
            //     if let error {
            //         continuation.resume(throwing: GoogleAuthError.signInFailed(underlying: error.localizedDescription))
            //         return
            //     }
            //     guard let user = result?.user,
            //           let profile = user.profile else {
            //         continuation.resume(throwing: GoogleAuthError.missingProfile)
            //         return
            //     }
            //     let id = user.userID ?? UUID().uuidString
            //     continuation.resume(returning: (id: id, email: profile.email, displayName: profile.name))
            // }

            continuation.resume(throwing: GoogleAuthError.signInFailed(underlying: "Google Sign-In not yet wired up"))
        }
        #else
        throw GoogleAuthError.sdkNotAvailable
        #endif
    }
}
