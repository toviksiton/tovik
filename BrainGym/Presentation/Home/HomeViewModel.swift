import Foundation
import SwiftData

// MARK: - HomeViewModel

@Observable
final class HomeViewModel {
    var currentChallenge: Challenge?
    var showOverlay = false
    var showActive = false
    var showComplete = false
    var streak = 0
    var latestCognitiveScore: Int = 0
    var recentChallenges: [Challenge] = []
    var weeklyScores: [Int] = []           // last 7 cognitive scores

    private var contextEngine: ContextEngine
    private var recentIDs: [UUID] = []

    init(contextEngine: ContextEngine) {
        self.contextEngine = contextEngine
    }

    // MARK: - Actions

    func requestChallenge(cognitiveScore: Int? = nil) {
        let challenge = contextEngine.selectChallenge(
            cognitiveScore: cognitiveScore,
            recentIDs: recentIDs
        )
        currentChallenge = challenge
        if challenge != nil {
            haptic(.medium)
            showOverlay = true
        }
    }

    func beginChallenge() {
        showOverlay = false
        showActive = true
    }

    func skipChallenge() {
        if let ch = currentChallenge {
            ch.skipped = true
            appendToRecent(ch)
        }
        showOverlay = false
        showActive = false
        currentChallenge = nil
    }

    func completeChallenge() {
        if let ch = currentChallenge {
            ch.completedAt = Date()
            appendToRecent(ch)
            streak += 1
        }
        showActive = false
        showComplete = true
    }

    func dismissComplete() {
        showComplete = false
        currentChallenge = nil
    }

    // MARK: - Helpers

    private func appendToRecent(_ challenge: Challenge) {
        recentIDs.insert(challenge.id, at: 0)
        if recentIDs.count > 10 { recentIDs = Array(recentIDs.prefix(10)) }
        recentChallenges.insert(challenge, at: 0)
        if recentChallenges.count > 3 { recentChallenges = Array(recentChallenges.prefix(3)) }
    }

    func loadData(challenges: [Challenge], scores: [CognitiveScore]) {
        recentChallenges = Array(challenges.filter { $0.completedAt != nil }
            .sorted { ($0.completedAt ?? .distantPast) > ($1.completedAt ?? .distantPast) }
            .prefix(3))

        recentIDs = recentChallenges.map { $0.id }

        streak = computeStreak(from: challenges)

        let sortedScores = scores.sorted { $0.recordedAt > $1.recordedAt }
        latestCognitiveScore = sortedScores.first?.overallInt ?? 0
        weeklyScores = sortedScores.prefix(7).map { $0.overallInt }.reversed()
    }

    private func computeStreak(from challenges: [Challenge]) -> Int {
        let completed = challenges
            .compactMap { $0.completedAt }
            .sorted(by: >)
        guard !completed.isEmpty else { return 0 }

        var streak = 1
        var prev = Calendar.current.startOfDay(for: completed[0])
        for date in completed.dropFirst() {
            let day = Calendar.current.startOfDay(for: date)
            let diff = Calendar.current.dateComponents([.day], from: day, to: prev).day ?? 0
            if diff == 1 { streak += 1; prev = day }
            else if diff > 1 { break }
        }
        return streak
    }
}
