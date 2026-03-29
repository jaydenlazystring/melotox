import Foundation

enum MelotoxError: Error, Sendable {
    case authenticationFailed(String)
    case sessionExpired
    case restrictionNotActive
    case audioPlaybackFailed
    case melodyGateFailed
    case storageError(String)
    case screenTimeNotAuthorized
    case unknown(Error)
}
