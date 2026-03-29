import Foundation

#if canImport(FamilyControls)
import FamilyControls
import DeviceActivity
import ManagedSettings
#endif

final class LiveScreenTimeManager: @unchecked Sendable, ScreenTimeManaging {

    #if canImport(FamilyControls)
    private let center = AuthorizationCenter.shared
    private let store = ManagedSettingsStore()
    #endif

    private(set) var isAuthorized: Bool = false

    init() {}

    func requestAuthorization() async throws {
        #if canImport(FamilyControls)
        try await center.requestAuthorization(for: .individual)
        isAuthorized = true
        #else
        throw ScreenTimeError.screenTimeNotAuthorized
        #endif
    }

    func selectApps() async throws -> [String] {
        #if canImport(FamilyControls)
        throw ScreenTimeError.selectionCancelled
        #else
        throw ScreenTimeError.screenTimeNotAuthorized
        #endif
    }

    func applyShield(to tokens: [String]) async throws {
        #if canImport(FamilyControls)
        print("[LiveScreenTimeManager] applyShield(to:) called with \(tokens.count) token(s).")
        #else
        throw ScreenTimeError.screenTimeNotAuthorized
        #endif
    }

    func removeShield() async throws {
        #if canImport(FamilyControls)
        store.clearAllSettings()
        #else
        throw ScreenTimeError.screenTimeNotAuthorized
        #endif
    }
}
