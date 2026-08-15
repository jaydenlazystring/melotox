import Foundation

@MainActor
final class DependencyContainer {

    // MARK: - Shared Instance

    static let shared = DependencyContainer()

    // MARK: - Platform Services

    let keychainService: KeychainService
    let screenTimeManager: any ScreenTimeManaging

    // MARK: - Data Repositories

    private(set) lazy var userProfileRepository: any UserProfileRepository = {
        #if canImport(FirebaseFirestore)
        if FirebaseConfigurator.isAvailable {
            return FirebaseUserProfileRepository()
        }
        #endif
        return LocalUserProfileRepository()
    }()

    private(set) lazy var authRepository: AuthRepositoryImpl = {
        let googleAuth = GoogleAuthService()
        let appleSignIn = AppleSignInService()
        let storage = KeychainSessionStorage(keychain: keychainService)
        return AuthRepositoryImpl(
            googleAuth: googleAuth,
            appleSignIn: appleSignIn,
            sessionStorage: storage,
            userProfileRepository: userProfileRepository
        )
    }()

    private(set) lazy var restrictionRepository: RestrictionRepositoryImpl = {
        RestrictionRepositoryImpl(screenTimeManager: screenTimeManager)
    }()

    private(set) lazy var audioRepository: AudioRepositoryImpl = {
        let player = AudioPlayerService()
        return AudioRepositoryImpl(audioPlayer: player)
    }()

    private(set) lazy var sessionRepository: SessionRepositoryImpl = {
        SessionRepositoryImpl()
    }()

    private(set) lazy var unlockRepository: UnlockRepositoryImpl = {
        UnlockRepositoryImpl()
    }()

    // MARK: - Domain Use Cases

    private(set) lazy var signInWithGoogleUseCase: SignInWithGoogleUseCase = {
        SignInWithGoogleUseCase(authRepository: authRepository)
    }()

    private(set) lazy var signInWithAppleUseCase: SignInWithAppleUseCase = {
        SignInWithAppleUseCase(authRepository: authRepository)
    }()

    private(set) lazy var restoreSessionUseCase: RestoreSessionUseCase = {
        RestoreSessionUseCase(authRepository: authRepository)
    }()

    private(set) lazy var checkUsernameAvailabilityUseCase: CheckUsernameAvailabilityUseCase = {
        CheckUsernameAvailabilityUseCase(repository: userProfileRepository)
    }()

    private(set) lazy var setUsernameUseCase: SetUsernameUseCase = {
        SetUsernameUseCase(repository: userProfileRepository)
    }()

    private(set) lazy var startInterventionUseCase: StartInterventionUseCase = {
        StartInterventionUseCase(
            sessionRepository: sessionRepository,
            audioRepository: audioRepository
        )
    }()

    private(set) lazy var completeMelodyGateUseCase: CompleteMelodyGateUseCase = {
        CompleteMelodyGateUseCase(sessionRepository: sessionRepository)
    }()

    private(set) lazy var selectRestrictedAppsUseCase: SelectRestrictedAppsUseCase = {
        SelectRestrictedAppsUseCase(restrictionRepository: restrictionRepository)
    }()

    private(set) lazy var grantUnlockTimeUseCase: GrantUnlockTimeUseCase = {
        GrantUnlockTimeUseCase(
            unlockRepository: unlockRepository,
            restrictionRepository: restrictionRepository
        )
    }()

    private(set) lazy var expireUnlockTimeUseCase: ExpireUnlockTimeUseCase = {
        ExpireUnlockTimeUseCase(
            unlockRepository: unlockRepository,
            restrictionRepository: restrictionRepository
        )
    }()

    // MARK: - Init

    init(screenTimeManager: any ScreenTimeManaging = MockScreenTimeManager()) {
        // Start Firebase before any repository is lazily resolved so the
        // backend-vs-local decision in `userProfileRepository` is correct.
        FirebaseConfigurator.configure()
        self.keychainService = KeychainService()
        self.screenTimeManager = screenTimeManager
    }

    // MARK: - ViewModel Factories

    func makeLoginViewModel() -> LoginViewModel {
        LoginViewModel(
            signInWithGoogleUseCase: signInWithGoogleUseCase,
            signInWithAppleUseCase: signInWithAppleUseCase
        )
    }

    func makeHomeViewModel() -> HomeViewModel {
        HomeViewModel(restrictionRepository: restrictionRepository)
    }

    func makeAppSelectionViewModel() -> AppSelectionViewModel {
        AppSelectionViewModel(
            selectRestrictedAppsUseCase: selectRestrictedAppsUseCase,
            restrictionRepository: restrictionRepository
        )
    }

    func makeInterventionViewModel() -> InterventionViewModel {
        InterventionViewModel(
            startInterventionUseCase: startInterventionUseCase,
            sessionRepository: sessionRepository
        )
    }

    func makeMelodyGateViewModel() -> MelodyGateViewModel {
        MelodyGateViewModel(
            audioRepository: audioRepository,
            completeMelodyGateUseCase: completeMelodyGateUseCase,
            sessionRepository: sessionRepository
        )
    }

    func makeActivityViewModel() -> ActivityViewModel {
        ActivityViewModel(sessionRepository: sessionRepository)
    }

    func makeUnlockViewModel(appToken: String) -> UnlockViewModel {
        UnlockViewModel(
            appToken: appToken,
            grantUnlockTimeUseCase: grantUnlockTimeUseCase
        )
    }

    func makeProfileViewModel() -> ProfileViewModel {
        ProfileViewModel(authRepository: authRepository)
    }

    func makeUsernameSetupViewModel(uid: String) -> UsernameSetupViewModel {
        UsernameSetupViewModel(
            uid: uid,
            checkUseCase: checkUsernameAvailabilityUseCase,
            setUseCase: setUsernameUseCase
        )
    }
}

// MARK: - KeychainSessionStorage

final class KeychainSessionStorage: Sendable {

    private static let sessionKey = "com.melotox.userSession"
    private let keychain: KeychainService

    init(keychain: KeychainService) {
        self.keychain = keychain
    }

    func saveUser(_ dto: UserDTO) throws {
        let data = try JSONEncoder().encode(dto)
        try keychain.save(key: Self.sessionKey, data: data)
    }

    func loadUser() throws -> UserDTO? {
        guard let data = try keychain.load(key: Self.sessionKey) else { return nil }
        return try JSONDecoder().decode(UserDTO.self, from: data)
    }

    func clear() throws {
        try keychain.delete(key: Self.sessionKey)
    }
}
