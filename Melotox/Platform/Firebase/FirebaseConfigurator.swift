import Foundation

#if canImport(FirebaseCore)
import FirebaseCore
#endif
#if canImport(GoogleSignIn)
import GoogleSignIn
#endif

/// Centralizes third-party SDK startup so `MelotoxApp` stays clean. No-ops
/// gracefully when the SDKs aren't linked (e.g. before Firebase is configured).
enum FirebaseConfigurator {

    /// Whether a real Firebase backend is available at runtime.
    static var isAvailable: Bool {
        #if canImport(FirebaseCore)
        return FirebaseApp.app() != nil
        #else
        return false
        #endif
    }

    /// Call once at app launch (before any Firebase/Google usage).
    static func configure() {
        #if canImport(FirebaseCore)
        guard FirebaseApp.app() == nil else { return }
        // Requires GoogleService-Info.plist in the app bundle.
        guard Bundle.main.url(forResource: "GoogleService-Info", withExtension: "plist") != nil else {
            print("[FirebaseConfigurator] GoogleService-Info.plist missing — running in local fallback mode.")
            return
        }
        FirebaseApp.configure()

        #if canImport(GoogleSignIn)
        if let clientID = FirebaseApp.app()?.options.clientID {
            GIDSignIn.sharedInstance.configuration = GIDConfiguration(clientID: clientID)
        }
        #endif
        #endif
    }
}
