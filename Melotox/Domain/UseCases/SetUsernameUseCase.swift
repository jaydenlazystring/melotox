import Foundation

// MARK: - SetUsernameUseCase

/// Re-validates a handle and atomically claims it for the user. The reservation
/// inside the repository is the true race guard — this may still throw
/// `UserProfileError.usernameTaken` even after an availability check passed.
struct SetUsernameUseCase: Sendable {

    enum SetUsernameError: Error, Sendable, Equatable {
        case invalid(UsernameValidation)
        case taken
        case failed
    }

    private let repository: any UserProfileRepository

    init(repository: any UserProfileRepository) {
        self.repository = repository
    }

    func execute(rawUsername: String, for uid: String) async throws -> User {
        let validation = UsernameValidator.validate(rawUsername)
        guard case .valid(let canonical) = validation else {
            throw SetUsernameError.invalid(validation)
        }

        do {
            return try await repository.setUsername(canonical, for: uid)
        } catch UserProfileError.usernameTaken {
            throw SetUsernameError.taken
        } catch {
            throw SetUsernameError.failed
        }
    }
}
