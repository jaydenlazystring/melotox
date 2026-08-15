import Foundation

/// A device-local `UserProfileRepository` used when Firebase isn't configured.
/// Persists user records and username reservations in UserDefaults so the
/// onboarding/username flow is fully testable in the Simulator. Once Firebase
/// is wired up, `FirebaseUserProfileRepository` replaces this (see DI).
final class LocalUserProfileRepository: UserProfileRepository, @unchecked Sendable {

    private let defaults: UserDefaults
    private let usersKey = "com.melotox.local.users"          // [uid: UserDTO]
    private let reservationsKey = "com.melotox.local.usernames" // [handleLower: uid]

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    // MARK: - UserProfileRepository

    func fetchProfile(uid: String) async throws -> User? {
        loadUsers()[uid]?.toEntity()
    }

    func upsertUser(_ user: User) async throws {
        var users = loadUsers()
        users[user.id] = UserDTO.fromEntity(user)
        saveUsers(users)
    }

    func isUsernameAvailable(_ canonical: String) async throws -> Bool {
        loadReservations()[canonical] == nil
    }

    func setUsername(_ canonical: String, for uid: String) async throws -> User {
        var reservations = loadReservations()
        if let owner = reservations[canonical], owner != uid {
            throw UserProfileError.usernameTaken
        }

        // Release any previous handle owned by this user.
        for (handle, owner) in reservations where owner == uid {
            reservations[handle] = nil
        }
        reservations[canonical] = uid
        saveReservations(reservations)

        var users = loadUsers()
        guard var dto = users[uid] else { throw UserProfileError.notAuthenticated }
        dto.username = canonical
        users[uid] = dto
        saveUsers(users)
        return dto.toEntity()
    }

    // MARK: - Persistence

    private func loadUsers() -> [String: UserDTO] {
        guard let data = defaults.data(forKey: usersKey),
              let map = try? JSONDecoder().decode([String: UserDTO].self, from: data)
        else { return [:] }
        return map
    }

    private func saveUsers(_ users: [String: UserDTO]) {
        if let data = try? JSONEncoder().encode(users) {
            defaults.set(data, forKey: usersKey)
        }
    }

    private func loadReservations() -> [String: String] {
        defaults.dictionary(forKey: reservationsKey) as? [String: String] ?? [:]
    }

    private func saveReservations(_ reservations: [String: String]) {
        defaults.set(reservations, forKey: reservationsKey)
    }
}
