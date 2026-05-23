import Foundation

struct ActivityStats: Sendable {
    let todayUnlocks: Int
    let totalSessions: Int
    let totalDeclined: Int
    let currentStreak: Int
}
