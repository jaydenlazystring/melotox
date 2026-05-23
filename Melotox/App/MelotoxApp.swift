import SwiftUI

@main
struct MelotoxApp: App {

    @StateObject private var coordinator = AppCoordinator()
    private let container = DependencyContainer.shared

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
            LoginView(viewModel: container.makeLoginViewModel())
                .overlay(alignment: .bottom) {
                    #if DEBUG
                    mockLoginButton
                    #endif
                }

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
            HomeScreen(
                coordinator: coordinator,
                container: container
            )

        case .appSelection:
            AppSelectionScreen(
                container: container,
                onBack: { coordinator.navigateTo(.home) },
                onSaved: { coordinator.navigateTo(.home) }
            )

        case .intervention(let appToken):
            InterventionScreen(
                container: container,
                appToken: appToken,
                onProceedToMelodyGate: { coordinator.proceedToMelodyGate(appToken: appToken) },
                onDismiss: { coordinator.dismissIntervention() }
            )

        case .melodyGate(let appToken):
            MelodyGateView(
                viewModel: container.makeMelodyGateViewModel(),
                onComplete: { coordinator.completeMelodyGate(appToken: appToken) }
            )

        case .unlockDuration(let appToken):
            UnlockScreen(
                container: container,
                appToken: appToken,
                onGranted: { minutes in coordinator.grantUnlock(minutes: minutes) }
            )

        default:
            HomeScreen(
                coordinator: coordinator,
                container: container
            )
        }
    }

    // MARK: - Debug Helpers

    #if DEBUG
    private var mockLoginButton: some View {
        Button {
            let mockUser = User(
                id: UUID(),
                provider: .apple,
                email: "test@melotox.com",
                displayName: "Tester",
                createdAt: Date()
            )
            coordinator.handleLoginSuccess(mockUser)
        } label: {
            Text("Skip Login (Debug)")
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundStyle(.white)
                .padding(.horizontal, 20)
                .padding(.vertical, 10)
                .background(Color(hex: "7C3AED").opacity(0.6))
                .clipShape(Capsule())
        }
        .padding(.bottom, 30)
    }

    private var debugTestInterventionButton: some View {
        Button {
            coordinator.startIntervention(for: "com.mock.instagram")
        } label: {
            Text("Test Intervention (Debug)")
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundStyle(.white)
                .padding(.horizontal, 20)
                .padding(.vertical, 10)
                .background(Color(hex: "7C3AED").opacity(0.6))
                .clipShape(Capsule())
        }
        .padding(.bottom, 30)
    }
    #endif
}

// MARK: - Wrapper Screens (own ViewModel lifecycle)

private struct HomeScreen: View {
    let coordinator: AppCoordinator
    let container: DependencyContainer

    @StateObject private var viewModel: HomeViewModel

    init(coordinator: AppCoordinator, container: DependencyContainer) {
        self.coordinator = coordinator
        self.container = container
        _viewModel = StateObject(wrappedValue: container.makeHomeViewModel())
    }

    var body: some View {
        HomeView(
            viewModel: viewModel,
            onManageApps: { coordinator.navigateTo(.appSelection) }
        )
        .onAppear {
            guard let user = coordinator.currentUser else { return }
            viewModel.loadProfile(user: user)
        }
        .onChange(of: coordinator.currentRoute) { _, newRoute in
            if case .home = newRoute, let user = coordinator.currentUser {
                viewModel.loadProfile(user: user)
            }
        }
        .overlay(alignment: .bottom) {
            #if DEBUG
            Button {
                coordinator.startIntervention(for: "com.mock.instagram")
            } label: {
                Text("Test Intervention (Debug)")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundStyle(.white)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 10)
                    .background(Color(hex: "7C3AED").opacity(0.6))
                    .clipShape(Capsule())
            }
            .padding(.bottom, 30)
            #endif
        }
    }
}

private struct AppSelectionScreen: View {
    let container: DependencyContainer
    let onBack: () -> Void
    let onSaved: () -> Void

    @StateObject private var viewModel: AppSelectionViewModel

    init(container: DependencyContainer, onBack: @escaping () -> Void, onSaved: @escaping () -> Void) {
        self.container = container
        self.onBack = onBack
        self.onSaved = onSaved
        _viewModel = StateObject(wrappedValue: container.makeAppSelectionViewModel())
    }

    var body: some View {
        AppSelectionView(viewModel: viewModel)
            .overlay(alignment: .topLeading) {
                Button(action: onBack) {
                    HStack(spacing: 4) {
                        Image(systemName: "chevron.left")
                        Text("Back")
                    }
                    .font(.body)
                    .foregroundStyle(Color(hex: "A78BFA"))
                    .padding(.leading, 16)
                    .padding(.top, 8)
                }
            }
            .onChange(of: viewModel.didSave) { _, saved in
                if saved { onSaved() }
            }
    }
}

private struct InterventionScreen: View {
    let container: DependencyContainer
    let appToken: String
    let onProceedToMelodyGate: () -> Void
    let onDismiss: () -> Void

    @StateObject private var viewModel: InterventionViewModel

    init(container: DependencyContainer, appToken: String, onProceedToMelodyGate: @escaping () -> Void, onDismiss: @escaping () -> Void) {
        self.container = container
        self.appToken = appToken
        self.onProceedToMelodyGate = onProceedToMelodyGate
        self.onDismiss = onDismiss
        _viewModel = StateObject(wrappedValue: container.makeInterventionViewModel())
    }

    var body: some View {
        InterventionQuestionView(viewModel: viewModel)
            .onAppear { viewModel.startIntervention(for: appToken) }
            .onChange(of: viewModel.shouldShowMelodyGate) { _, show in
                if show { onProceedToMelodyGate() }
            }
            .onChange(of: viewModel.shouldDismiss) { _, dismiss in
                if dismiss { onDismiss() }
            }
    }
}

private struct UnlockScreen: View {
    let container: DependencyContainer
    let appToken: String
    let onGranted: (Int) -> Void

    @StateObject private var viewModel: UnlockViewModel

    init(container: DependencyContainer, appToken: String, onGranted: @escaping (Int) -> Void) {
        self.container = container
        self.appToken = appToken
        self.onGranted = onGranted
        _viewModel = StateObject(wrappedValue: container.makeUnlockViewModel(appToken: appToken))
    }

    var body: some View {
        UnlockDurationView(viewModel: viewModel)
            .onChange(of: viewModel.isGranted) { _, granted in
                if granted { onGranted(viewModel.selectedDuration ?? 15) }
            }
    }
}
