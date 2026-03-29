import SwiftUI

@main
struct MelotoxApp: App {

    @StateObject private var coordinator = AppCoordinator()

    var body: some Scene {
        WindowGroup {
            Group {
                if coordinator.isAuthenticated {
                    authenticatedContent
                } else {
                    unauthenticatedContent
                }
            }
            .animation(.easeInOut, value: coordinator.isAuthenticated)
            .animation(.easeInOut, value: coordinator.currentRoute)
        }
    }

    // MARK: - Unauthenticated Flow

    @ViewBuilder
    private var unauthenticatedContent: some View {
        switch coordinator.currentRoute {
        case .login:
            LoginView(viewModel: DependencyContainer.shared.makeLoginViewModel())
                .environmentObject(coordinator)

        default:
            OnboardingView {
                coordinator.navigateTo(.login)
            }
        }
    }

    // MARK: - Authenticated Flow

    @ViewBuilder
    private var authenticatedContent: some View {
        switch coordinator.currentRoute {
        case .home:
            Text("Home")
                .environmentObject(coordinator)

        case .appSelection:
            Text("App Selection")
                .environmentObject(coordinator)

        case .intervention(let appToken):
            Text("Intervention: \(appToken)")
                .environmentObject(coordinator)

        case .melodyGate:
            Text("Melody Gate")
                .environmentObject(coordinator)

        case .unlockDuration(let appToken):
            Text("Unlock Duration: \(appToken)")
                .environmentObject(coordinator)

        default:
            Text("Home")
                .environmentObject(coordinator)
        }
    }
}
