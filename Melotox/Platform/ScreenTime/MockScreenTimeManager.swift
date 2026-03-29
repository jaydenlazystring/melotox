import Foundation

final class MockScreenTimeManager: @unchecked Sendable, ScreenTimeManaging {

    private(set) var isAuthorized: Bool = true
    private(set) var shieldedTokens: [String] = []

    func requestAuthorization() async throws {
        isAuthorized = true
    }

    func selectApps() async throws -> [String] {
        ["com.mock.instagram", "com.mock.youtube", "com.mock.tiktok"]
    }

    func applyShield(to tokens: [String]) async throws {
        shieldedTokens = tokens
    }

    func removeShield() async throws {
        shieldedTokens = []
    }
}
