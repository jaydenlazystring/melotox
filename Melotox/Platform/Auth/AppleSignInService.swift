import AuthenticationServices
import CryptoKit
import Foundation

// MARK: - AppleSignInResult

struct AppleSignInResult: Sendable {
    let id: String
    let email: String
    let displayName: String
    /// Apple identity token (JWT) used to build a Firebase credential. May be nil.
    let idToken: String?
    /// The raw (un-hashed) nonce paired with the request, required by Firebase.
    let rawNonce: String?
}

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
    private nonisolated(unsafe) var _continuation: CheckedContinuation<AppleSignInResult, Error>?
    /// The raw nonce paired with the current request.
    private nonisolated(unsafe) var _currentNonce: String?

    private func storeContinuation(_ c: CheckedContinuation<AppleSignInResult, Error>, nonce: String) {
        continuationLock.lock()
        _continuation = c
        _currentNonce = nonce
        continuationLock.unlock()
    }

    private func takeContinuation() -> (CheckedContinuation<AppleSignInResult, Error>?, String?) {
        continuationLock.lock()
        let c = _continuation
        let nonce = _currentNonce
        _continuation = nil
        _currentNonce = nil
        continuationLock.unlock()
        return (c, nonce)
    }

    // MARK: - Public

    /// Presents the Apple Sign-In sheet and returns the authenticated user's info.
    @MainActor
    func signIn() async throws -> AppleSignInResult {
        let rawNonce = Self.randomNonceString()
        let provider = ASAuthorizationAppleIDProvider()
        let request = provider.createRequest()
        request.requestedScopes = [.fullName, .email]
        request.nonce = Self.sha256(rawNonce)

        let controller = ASAuthorizationController(authorizationRequests: [request])

        return try await withCheckedThrowingContinuation { continuation in
            storeContinuation(continuation, nonce: rawNonce)
            controller.delegate = self
            controller.performRequests()
        }
    }

    // MARK: - Nonce Helpers

    private static func randomNonceString(length: Int = 32) -> String {
        let charset: [Character] = Array("0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz-._")
        var result = ""
        var remaining = length
        while remaining > 0 {
            var random: UInt8 = 0
            let status = SecRandomCopyBytes(kSecRandomDefault, 1, &random)
            if status == errSecSuccess {
                if random < charset.count {
                    result.append(charset[Int(random) % charset.count])
                    remaining -= 1
                }
            } else {
                // Fallback: still produces a valid nonce character.
                result.append(charset[Int(random) % charset.count])
                remaining -= 1
            }
        }
        return result
    }

    private static func sha256(_ input: String) -> String {
        let hashed = SHA256.hash(data: Data(input.utf8))
        return hashed.map { String(format: "%02x", $0) }.joined()
    }
}

// MARK: - ASAuthorizationControllerDelegate

extension AppleSignInService: ASAuthorizationControllerDelegate {

    func authorizationController(controller: ASAuthorizationController,
                                 didCompleteWithAuthorization authorization: ASAuthorization) {
        let (continuation, nonce) = takeContinuation()
        guard let credential = authorization.credential as? ASAuthorizationAppleIDCredential else {
            continuation?.resume(throwing: AppleSignInError.unknownCredentialType)
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
        let idToken = credential.identityToken.flatMap { String(data: $0, encoding: .utf8) }

        continuation?.resume(returning: AppleSignInResult(
            id: userID,
            email: email,
            displayName: displayName,
            idToken: idToken,
            rawNonce: nonce
        ))
    }

    func authorizationController(controller: ASAuthorizationController,
                                 didCompleteWithError error: Error) {
        let (continuation, _) = takeContinuation()
        continuation?.resume(throwing: AppleSignInError.authorizationFailed(underlying: error.localizedDescription))
    }
}
