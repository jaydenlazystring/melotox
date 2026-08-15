import Foundation

#if canImport(FirebaseFirestore)
import FirebaseFirestore

/// Firestore-backed source of truth for user records and username uniqueness.
///
/// Data model:
///   users/{uid}            → UserProfileFirestoreDTO
///   usernames/{handleLower} → { uid, createdAt }  (atomic uniqueness reservation)
final class FirebaseUserProfileRepository: UserProfileRepository, @unchecked Sendable {

    private let db = Firestore.firestore()
    private let usersCollection = "users"
    private let usernamesCollection = "usernames"

    // Sentinel used to distinguish a "handle taken" transaction failure.
    private static let takenErrorDomain = "com.melotox.username"
    private static let takenErrorCode = 409

    // MARK: - UserProfileRepository

    func fetchProfile(uid: String) async throws -> User? {
        let snap = try await db.collection(usersCollection).document(uid).getDocument()
        guard snap.exists else { return nil }
        return try snap.data(as: UserProfileFirestoreDTO.self).toEntity()
    }

    func upsertUser(_ user: User) async throws {
        let ref = db.collection(usersCollection).document(user.id)
        let existing = try await ref.getDocument()
        // Preserve an already-chosen username; only seed the base record when new.
        if existing.exists { return }
        let dto = UserProfileFirestoreDTO.fromEntity(user, updatedAt: Date())
        try ref.setData(from: dto, merge: true)
    }

    func isUsernameAvailable(_ canonical: String) async throws -> Bool {
        let snap = try await db.collection(usernamesCollection).document(canonical).getDocument()
        return !snap.exists
    }

    func setUsername(_ canonical: String, for uid: String) async throws -> User {
        let userRef = db.collection(usersCollection).document(uid)
        let handleRef = db.collection(usernamesCollection).document(canonical)

        do {
            _ = try await db.runTransaction { transaction, errorPointer -> Any? in
                do {
                    let handleSnap = try transaction.getDocument(handleRef)
                    if handleSnap.exists {
                        errorPointer?.pointee = NSError(
                            domain: Self.takenErrorDomain,
                            code: Self.takenErrorCode
                        )
                        return nil
                    }

                    // Release a previously reserved handle owned by this user.
                    let userSnap = try transaction.getDocument(userRef)
                    if let oldHandle = userSnap.data()?["usernameLower"] as? String,
                       oldHandle != canonical {
                        let oldRef = self.db.collection(self.usernamesCollection).document(oldHandle)
                        transaction.deleteDocument(oldRef)
                    }

                    transaction.setData(
                        ["uid": uid, "createdAt": FieldValue.serverTimestamp()],
                        forDocument: handleRef
                    )
                    transaction.setData(
                        [
                            "username": canonical,
                            "usernameLower": canonical,
                            "updatedAt": FieldValue.serverTimestamp(),
                        ],
                        forDocument: userRef,
                        merge: true
                    )
                    return nil
                } catch {
                    errorPointer?.pointee = error as NSError
                    return nil
                }
            }
        } catch let error as NSError where error.domain == Self.takenErrorDomain {
            throw UserProfileError.usernameTaken
        }

        guard let user = try await fetchProfile(uid: uid) else {
            throw UserProfileError.notAuthenticated
        }
        return user
    }
}
#endif
