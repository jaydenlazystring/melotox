import Foundation

@MainActor
final class UsernameSetupViewModel: ObservableObject {

    // MARK: - Field State

    enum FieldState: Equatable {
        case idle
        case checking
        case available
        case invalid(String)
        case taken

        var isAvailable: Bool { self == .available }
    }

    // MARK: - Published State

    @Published var username: String = "" {
        didSet { onUsernameChanged() }
    }
    @Published private(set) var state: FieldState = .idle
    @Published private(set) var isSubmitting = false
    @Published var errorMessage: String?
    @Published private(set) var didComplete = false
    @Published private(set) var completedUser: User?

    var canSubmit: Bool { state.isAvailable && !isSubmitting }

    // MARK: - Dependencies

    private let uid: String
    private let checkUseCase: CheckUsernameAvailabilityUseCase
    private let setUseCase: SetUsernameUseCase
    private var debounceTask: Task<Void, Never>?

    // MARK: - Init

    init(
        uid: String,
        checkUseCase: CheckUsernameAvailabilityUseCase,
        setUseCase: SetUsernameUseCase
    ) {
        self.uid = uid
        self.checkUseCase = checkUseCase
        self.setUseCase = setUseCase
    }

    // MARK: - Actions

    private func onUsernameChanged() {
        debounceTask?.cancel()
        let raw = username

        guard !raw.trimmingCharacters(in: .whitespaces).isEmpty else {
            state = .idle
            return
        }

        // Immediate local validation for responsive feedback.
        let validation = UsernameValidator.validate(raw)
        guard validation.isValid else {
            state = .invalid(validation.message ?? "Invalid username")
            return
        }

        state = .checking
        debounceTask = Task { [weak self] in
            try? await Task.sleep(nanoseconds: 400_000_000)
            guard let self, !Task.isCancelled else { return }
            await self.performCheck(raw)
        }
    }

    private func performCheck(_ raw: String) async {
        do {
            let result = try await checkUseCase.execute(raw)
            guard raw == username else { return } // input changed mid-flight
            switch result {
            case .available:
                state = .available
            case .invalid(let validation):
                state = .invalid(validation.message ?? "Invalid username")
            case .taken:
                state = .taken
            }
        } catch {
            guard raw == username else { return }
            state = .invalid("Couldn't check availability")
        }
    }

    func submit() {
        guard canSubmit else { return }
        isSubmitting = true
        errorMessage = nil

        Task {
            do {
                let user = try await setUseCase.execute(rawUsername: username, for: uid)
                completedUser = user
                didComplete = true
            } catch SetUsernameUseCase.SetUsernameError.taken {
                state = .taken
            } catch {
                errorMessage = "Couldn't set your username. Please try again."
            }
            isSubmitting = false
        }
    }
}
