import AuthenticationServices
import Foundation

// MARK: - AppleSignInService

/// Wraps Sign in with Apple using ASAuthorizationController and exposes an async interface.
final class AppleSignInService: NSObject, Sendable {

    // MARK: - Errors

    enum AppleSignInError: Error, Sendable {
        case authorizationFailed(underlying: String)
        case missingCredential
        case unknownCredentialType
    }

    // MARK: - Private State

    /// Thread-safe storage for the in-flight continuation.
    private let continuationLock = NSLock()
    private nonisolated(unsafe) var _continuation: CheckedContinuation<(id: String, email: String, displayName: String), Error>?

    private func storeContinuation(_ c: CheckedContinuation<(id: String, email: String, displayName: String), Error>) {
        continuationLock.lock()
        _continuation = c
        continuationLock.unlock()
    }

    private func takeContinuation() -> CheckedContinuation<(id: String, email: String, displayName: String), Error>? {
        continuationLock.lock()
        let c = _continuation
        _continuation = nil
        continuationLock.unlock()
        return c
    }

    // MARK: - Public

    /// Presents the Apple Sign-In sheet and returns the authenticated user's info.
    @MainActor
    func signIn() async throws -> (id: String, email: String, displayName: String) {
        let provider = ASAuthorizationAppleIDProvider()
        let request = provider.createRequest()
        request.requestedScopes = [.fullName, .email]

        let controller = ASAuthorizationController(authorizationRequests: [request])

        return try await withCheckedThrowingContinuation { continuation in
            storeContinuation(continuation)
            controller.delegate = self
            controller.performRequests()
        }
    }
}

// MARK: - ASAuthorizationControllerDelegate

extension AppleSignInService: ASAuthorizationControllerDelegate {

    func authorizationController(controller: ASAuthorizationController,
                                 didCompleteWithAuthorization authorization: ASAuthorization) {
        guard let credential = authorization.credential as? ASAuthorizationAppleIDCredential else {
            takeContinuation()?.resume(throwing: AppleSignInError.unknownCredentialType)
            return
        }

        let userID = credential.user
        let email = credential.email ?? "\(userID)@privaterelay.appleid.com"
        let displayName: String = {
            let given = credential.fullName?.givenName ?? ""
            let family = credential.fullName?.familyName ?? ""
            let combined = [given, family].filter { !$0.isEmpty }.joined(separator: " ")
            return combined.isEmpty ? "Apple User" : combined
        }()

        takeContinuation()?.resume(returning: (id: userID, email: email, displayName: displayName))
    }

    func authorizationController(controller: ASAuthorizationController,
                                 didCompleteWithError error: Error) {
        takeContinuation()?.resume(throwing: AppleSignInError.authorizationFailed(underlying: error.localizedDescription))
    }
}
