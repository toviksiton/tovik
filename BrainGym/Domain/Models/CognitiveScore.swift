import Foundation
import SwiftData

// MARK: - Individual Test Result

struct TestResult: Codable {
    let score: Double   // 0–100
    let rawData: String // JSON-serialised detail (optional telemetry)
}

// MARK: - CognitiveScore (SwiftData model)

@Model
final class CognitiveScore {
    var id: UUID
    var recordedAt: Date

    // Sub-scores (0–100 each)
    var reactionTimeScore: Double
    var nBackScore: Double
    var stroopScore: Double
    var spatialMemoryScore: Double

    /// Average of all four tests
    var overall: Double {
        (reactionTimeScore + nBackScore + stroopScore + spatialMemoryScore) / 4.0
    }

    /// Clamped Int for algorithm use
    var overallInt: Int { Int(overall.rounded()) }

    init(
        id: UUID = UUID(),
        recordedAt: Date = Date(),
        reactionTimeScore: Double,
        nBackScore: Double,
        stroopScore: Double,
        spatialMemoryScore: Double
    ) {
        self.id = id
        self.recordedAt = recordedAt
        self.reactionTimeScore = reactionTimeScore
        self.nBackScore = nBackScore
        self.stroopScore = stroopScore
        self.spatialMemoryScore = spatialMemoryScore
    }
}
