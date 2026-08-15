import SwiftUI
#if canImport(GoogleSignIn)
import GoogleSignIn
#endif

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
            .onOpenURL { url in
                #if canImport(GoogleSignIn)
                _ = GIDSignIn.sharedInstance.handle(url)
                #endif
            }
        }
    }

    // MARK: - Unauthenticated Flow

    @ViewBuilder
    private var unauthenticatedContent: some View {
        switch coordinator.currentRoute {
        case .login:
            LoginScreen(coordinator: coordinator, container: container)
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
        // Gate the app behind username selection for brand-new accounts.
        if case .usernameSetup = coordinator.currentRoute {
            UsernameSetupScreen(coordinator: coordinator, container: container)
        } else {
            mainContent
        }
    }

    private var mainContent: some View {
        ZStack {
            // Base: Tab bar with Home / Activity / Settings
            tabbedContent

            // Overlay: full-screen flows (intervention, melodyGate, unlock, profile, appSelection)
            if let overlayRoute = coordinator.overlayRoute {
                overlayContent(for: overlayRoute)
                    .transition(.move(edge: .trailing))
                    .zIndex(2) // above route screens (appSelection/profile/about)
            }

            if case .profile = coordinator.currentRoute {
                ProfileScreen(
                    coordinator: coordinator,
                    container: container
                )
                .transition(.move(edge: .trailing))
                .zIndex(1)
            }

            if case .about = coordinator.currentRoute {
                AboutView(onBack: { coordinator.navigateTo(.home) })
                    .transition(.move(edge: .trailing))
                    .zIndex(1)
            }

            if case .appSelection = coordinator.currentRoute {
                AppSelectionScreen(
                    container: container,
                    onBack: { coordinator.navigateTo(.home) },
                    onSaved: { coordinator.navigateTo(.home) },
                    onPreviewBlock: { coordinator.startIntervention(for: "com.mock.preview") }
                )
                .transition(.move(edge: .trailing))
                .zIndex(1)
            }
        }
        .animation(.easeInOut(duration: 0.25), value: coordinator.overlayRoute)
        .animation(.easeInOut(duration: 0.25), value: coordinator.currentRoute)
    }

    private var tabbedContent: some View {
        MainTabView(
            selectedTab: $coordinator.selectedTab,
            homeContent: AnyView(
                HomeScreen(coordinator: coordinator, container: container)
            ),
            activityContent: AnyView(
                ActivityScreen(container: container)
            ),
            settingsContent: AnyView(
                SettingsScreen(coordinator: coordinator, container: container)
            )
        )
    }

    @ViewBuilder
    private func overlayContent(for route: AppRoute) -> some View {
        switch route {
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
                onComplete: { coordinator.completeMelodyGate(appToken: appToken) },
                onQuit: { coordinator.dismissIntervention() }
            )

        case .unlockDuration(let appToken):
            UnlockScreen(
                container: container,
                appToken: appToken,
                onGranted: { minutes in coordinator.grantUnlock(minutes: minutes) }
            )

        default:
            EmptyView()
        }
    }

    // MARK: - Debug Helpers

    #if DEBUG
    private var mockLoginButton: some View {
        Button {
            let mockUser = User(
                id: UUID().uuidString,
                provider: .apple,
                email: "test@melotox.com",
                displayName: "Tester",
                username: "tester",
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
    #endif
}

// MARK: - Wrapper Screens

private struct LoginScreen: View {
    let coordinator: AppCoordinator
    let container: DependencyContainer

    @StateObject private var viewModel: LoginViewModel

    init(coordinator: AppCoordinator, container: DependencyContainer) {
        self.coordinator = coordinator
        self.container = container
        _viewModel = StateObject(wrappedValue: container.makeLoginViewModel())
    }

    var body: some View {
        LoginView(viewModel: viewModel)
            .onChange(of: viewModel.user) { _, user in
                if let user { coordinator.handleLoginSuccess(user) }
            }
    }
}

private struct UsernameSetupScreen: View {
    let coordinator: AppCoordinator
    let container: DependencyContainer

    @StateObject private var viewModel: UsernameSetupViewModel

    init(coordinator: AppCoordinator, container: DependencyContainer) {
        self.coordinator = coordinator
        self.container = container
        let uid = coordinator.currentUser?.id ?? ""
        _viewModel = StateObject(wrappedValue: container.makeUsernameSetupViewModel(uid: uid))
    }

    var body: some View {
        UsernameSetupView(viewModel: viewModel)
            .onChange(of: viewModel.didComplete) { _, done in
                if done, let user = viewModel.completedUser {
                    coordinator.completeUsernameSetup(user)
                }
            }
    }
}

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
            onManageApps: { coordinator.navigateTo(.appSelection) },
            onProfileTap: { coordinator.navigateTo(.profile) }
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
                if viewModel.isRestrictionActive {
                    coordinator.startIntervention(for: "com.mock.instagram")
                }
            } label: {
                Text(viewModel.isRestrictionActive ? "Test Intervention (Debug)" : "Protection Off")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundStyle(.white)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 10)
                    .background(
                        viewModel.isRestrictionActive
                            ? Color(hex: "7C3AED").opacity(0.6)
                            : Color.gray.opacity(0.3)
                    )
                    .clipShape(Capsule())
            }
            .disabled(!viewModel.isRestrictionActive)
            .padding(.bottom, 90) // above tab bar
            #endif
        }
    }
}

private struct ProfileScreen: View {
    let coordinator: AppCoordinator
    let container: DependencyContainer

    @StateObject private var viewModel: ProfileViewModel

    init(coordinator: AppCoordinator, container: DependencyContainer) {
        self.coordinator = coordinator
        self.container = container
        _viewModel = StateObject(wrappedValue: container.makeProfileViewModel())
    }

    var body: some View {
        ProfileView(
            viewModel: viewModel,
            onBack: { coordinator.navigateTo(.home) }
        )
        .onAppear {
            guard let user = coordinator.currentUser else { return }
            viewModel.loadUser(user)
        }
        .onChange(of: viewModel.didSignOut) { _, signedOut in
            if signedOut { coordinator.handleLogout() }
        }
    }
}

private struct SettingsScreen: View {
    let coordinator: AppCoordinator
    let container: DependencyContainer

    var body: some View {
        ZStack {
            Color(hex: "0D0D0D")
                .ignoresSafeArea()

            VStack(spacing: 0) {
                Text("Settings")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundStyle(.white)
                    .padding(.top, 60)
                    .padding(.bottom, 24)

                VStack(spacing: 0) {
                    settingsRow(icon: "app.badge.fill", label: "Manage Apps") {
                        coordinator.navigateTo(.appSelection)
                    }
                    Divider().background(Color.white.opacity(0.1))
                    settingsRow(icon: "person.fill", label: "Profile") {
                        coordinator.navigateTo(.profile)
                    }
                    Divider().background(Color.white.opacity(0.1))
                    settingsRow(icon: "info.circle", label: "About Melotox") {
                        coordinator.navigateTo(.about)
                    }
                }
                .background(Color(hex: "1A1A2E"))
                .clipShape(RoundedRectangle(cornerRadius: 16))
                .padding(.horizontal, 20)

                Spacer()
            }
        }
    }

    private func settingsRow(icon: String, label: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 14) {
                Image(systemName: icon)
                    .font(.body)
                    .foregroundStyle(Color(hex: "A78BFA"))
                    .frame(width: 28)

                Text(label)
                    .font(.body)
                    .foregroundStyle(.white)

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundStyle(Color.white.opacity(0.3))
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
        }
        .buttonStyle(.plain)
    }
}

private struct ActivityScreen: View {
    let container: DependencyContainer

    @StateObject private var viewModel: ActivityViewModel

    init(container: DependencyContainer) {
        self.container = container
        _viewModel = StateObject(wrappedValue: container.makeActivityViewModel())
    }

    var body: some View {
        ActivityView(viewModel: viewModel)
    }
}

private struct AppSelectionScreen: View {
    let container: DependencyContainer
    let onBack: () -> Void
    let onSaved: () -> Void
    let onPreviewBlock: () -> Void

    @StateObject private var viewModel: AppSelectionViewModel

    init(container: DependencyContainer, onBack: @escaping () -> Void, onSaved: @escaping () -> Void, onPreviewBlock: @escaping () -> Void) {
        self.container = container
        self.onBack = onBack
        self.onSaved = onSaved
        self.onPreviewBlock = onPreviewBlock
        _viewModel = StateObject(wrappedValue: container.makeAppSelectionViewModel())
    }

    var body: some View {
        AppSelectionView(viewModel: viewModel, onPreviewBlock: onPreviewBlock)
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
