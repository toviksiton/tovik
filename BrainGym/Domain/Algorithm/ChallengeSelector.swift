import Foundation

// MARK: - ChallengeSelector

/// Selects a ChallengeTemplate from the bank for a given type, avoiding
/// recently served challenges (recency-avoidance window = 3 challenges per type).
struct ChallengeSelector {

    private let recencyWindow = 3

    // MARK: - Public API

    /// Returns a Challenge for the given type, avoiding recent prompts.
    /// - Parameters:
    ///   - type: The winning ChallengeType from ScoringEngine.
    ///   - recentIDs: Array of recently served challenge IDs (newest first).
    func select(type: ChallengeType, recentIDs: [UUID]) -> ChallengeTemplate? {
        let pool = ChallengeBank.templates(for: type)
        guard !pool.isEmpty else { return nil }

        // IDs to avoid (most recent N per type)
        let avoidSet = Set(recentIDs.prefix(recencyWindow))

        // Prefer templates not recently shown
        let fresh = pool.filter { !avoidSet.contains($0.id) }
        let candidates = fresh.isEmpty ? pool : fresh  // fallback: use full pool

        return candidates.randomElement()
    }

    /// Full pipeline: signals → type → template → Challenge
    func selectChallenge(
        signals: ContextSignals,
        recentIDs: [UUID] = []
    ) -> Challenge? {
        let engine = ScoringEngine()
        guard let type = engine.recommendedType(for: signals) else { return nil }
        guard let template = select(type: type, recentIDs: recentIDs) else { return nil }
        return template.toChallenge()
    }
}

// MARK: - ChallengeTemplate ID helper
// Templates are value types; give each a stable identity based on type+prompt hash.
extension ChallengeTemplate {
    var id: UUID {
        // Deterministic UUID from a hash of type+prompt so recency tracking works
        // across app launches without persistence.
        let hash = "\(type.rawValue):\(prompt)".stableUUID
        return hash
    }
}

private extension String {
    /// Produces a deterministic UUID v5-like value from a string.
    var stableUUID: UUID {
        var result = [UInt8](repeating: 0, count: 16)
        let bytes = Array(utf8)
        for (i, byte) in bytes.enumerated() {
            result[i % 16] ^= byte
        }
        // Set version 4 bits to make it a valid UUID structure
        result[6] = (result[6] & 0x0F) | 0x40
        result[8] = (result[8] & 0x3F) | 0x80
        return UUID(uuid: (
            result[0], result[1], result[2],  result[3],
            result[4], result[5], result[6],  result[7],
            result[8], result[9], result[10], result[11],
            result[12],result[13],result[14], result[15]
        ))
    }
}
