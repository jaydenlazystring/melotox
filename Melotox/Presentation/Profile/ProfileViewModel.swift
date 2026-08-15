import Foundation

@MainActor
final class ProfileViewModel: ObservableObject {

    @Published var displayName: String = ""
    @Published var username: String = ""
    @Published var email: String = ""
    @Published var providerName: String = ""
    @Published var joinedDate: String = ""
    @Published var didSignOut = false

    private let authRepository: any AuthRepository

    init(authRepository: any AuthRepository) {
        self.authRepository = authRepository
    }

    func loadUser(_ user: User) {
        displayName = user.displayName
        username = user.username ?? user.displayName
        email = user.email
        providerName = user.provider == .apple ? "Apple" : "Google"

        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        joinedDate = formatter.string(from: user.createdAt)
    }

    func signOut() {
        Task {
            try? await authRepository.signOut()
            didSignOut = true
        }
    }
}
