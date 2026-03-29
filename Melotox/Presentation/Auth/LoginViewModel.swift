import Foundation

@MainActor
final class LoginViewModel: ObservableObject {

    // MARK: - Published State

    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var isAuthenticated = false
    @Published private(set) var user: User?

    // MARK: - Dependencies

    private let signInWithGoogleUseCase: SignInWithGoogleUseCase
    private let signInWithAppleUseCase: SignInWithAppleUseCase

    // MARK: - Init

    init(
        signInWithGoogleUseCase: SignInWithGoogleUseCase,
        signInWithAppleUseCase: SignInWithAppleUseCase
    ) {
        self.signInWithGoogleUseCase = signInWithGoogleUseCase
        self.signInWithAppleUseCase = signInWithAppleUseCase
    }

    // MARK: - Actions

    func signInWithGoogle() {
        Task {
            isLoading = true
            errorMessage = nil

            do {
                let authenticatedUser = try await signInWithGoogleUseCase.execute()
                user = authenticatedUser
                isAuthenticated = true
            } catch {
                errorMessage = "Google sign-in failed. Please try again."
            }

            isLoading = false
        }
    }

    func signInWithApple() {
        Task {
            isLoading = true
            errorMessage = nil

            do {
                let authenticatedUser = try await signInWithAppleUseCase.execute()
                user = authenticatedUser
                isAuthenticated = true
            } catch {
                errorMessage = "Apple sign-in failed. Please try again."
            }

            isLoading = false
        }
    }
}
