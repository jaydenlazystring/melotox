import Foundation
import SwiftUI

// MARK: - AppRoute

enum AppRoute: Equatable, Sendable {
    case onboarding
    case login
    case home
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
        currentRoute = .home
    }

    func handleLogout() {
        currentUser = nil
        isAuthenticated = false
        currentRoute = .login
    }

    // MARK: - Intervention Flow

    func startIntervention(for appToken: String) {
        currentRoute = .intervention(appToken: appToken)
    }

    func proceedToMelodyGate(appToken: String) {
        currentRoute = .melodyGate(appToken: appToken)
    }

    func completeMelodyGate(appToken: String) {
        currentRoute = .unlockDuration(appToken: appToken)
    }

    func grantUnlock(minutes: Int) {
        currentRoute = .home
    }

    func dismissIntervention() {
        currentRoute = .home
    }
}
