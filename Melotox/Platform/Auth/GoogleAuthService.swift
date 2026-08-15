import Foundation
#if canImport(GoogleSignIn)
import GoogleSignIn
#endif
#if canImport(UIKit)
import UIKit
#endif

// MARK: - GoogleSignInResult

struct GoogleSignInResult: Sendable {
    let id: String
    let email: String
    let displayName: String
    let idToken: String?
    let accessToken: String?
}

// MARK: - GoogleAuthService

/// Wraps Google Sign-In SDK to provide async authentication.
final class GoogleAuthService: Sendable {

    // MARK: - Errors

    enum GoogleAuthError: Error, Sendable {
        case sdkNotAvailable
        case noPresenter
        case signInFailed(underlying: String)
        case missingProfile
    }

    // MARK: - Init

    init() {}

    // MARK: - Public

    /// Performs Google Sign-In and returns the authenticated user's info + tokens.
    @MainActor
    func signIn() async throws -> GoogleSignInResult {
        #if canImport(GoogleSignIn) && canImport(UIKit)
        guard let presenter = Self.rootViewController() else {
            throw GoogleAuthError.noPresenter
        }

        let signInResult = try await GIDSignIn.sharedInstance.signIn(withPresenting: presenter)
        let user = signInResult.user
        guard let profile = user.profile else {
            throw GoogleAuthError.missingProfile
        }

        return GoogleSignInResult(
            id: user.userID ?? UUID().uuidString,
            email: profile.email,
            displayName: profile.name,
            idToken: user.idToken?.tokenString,
            accessToken: user.accessToken.tokenString
        )
        #else
        throw GoogleAuthError.sdkNotAvailable
        #endif
    }

    #if canImport(UIKit)
    /// Finds the top-most view controller of the active foreground scene.
    @MainActor
    private static func rootViewController() -> UIViewController? {
        let scene = UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .first(where: { $0.activationState == .foregroundActive })
        var top = scene?.keyWindow?.rootViewController
            ?? scene?.windows.first?.rootViewController
        while let presented = top?.presentedViewController {
            top = presented
        }
        return top
    }
    #endif
}
