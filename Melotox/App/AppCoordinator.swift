import Foundation
import SwiftUI

// MARK: - AppRoute

enum AppRoute: Equatable, Sendable {
    case onboarding
    case login
    case home
    case appSelection
    case intervention(appToken: String)
    case melodyGate
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

    func completeMelodyGate() {
        // After melody gate completes, navigate to unlock duration screen.
        // The appToken is carried from the previous route context.
        if case .melodyGate = currentRoute {
            // Retrieve the app token from the active session context.
            // The ViewModel should call navigateTo directly with the token.
        }
        currentRoute = .melodyGate
    }

    func grantUnlock(minutes: Int) {
        // After unlock is granted, return to home.
        currentRoute = .home
    }
}
