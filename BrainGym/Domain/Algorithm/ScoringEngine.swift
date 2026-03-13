import Foundation

// MARK: - ScoringEngine

/// Pure deterministic algorithm: given ContextSignals → returns the winning ChallengeType or nil.
/// No side-effects, no I/O, fully unit-testable.
struct ScoringEngine {

    // MARK: - Public API

    /// Returns the recommended ChallengeType for the given context, or nil when
    /// a challenge must be blocked (e.g. inMeeting / driving without audio-only).
    func recommendedType(for signals: ContextSignals) -> ChallengeType? {
        // ── 1. HARD BLOCKS ──────────────────────────────────────────────────
        if signals.calendarStatus == .inMeeting {
            return nil
        }
        // Driving: only audio-capable challenges are safe — handled via
        // allowedTypes filtering further down. We don't block outright.

        // ── 2. PRIORITY OVERRIDES (short-circuit scoring) ───────────────────
        if signals.calendarStatus == .meetingSoon {
            return .quickReflect
        }
        // postMeeting is handled inside scoring (memory +8 boost), not as override.

        // HRV emergency gates
        if let hrv = signals.hrv, hrv < 20 {
            return .recovery
        }

        // Sleep emergency gate
        if let sleep = signals.sleepHours, sleep < 5 {
            // Return recovery by default; sensory is also OK but recovery takes precedence
            return .recovery
        }

        // ── 3. ALLOWED-TYPE FILTER ──────────────────────────────────────────
        let allowed = allowedTypes(for: signals)
        guard !allowed.isEmpty else { return nil }

        // ── 4. FULL SCORING ──────────────────────────────────────────────────
        var scores = initialScores()
        scores = applyAIUsage(scores: scores, signals: signals)
        scores = applyChronotype(scores: scores, signals: signals)
        scores = applyExercise(scores: scores, signals: signals)
        scores = applyMotion(scores: scores, signals: signals)
        scores = applyLocation(scores: scores, signals: signals)
        scores = applyDemographics(scores: scores, signals: signals)
        scores = applyHealth(scores: scores, signals: signals)
        scores = applyBluetooth(scores: scores, signals: signals)
        scores = applyCognitiveBaseline(scores: scores, signals: signals)
        scores = applyLifeStage(scores: scores, signals: signals)
        scores = applyPostMeetingBoost(scores: scores, signals: signals)

        // ── 5. PICK WINNER from allowed types ───────────────────────────────
        let winner = allowed
            .max { scores[$0, default: 0] < scores[$1, default: 0] }

        return winner
    }

    // MARK: - Allowed Types

    /// Returns the set of ChallengeType values that are safe/appropriate
    /// given hard constraints (driving safety, HRV gates, sleep gates).
    func allowedTypes(for signals: ContextSignals) -> Set<ChallengeType> {
        var types = Set(ChallengeType.allCases)

        // Driving: only audio-only types are safe
        if signals.motionState == .driving {
            // memory (audio) and sensory are OK; deep cognitive is unsafe
            types = [.memory, .sensory, .recovery, .quickReflect]
        }

        // Heart rate: very high HR means active exercise — physicalMind only
        if let hr = signals.heartRate, hr > 140 {
            return [.physicalMind]
        }

        // HRV gates
        if let hrv = signals.hrv {
            switch hrv {
            case ..<20:
                types = types.intersection([.recovery])
            case 20..<30:
                types = types.intersection([.sensory, .recovery])
            case 30..<50:
                // All light challenges OK — remove only deepCognitive and criticalThinking
                types = types.subtracting([.deepCognitive, .criticalThinking])
            case 50..<70:
                // deepCognitive OK, criticalThinking still blocked
                types = types.subtracting([.criticalThinking])
            default: // >= 70
                break // all types allowed
            }
        }

        // Sleep gates
        if let sleep = signals.sleepHours {
            switch sleep {
            case ..<5:
                types = types.intersection([.recovery, .sensory])
            case 5..<6:
                types = types.subtracting([.deepCognitive, .criticalThinking])
            default:
                break
            }
        }

        return types
    }

    // MARK: - Scoring Steps

    private func initialScores() -> [ChallengeType: Double] {
        // All buckets start at 0
        Dictionary(uniqueKeysWithValues: ChallengeType.allCases.map { ($0, 0.0) })
    }

    // ── AI Usage (MIT 2025, Gerlich 2025) ─────────────────────────────────
    private func applyAIUsage(scores: [ChallengeType: Double], signals: ContextSignals) -> [ChallengeType: Double] {
        var s = scores
        let usage = signals.aiUsageToday

        if usage >= 5 {
            s[.criticalThinking, default: 0] += 7
            s[.deepCognitive, default: 0] += 5
        }
        if usage >= 3 {
            s[.memory, default: 0] += 4
        }
        if usage >= 1 {
            s[.quickReflect, default: 0] += 2
        }
        if signals.consecutiveDaysWithAI >= 7 {
            s[.criticalThinking, default: 0] += 5
        }
        return s
    }

    // ── Chronotype × Hour (Facer-Childs 2018) ─────────────────────────────
    private func applyChronotype(scores: [ChallengeType: Double], signals: ContextSignals) -> [ChallengeType: Double] {
        var s = scores
        let h = signals.hour

        switch signals.chronotype {
        case .early:
            if (9...12).contains(h) {
                s[.deepCognitive, default: 0] += 6
            }
            if (13...15).contains(h) {
                s[.quickReflect, default: 0] += 4
                s[.deepCognitive, default: 0] -= 3
            }
        case .mid:
            if (10...13).contains(h) {
                s[.deepCognitive, default: 0] += 5
            }
            if (17...19).contains(h) {
                s[.creative, default: 0] += 3
            }
        case .late:
            if (14...20).contains(h) {
                s[.deepCognitive, default: 0] += 6
            }
            if (6...10).contains(h) {
                s[.deepCognitive, default: 0] -= 4
            }
        }

        // Universal afternoon dip
        if (13...15).contains(h) {
            s[.quickReflect, default: 0] += 4
            s[.deepCognitive, default: 0] -= 3
        }

        return s
    }

    // ── Post-exercise golden window (Nature Comms Psych 2024) ─────────────
    private func applyExercise(scores: [ChallengeType: Double], signals: ContextSignals) -> [ChallengeType: Double] {
        var s = scores
        if let mins = signals.lastExerciseMinutes, (20...60).contains(mins) {
            s[.memory, default: 0] += 6
            s[.criticalThinking, default: 0] += 4
        }
        // heartRate > 140 handled in allowedTypes (physicalMind-only)
        return s
    }

    // ── Motion ────────────────────────────────────────────────────────────
    private func applyMotion(scores: [ChallengeType: Double], signals: ContextSignals) -> [ChallengeType: Double] {
        var s = scores
        switch signals.motionState {
        case .stationary:
            s[.deepCognitive, default: 0] += 4
            s[.memory, default: 0] += 2
        case .walking:
            s[.sensory, default: 0] += 3
            s[.creative, default: 0] += 2
            s[.physicalMind, default: 0] += 3
        case .running:
            s[.physicalMind, default: 0] += 5
            s[.deepCognitive, default: 0] -= 5
        case .driving:
            s[.memory, default: 0] += 3      // audio recall
            s[.sensory, default: 0] += 2
            s[.deepCognitive, default: 0] -= 10
        }
        return s
    }

    // ── Location ──────────────────────────────────────────────────────────
    private func applyLocation(scores: [ChallengeType: Double], signals: ContextSignals) -> [ChallengeType: Double] {
        var s = scores
        switch signals.location {
        case .work:
            if signals.motionState == .stationary {
                s[.deepCognitive, default: 0] += 4
            }
        case .gym:
            s[.physicalMind, default: 0] += 5
        case .park:
            s[.sensory, default: 0] += 4
            s[.creative, default: 0] += 2
        case .cafe:
            s[.social, default: 0] += 2
            s[.sensory, default: 0] += 2
        case .restaurant:
            s[.social, default: 0] += 3
        case .commuteCar:
            s[.social, default: 0] += 3
        case .commuteTransit:
            s[.social, default: 0] += 3
        case .home, .unknown:
            break
        }
        return s
    }

    // ── Demographics (Gerlich 2025) ────────────────────────────────────────
    private func applyDemographics(scores: [ChallengeType: Double], signals: ContextSignals) -> [ChallengeType: Double] {
        var s = scores
        let age = signals.age

        // Age multipliers
        if (17...25).contains(age) {
            s[.criticalThinking, default: 0] *= 1.5
        } else if (26...45).contains(age) {
            s[.deepCognitive, default: 0] *= 1.2
        } else if age > 45 {
            s[.memory, default: 0] *= 1.3
        }

        // Profession multipliers
        switch signals.profession {
        case .tech:
            s[.criticalThinking, default: 0] *= 1.3
        case .creative:
            s[.criticalThinking, default: 0] *= 1.2  // note: spec says criticalThinking ×1.2 for creative
        case .finance:
            s[.deepCognitive, default: 0] *= 1.15
        default:
            break
        }

        // No university degree
        if !signals.hasUniversityDegree {
            s[.quickReflect, default: 0] += 2
        }

        return s
    }

    // ── Health signals ─────────────────────────────────────────────────────
    private func applyHealth(scores: [ChallengeType: Double], signals: ContextSignals) -> [ChallengeType: Double] {
        var s = scores

        if let hr = signals.heartRate {
            if hr > 100 {
                s[.deepCognitive, default: 0] -= 4
                s[.sensory, default: 0] += 3
            }
        }

        if let hrv = signals.hrv {
            if hrv < 30 {
                s[.emotional, default: 0] += 3
                s[.deepCognitive, default: 0] -= 2
            }
        }

        if let sleep = signals.sleepHours {
            switch sleep {
            case ..<6:
                s[.deepCognitive, default: 0] -= 4
                s[.quickReflect, default: 0] += 3
            case 6..<7:
                // reduce intensity by -2 is expressed as slight score reduction on demanding types
                s[.deepCognitive, default: 0] -= 2
                s[.criticalThinking, default: 0] -= 2
            case 8...:
                s[.quickReflect, default: 0] += 1
                s[.sensory, default: 0] += 1
            default:
                break // 7–8h optimal, no adjustment
            }
        }

        if let steps = signals.steps {
            if steps < 2000 {
                s[.physicalMind, default: 0] += 3
            } else if steps > 8000 {
                s[.physicalMind, default: 0] -= 2
            }
        }

        return s
    }

    // ── Bluetooth ─────────────────────────────────────────────────────────
    private func applyBluetooth(scores: [ChallengeType: Double], signals: ContextSignals) -> [ChallengeType: Double] {
        var s = scores
        let bt = signals.bluetoothDevices

        if bt.contains(.earphones) && signals.motionState != .driving {
            s[.memory, default: 0] += 2      // audio challenge
        }
        if bt.contains(.watch) {
            s[.physicalMind, default: 0] += 1
        }
        if bt.contains(.car) {
            s[.deepCognitive, default: 0] -= 5
            s[.sensory, default: 0] += 2
        }
        return s
    }

    // ── Cognitive baseline ─────────────────────────────────────────────────
    private func applyCognitiveBaseline(scores: [ChallengeType: Double], signals: ContextSignals) -> [ChallengeType: Double] {
        var s = scores
        if let cog = signals.cognitiveScore {
            if cog < 40 {
                s[.memory, default: 0] += 4
            } else if cog > 75 {
                s[.deepCognitive, default: 0] += 3
            }
        }
        return s
    }

    // ── Life stage ────────────────────────────────────────────────────────
    private func applyLifeStage(scores: [ChallengeType: Double], signals: ContextSignals) -> [ChallengeType: Double] {
        var s = scores
        if signals.hasKids {
            s[.quickReflect, default: 0] += 2
            s[.emotional, default: 0] += 2
            s[.deepCognitive, default: 0] -= 1
        }
        return s
    }

    // ── Post-meeting memory consolidation window (MIT 2025) ───────────────
    private func applyPostMeetingBoost(scores: [ChallengeType: Double], signals: ContextSignals) -> [ChallengeType: Double] {
        var s = scores
        if signals.calendarStatus == .postMeeting {
            s[.memory, default: 0] += 8
        }
        return s
    }
}

// MARK: - Dictionary subscript default helper
// (needed so Dictionary<ChallengeType, Double>[key, default: 0] compiles in older toolchains)
extension Dictionary where Key == ChallengeType, Value == Double {
    subscript(key: ChallengeType, default defaultValue: Double) -> Double {
        get { self[key] ?? defaultValue }
        set { self[key] = newValue }
    }
}
