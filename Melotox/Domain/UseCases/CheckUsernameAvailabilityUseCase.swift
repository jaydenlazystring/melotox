import Foundation

// MARK: - CheckUsernameAvailabilityUseCase

/// Validates a candidate handle's format and, if valid, checks availability.
struct CheckUsernameAvailabilityUseCase: Sendable {

    enum Result: Sendable, Equatable {
        case available(canonical: String)
        case invalid(UsernameValidation)
        case taken
    }

    private let repository: any UserProfileRepository

    init(repository: any UserProfileRepository) {
        self.repository = repository
    }

    func execute(_ raw: String) async throws -> Result {
        let validation = UsernameValidator.validate(raw)
        guard case .valid(let canonical) = validation else {
            return .invalid(validation)
        }

        let available = try await repository.isUsernameAvailable(canonical)
        return available ? .available(canonical: canonical) : .taken
    }
}
