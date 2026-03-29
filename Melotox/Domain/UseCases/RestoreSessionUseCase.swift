import Foundation

struct RestoreSessionUseCase: Sendable {
    private let authRepository: any AuthRepository

    init(authRepository: any AuthRepository) {
        self.authRepository = authRepository
    }

    func execute() async throws -> User? {
        try await authRepository.restoreSession()
    }
}
