import Foundation
import SwiftUI

// MARK: - AppRoute

enum AppRoute: Equatable, Sendable {
    case onboarding
    case login
    case usernameSetup
    case home
    case profile
    case about
    case appSelection
    case intervention(appToken: String)
    case melodyGate(appToken: String)
    case unlockDuration(appToken: String)
}

// MARK: - AppCoordinator

@MainActor
final class AppCoordinator: ObservableObject {

    // MARK: - Published State

    @Published var currentRoute: AppRoute = .onboarding
    @Published var isAuthenticated: Bool = false
    @Published private(set) var currentUser: User?

    /// Active overlay flow (intervention/melodyGate/unlock) presented on top of tabs.
    @Published var overlayRoute: AppRoute? = nil

    /// Selected tab in the main tab bar.
    @Published var selectedTab: MainTab = .home

    // MARK: - Init

    init() {}

    // MARK: - Navigation

    func navigateTo(_ route: AppRoute) {
        currentRoute = route
    }

    // MARK: - Authentication

    func handleLoginSuccess(_ user: User) {
        currentUser = user
        isAuthenticated = true
        // New users pick a handle before entering the app.
        currentRoute = (user.username?.isEmpty ?? true) ? .usernameSetup : .home
    }

    /// Called once the user has chosen a handle during onboarding.
    func completeUsernameSetup(_ updatedUser: User) {
        currentUser = updatedUser
        currentRoute = .home
    }

    func handleLogout() {
        currentUser = nil
        isAuthenticated = false
        overlayRoute = nil
        currentRoute = .login
    }

    // MARK: - Intervention Flow (overlay on top of tabs)

    func startIntervention(for appToken: String) {
        overlayRoute = .intervention(appToken: appToken)
    }

    func proceedToMelodyGate(appToken: String) {
        overlayRoute = .melodyGate(appToken: appToken)
    }

    func completeMelodyGate(appToken: String) {
        overlayRoute = .unlockDuration(appToken: appToken)
    }

    func grantUnlock(minutes: Int) {
        overlayRoute = nil
        currentRoute = .home
    }

    func dismissIntervention() {
        overlayRoute = nil
        currentRoute = .home
    }
}
