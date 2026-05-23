import Foundation

@MainActor
final class ActivityViewModel: ObservableObject {

    @Published var stats = ActivityStats(todayUnlocks: 0, totalSessions: 0, totalDeclined: 0, currentStreak: 0)
    @Published var isLoading = false

    private let sessionRepository: any SessionRepository

    init(sessionRepository: any SessionRepository) {
        self.sessionRepository = sessionRepository
    }

    func loadStats() {
        Task {
            isLoading = true
            do {
                let history = try await sessionRepository.loadActivityHistory()
                stats = computeStats(from: history)
            } catch {
                // Keep defaults
            }
            isLoading = false
        }
    }

    private func computeStats(from records: [ActivityRecord]) -> ActivityStats {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())

        let todayUnlocks = records.filter {
            $0.type == .completed && calendar.isDate($0.date, inSameDayAs: today)
        }.count

        let totalSessions = records.filter { $0.type == .completed }.count
        let totalDeclined = records.filter { $0.type == .declined }.count

        // Streak: count consecutive days with at least one completed session, going backwards from today
        let completedDates = Set(
            records
                .filter { $0.type == .completed }
                .map { calendar.startOfDay(for: $0.date) }
        )

        var streak = 0
        var checkDate = today
        while completedDates.contains(checkDate) {
            streak += 1
            guard let previousDay = calendar.date(byAdding: .day, value: -1, to: checkDate) else { break }
            checkDate = previousDay
        }

        return ActivityStats(
            todayUnlocks: todayUnlocks,
            totalSessions: totalSessions,
            totalDeclined: totalDeclined,
            currentStreak: streak
        )
    }
}
