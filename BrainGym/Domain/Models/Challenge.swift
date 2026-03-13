import Foundation
import SwiftData

// MARK: - Challenge (domain model, SwiftData-backed)

@Model
final class Challenge {
    var id: UUID
    var type: ChallengeType
    var prompt: String          // Hebrew
    var durationSeconds: Int    // 30 / 45 / 60 / 90 / 120
    var intensity: Int          // 1–10
    var researchNote: String?
    var audioOnly: Bool
    var requiresStationary: Bool
    var completedAt: Date?
    var skipped: Bool

    init(
        id: UUID = UUID(),
        type: ChallengeType,
        prompt: String,
        durationSeconds: Int,
        intensity: Int,
        researchNote: String? = nil,
        audioOnly: Bool = false,
        requiresStationary: Bool = false,
        completedAt: Date? = nil,
        skipped: Bool = false
    ) {
        self.id = id
        self.type = type
        self.prompt = prompt
        self.durationSeconds = durationSeconds
        self.intensity = intensity
        self.researchNote = researchNote
        self.audioOnly = audioOnly
        self.requiresStationary = requiresStationary
        self.completedAt = completedAt
        self.skipped = skipped
    }
}

// MARK: - ChallengeTemplate (static definition, not persisted)

struct ChallengeTemplate {
    let type: ChallengeType
    let prompt: String
    let durationSeconds: Int
    let intensity: Int
    let researchNote: String?
    let audioOnly: Bool
    let requiresStationary: Bool

    init(
        type: ChallengeType,
        prompt: String,
        durationSeconds: Int,
        intensity: Int,
        researchNote: String? = nil,
        audioOnly: Bool = false,
        requiresStationary: Bool = false
    ) {
        self.type = type
        self.prompt = prompt
        self.durationSeconds = durationSeconds
        self.intensity = intensity
        self.researchNote = researchNote
        self.audioOnly = audioOnly
        self.requiresStationary = requiresStationary
    }

    func toChallenge() -> Challenge {
        Challenge(
            type: type,
            prompt: prompt,
            durationSeconds: durationSeconds,
            intensity: intensity,
            researchNote: researchNote,
            audioOnly: audioOnly,
            requiresStationary: requiresStationary
        )
    }
}
