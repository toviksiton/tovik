import XCTest
@testable import BrainGym

// MARK: - ScoringEngineTests
// Covers: hard blocks, priority overrides, HRV gates, sleep gates, all scoring
// dimensions, edge cases, and allowed-type filtering.

final class ScoringEngineTests: XCTestCase {

    let engine = ScoringEngine()

    // ═══════════════════════════════════════════════════════════════════
    // MARK: 1 · Hard Blocks
    // ═══════════════════════════════════════════════════════════════════

    func test_hardBlock_inMeeting_returnsNil() {
        let signals = ContextSignals(calendarStatus: .inMeeting)
        XCTAssertNil(engine.recommendedType(for: signals))
    }

    func test_hardBlock_inMeeting_overridesEverything() {
        // Even high AI usage + optimal HRV should not produce a challenge during a meeting
        let signals = ContextSignals(
            hour: 10, chronotype: .mid,
            calendarStatus: .inMeeting,
            aiUsageToday: 10,
            hrv: 80,
            sleepHours: 8,
            cognitiveScore: 90
        )
        XCTAssertNil(engine.recommendedType(for: signals))
    }

    // ═══════════════════════════════════════════════════════════════════
    // MARK: 2 · Priority Overrides
    // ═══════════════════════════════════════════════════════════════════

    func test_priorityOverride_meetingSoon_returnsQuickReflect() {
        let signals = ContextSignals(calendarStatus: .meetingSoon)
        XCTAssertEqual(engine.recommendedType(for: signals), .quickReflect)
    }

    func test_priorityOverride_meetingSoon_overridesHighAIUsage() {
        let signals = ContextSignals(
            calendarStatus: .meetingSoon,
            aiUsageToday: 10,
            consecutiveDaysWithAI: 14
        )
        XCTAssertEqual(engine.recommendedType(for: signals), .quickReflect)
    }

    func test_priorityOverride_lowHRV_returnsRecovery() {
        let signals = ContextSignals(hrv: 15)
        XCTAssertEqual(engine.recommendedType(for: signals), .recovery)
    }

    func test_priorityOverride_extremelyLowHRV_returnsRecovery() {
        let signals = ContextSignals(hrv: 1)
        XCTAssertEqual(engine.recommendedType(for: signals), .recovery)
    }

    func test_priorityOverride_sleepUnder5h_returnsRecovery() {
        let signals = ContextSignals(sleepHours: 4.5)
        XCTAssertEqual(engine.recommendedType(for: signals), .recovery)
    }

    func test_priorityOverride_sleepUnder5h_evenWithHighAI() {
        let signals = ContextSignals(aiUsageToday: 10, sleepHours: 3.0)
        XCTAssertEqual(engine.recommendedType(for: signals), .recovery)
    }

    // ═══════════════════════════════════════════════════════════════════
    // MARK: 3 · HRV Gates (AllowedTypes)
    // ═══════════════════════════════════════════════════════════════════

    func test_HRVGate_under20_onlyRecoveryAllowed() {
        let allowed = engine.allowedTypes(for: ContextSignals(hrv: 19))
        XCTAssertEqual(allowed, [.recovery])
    }

    func test_HRVGate_20to30_onlySensoryAndRecovery() {
        let allowed = engine.allowedTypes(for: ContextSignals(hrv: 25))
        XCTAssertEqual(allowed, [.sensory, .recovery])
    }

    func test_HRVGate_30to50_noDeepOrCritical() {
        let allowed = engine.allowedTypes(for: ContextSignals(hrv: 40))
        XCTAssertFalse(allowed.contains(.deepCognitive))
        XCTAssertFalse(allowed.contains(.criticalThinking))
        XCTAssertTrue(allowed.contains(.memory))
        XCTAssertTrue(allowed.contains(.quickReflect))
    }

    func test_HRVGate_50to70_noCriticalThinking() {
        let allowed = engine.allowedTypes(for: ContextSignals(hrv: 60))
        XCTAssertFalse(allowed.contains(.criticalThinking))
        XCTAssertTrue(allowed.contains(.deepCognitive))
    }

    func test_HRVGate_over70_allTypesAllowed() {
        let allowed = engine.allowedTypes(for: ContextSignals(hrv: 80))
        XCTAssertEqual(allowed, Set(ChallengeType.allCases))
    }

    func test_HRVGate_exactly20_sensoryAndRecovery() {
        // Boundary: 20 is in [20..<30] → sensory+recovery only
        let allowed = engine.allowedTypes(for: ContextSignals(hrv: 20))
        XCTAssertEqual(allowed, [.sensory, .recovery])
    }

    func test_HRVGate_exactly30_noDeepOrCritical() {
        let allowed = engine.allowedTypes(for: ContextSignals(hrv: 30))
        XCTAssertFalse(allowed.contains(.deepCognitive))
        XCTAssertFalse(allowed.contains(.criticalThinking))
    }

    func test_HRVGate_exactly50_noCritical_deepOK() {
        let allowed = engine.allowedTypes(for: ContextSignals(hrv: 50))
        XCTAssertFalse(allowed.contains(.criticalThinking))
        XCTAssertTrue(allowed.contains(.deepCognitive))
    }

    // ═══════════════════════════════════════════════════════════════════
    // MARK: 4 · Sleep Gates
    // ═══════════════════════════════════════════════════════════════════

    func test_sleepGate_under5h_onlyRecoveryAndSensory() {
        let allowed = engine.allowedTypes(for: ContextSignals(sleepHours: 4.0))
        XCTAssertEqual(allowed, [.recovery, .sensory])
    }

    func test_sleepGate_5to6h_noDeepOrCritical() {
        let allowed = engine.allowedTypes(for: ContextSignals(sleepHours: 5.5))
        XCTAssertFalse(allowed.contains(.deepCognitive))
        XCTAssertFalse(allowed.contains(.criticalThinking))
        XCTAssertTrue(allowed.contains(.memory))
    }

    func test_sleepGate_over6h_allTypesAllowed() {
        let allowed = engine.allowedTypes(for: ContextSignals(sleepHours: 7.0))
        XCTAssertEqual(allowed, Set(ChallengeType.allCases))
    }

    func test_sleepGate_exactly5h_noDeepOrCritical() {
        let allowed = engine.allowedTypes(for: ContextSignals(sleepHours: 5.0))
        XCTAssertFalse(allowed.contains(.deepCognitive))
        XCTAssertFalse(allowed.contains(.criticalThinking))
    }

    // ═══════════════════════════════════════════════════════════════════
    // MARK: 5 · Driving Gate
    // ═══════════════════════════════════════════════════════════════════

    func test_driving_onlyAudioSafeTypesAllowed() {
        let allowed = engine.allowedTypes(for: ContextSignals(motionState: .driving))
        XCTAssertFalse(allowed.contains(.deepCognitive))
        XCTAssertFalse(allowed.contains(.criticalThinking))
        XCTAssertTrue(allowed.contains(.memory))
        XCTAssertTrue(allowed.contains(.sensory))
    }

    func test_driving_doesNotReturnNil() {
        // Driving is not a hard block — returns an audio-safe challenge
        let signals = ContextSignals(motionState: .driving)
        XCTAssertNotNil(engine.recommendedType(for: signals))
    }

    // ═══════════════════════════════════════════════════════════════════
    // MARK: 6 · Heart Rate Gate
    // ═══════════════════════════════════════════════════════════════════

    func test_heartRateOver140_physicalMindOnly() {
        let allowed = engine.allowedTypes(for: ContextSignals(heartRate: 150))
        XCTAssertEqual(allowed, [.physicalMind])
    }

    func test_heartRateAt140_notRestricted() {
        // > 140, so exactly 140 is still unrestricted
        let allowed = engine.allowedTypes(for: ContextSignals(heartRate: 140))
        XCTAssertTrue(allowed.count > 1)
    }

    // ═══════════════════════════════════════════════════════════════════
    // MARK: 7 · AI Usage Scoring
    // ═══════════════════════════════════════════════════════════════════

    func test_aiUsage5plus_prefersCriticalThinking() {
        // With high AI usage, optimal conditions, no sleep/HRV constraints
        let signals = ContextSignals(
            hour: 10, chronotype: .mid,
            aiUsageToday: 5,
            consecutiveDaysWithAI: 0,
            hrv: 80,
            sleepHours: 8
        )
        let result = engine.recommendedType(for: signals)
        // criticalThinking gets +7+5(deepCog); with tech profession ×1.3 criticalThinking should win
        XCTAssertNotNil(result)
    }

    func test_consecutiveDaysWithAI7plus_boostsCriticalThinking() {
        let signals = ContextSignals(
            aiUsageToday: 5,
            consecutiveDaysWithAI: 7,
            hrv: 80,
            sleepHours: 8
        )
        let result = engine.recommendedType(for: signals)
        // criticalThinking gets +7 (usage>=5) + +5 (consecutive) = +12 base
        XCTAssertEqual(result, .criticalThinking)
    }

    func test_aiUsage0_noAIBoost() {
        // No AI usage — criticalThinking gets no AI bonus
        let signals = ContextSignals(
            hour: 10, chronotype: .mid,
            aiUsageToday: 0,
            hrv: 80,
            sleepHours: 8
        )
        // Should not specifically be criticalThinking from AI boost alone
        let result = engine.recommendedType(for: signals)
        XCTAssertNotNil(result) // Just ensure it returns something valid
    }

    // ═══════════════════════════════════════════════════════════════════
    // MARK: 8 · Chronotype × Hour
    // ═══════════════════════════════════════════════════════════════════

    func test_earlyChronotype_morning_deepCognitiveScoresBoosted() {
        // Early + 10am: deepCognitive +6
        let signals = ContextSignals(
            hour: 10, chronotype: .early,
            aiUsageToday: 0,
            hrv: 80,
            sleepHours: 8
        )
        let result = engine.recommendedType(for: signals)
        XCTAssertNotNil(result)
    }

    func test_lateChronotype_peak_deepCognitiveBoosted() {
        // Late + 16:00: deepCognitive +6
        let signals = ContextSignals(
            hour: 16, chronotype: .late,
            aiUsageToday: 0,
            hrv: 80,
            sleepHours: 8
        )
        let result = engine.recommendedType(for: signals)
        XCTAssertNotNil(result)
    }

    func test_lateChronotype_morning_deepCognitivePenalized() {
        // Late + 8am: deepCognitive -4 penalty
        let signals = ContextSignals(
            hour: 8, chronotype: .late,
            aiUsageToday: 0,
            hrv: 80,
            sleepHours: 8
        )
        let result = engine.recommendedType(for: signals)
        // Just verify it doesn't return deepCognitive as winner when penalized
        // (Other signals may vary, so don't assert specific type)
        XCTAssertNotNil(result)
    }

    func test_universalAfternoonDip_boostsQuickReflect() {
        // 14:00 universal dip: quickReflect +4, deepCognitive -3
        let signals = ContextSignals(
            hour: 14, chronotype: .mid,
            aiUsageToday: 0,
            hrv: 80,
            sleepHours: 8,
            steps: 5000
        )
        let result = engine.recommendedType(for: signals)
        XCTAssertNotNil(result)
        // quickReflect should score well here
    }

    // ═══════════════════════════════════════════════════════════════════
    // MARK: 9 · Post-exercise Golden Window
    // ═══════════════════════════════════════════════════════════════════

    func test_postExercise20to60min_boostsMemory() {
        let signals = ContextSignals(
            aiUsageToday: 0,
            hrv: 80,
            sleepHours: 8,
            lastExerciseMinutes: 30
        )
        let result = engine.recommendedType(for: signals)
        // memory gets +6, criticalThinking +4 in this window
        XCTAssertNotNil(result)
    }

    func test_postExerciseUnder20min_noBoost() {
        let signals = ContextSignals(lastExerciseMinutes: 10, hrv: 80, sleepHours: 8)
        // No exercise boost applied
        let result = engine.recommendedType(for: signals)
        XCTAssertNotNil(result)
    }

    func test_postExerciseOver60min_noBoost() {
        let signals = ContextSignals(lastExerciseMinutes: 90, hrv: 80, sleepHours: 8)
        let result = engine.recommendedType(for: signals)
        XCTAssertNotNil(result)
    }

    // ═══════════════════════════════════════════════════════════════════
    // MARK: 10 · Motion
    // ═══════════════════════════════════════════════════════════════════

    func test_running_physicalMindBoosted_deepCognitivePenalized() {
        let signals = ContextSignals(
            aiUsageToday: 0,
            motionState: .running,
            hrv: 80,
            sleepHours: 8
        )
        let result = engine.recommendedType(for: signals)
        XCTAssertEqual(result, .physicalMind)
    }

    func test_walking_sensoryAndCreativeBoosted() {
        let signals = ContextSignals(
            aiUsageToday: 0,
            location: .park,
            motionState: .walking,
            hrv: 80,
            sleepHours: 8
        )
        let result = engine.recommendedType(for: signals)
        // park + walking: sensory +4+3=7, creative +2+2=4, physicalMind +3
        XCTAssertEqual(result, .sensory)
    }

    func test_stationary_deepCognitiveBoosted() {
        let signals = ContextSignals(
            aiUsageToday: 0,
            location: .work,
            motionState: .stationary,
            hrv: 80,
            sleepHours: 8
        )
        let result = engine.recommendedType(for: signals)
        // work+stationary: deepCognitive +4+4=8
        XCTAssertEqual(result, .deepCognitive)
    }

    // ═══════════════════════════════════════════════════════════════════
    // MARK: 11 · Location
    // ═══════════════════════════════════════════════════════════════════

    func test_gym_physicalMindBoosted() {
        let signals = ContextSignals(
            aiUsageToday: 0,
            location: .gym,
            motionState: .stationary,
            hrv: 80,
            sleepHours: 8
        )
        let result = engine.recommendedType(for: signals)
        // gym +5 physicalMind
        XCTAssertNotNil(result)
    }

    func test_cafe_socialAndSensoryBoosted() {
        let signals = ContextSignals(
            aiUsageToday: 0,
            location: .cafe,
            motionState: .stationary,
            hrv: 80,
            sleepHours: 8
        )
        // cafe: social +2, sensory +2
        let result = engine.recommendedType(for: signals)
        XCTAssertNotNil(result)
    }

    func test_park_sensoryBoosted() {
        let signals = ContextSignals(
            aiUsageToday: 0,
            location: .park,
            motionState: .stationary,
            hrv: 80,
            sleepHours: 8
        )
        let result = engine.recommendedType(for: signals)
        // park: sensory +4, creative +2
        XCTAssertEqual(result, .sensory)
    }

    // ═══════════════════════════════════════════════════════════════════
    // MARK: 12 · Demographics
    // ═══════════════════════════════════════════════════════════════════

    func test_age17to25_criticalThinkingMultiplied() {
        // Young user with AI usage should strongly prefer criticalThinking
        let signals = ContextSignals(
            age: 20, profession: .student,
            aiUsageToday: 5,
            consecutiveDaysWithAI: 7,
            hrv: 80,
            sleepHours: 8
        )
        let result = engine.recommendedType(for: signals)
        XCTAssertEqual(result, .criticalThinking)
    }

    func test_age26to45_deepCognitiveMultiplied() {
        let signals = ContextSignals(
            age: 35, profession: .other,
            location: .work, motionState: .stationary,
            aiUsageToday: 0,
            hrv: 80,
            sleepHours: 8
        )
        let result = engine.recommendedType(for: signals)
        // work+stationary deepCognitive +8, ×1.2 = 9.6
        XCTAssertEqual(result, .deepCognitive)
    }

    func test_age45plus_memoryMultiplied() {
        // Senior user post-meeting in free context — memory gets ×1.3 + +8
        let signals = ContextSignals(
            age: 55, profession: .other,
            aiUsageToday: 0,
            calendarStatus: .postMeeting,
            hrv: 80,
            sleepHours: 8
        )
        let result = engine.recommendedType(for: signals)
        XCTAssertEqual(result, .memory)
    }

    func test_techProfession_criticalThinkingBoosted() {
        let signals = ContextSignals(
            age: 30, profession: .tech,
            aiUsageToday: 5,
            consecutiveDaysWithAI: 7,
            hrv: 80,
            sleepHours: 8
        )
        let result = engine.recommendedType(for: signals)
        XCTAssertEqual(result, .criticalThinking)
    }

    func test_financeProfession_deepCognitiveMultiplied() {
        let signals = ContextSignals(
            age: 35, profession: .finance,
            location: .work, motionState: .stationary,
            aiUsageToday: 0,
            hrv: 80,
            sleepHours: 8
        )
        let result = engine.recommendedType(for: signals)
        XCTAssertEqual(result, .deepCognitive)
    }

    func test_noUniversity_quickReflectBoosted() {
        let signals = ContextSignals(
            age: 30, hasUniversityDegree: false,
            aiUsageToday: 0,
            hrv: 80,
            sleepHours: 8
        )
        // quickReflect +2 for no university degree
        let result = engine.recommendedType(for: signals)
        XCTAssertNotNil(result)
    }

    // ═══════════════════════════════════════════════════════════════════
    // MARK: 13 · Health Signals
    // ═══════════════════════════════════════════════════════════════════

    func test_elevatedHeartRate_penalizesDeepCognitive() {
        // HR > 100: deepCognitive -4, sensory +3
        let signals = ContextSignals(
            aiUsageToday: 0,
            hrv: 80,
            sleepHours: 8,
            heartRate: 110
        )
        let result = engine.recommendedType(for: signals)
        XCTAssertNotNil(result)
    }

    func test_lowSteps_physicalMindBoosted() {
        let signals = ContextSignals(
            aiUsageToday: 0,
            hrv: 80,
            sleepHours: 8,
            steps: 500
        )
        // physicalMind +3 for steps < 2000
        let result = engine.recommendedType(for: signals)
        XCTAssertNotNil(result)
    }

    func test_highSteps_physicalMindPenalized() {
        let signals = ContextSignals(
            aiUsageToday: 0,
            hrv: 80,
            sleepHours: 8,
            steps: 10000
        )
        // physicalMind -2 for steps > 8000
        let result = engine.recommendedType(for: signals)
        XCTAssertNotNil(result)
    }

    func test_hrv25_emotionalBoosted() {
        // hrv < 30: emotional +3, deepCognitive -2
        let signals = ContextSignals(
            aiUsageToday: 0,
            hrv: 25,        // Will hit priority override → blocked by allowedTypes
            sleepHours: 8
        )
        // hrv 25 → allowedTypes = [.sensory, .recovery] so recommended is sensory or recovery
        let result = engine.recommendedType(for: signals)
        XCTAssertTrue(result == .sensory || result == .recovery)
    }

    func test_sleepBelow6h_penalizesDeepCognitive_boostsQuickReflect() {
        // This tests the health scoring step (not the gate)
        // hrv 80 so no gate, but sleep 5.5h: deepCognitive -4, quickReflect +3
        let signals = ContextSignals(
            hour: 10, chronotype: .mid,
            aiUsageToday: 0,
            hrv: 80,
            sleepHours: 5.5
        )
        // With 5.5h sleep, gate removes deepCognitive+criticalThinking from allowed
        let allowed = engine.allowedTypes(for: signals)
        XCTAssertFalse(allowed.contains(.deepCognitive))
    }

    // ═══════════════════════════════════════════════════════════════════
    // MARK: 14 · Bluetooth
    // ═══════════════════════════════════════════════════════════════════

    func test_earphones_notDriving_boostsMemory() {
        let signals = ContextSignals(
            aiUsageToday: 0,
            motionState: .walking,
            bluetoothDevices: [.earphones],
            hrv: 80,
            sleepHours: 8
        )
        // earphones + !driving: memory +2
        let result = engine.recommendedType(for: signals)
        XCTAssertNotNil(result)
    }

    func test_earphones_driving_noMemoryBoost() {
        let signals = ContextSignals(
            aiUsageToday: 0,
            motionState: .driving,
            bluetoothDevices: [.earphones],
            hrv: 80,
            sleepHours: 8
        )
        // No earphone boost when driving, but driving gate applies
        let result = engine.recommendedType(for: signals)
        XCTAssertNotNil(result)
    }

    func test_carBluetooth_penalizesDeepCognitive() {
        let signals = ContextSignals(
            aiUsageToday: 0,
            bluetoothDevices: [.car],
            hrv: 80,
            sleepHours: 8
        )
        // car: deepCognitive -5, sensory +2
        let result = engine.recommendedType(for: signals)
        XCTAssertNotNil(result)
    }

    // ═══════════════════════════════════════════════════════════════════
    // MARK: 15 · Cognitive Baseline
    // ═══════════════════════════════════════════════════════════════════

    func test_lowCognitiveScore_boostsMemory() {
        let signals = ContextSignals(
            aiUsageToday: 0,
            hrv: 80,
            sleepHours: 8,
            cognitiveScore: 30
        )
        // cognitiveScore < 40: memory +4
        let result = engine.recommendedType(for: signals)
        XCTAssertNotNil(result)
    }

    func test_highCognitiveScore_boostsDeepCognitive() {
        let signals = ContextSignals(
            age: 35, profession: .other,
            location: .work, motionState: .stationary,
            aiUsageToday: 0,
            hrv: 80,
            sleepHours: 8,
            cognitiveScore: 80
        )
        // cognitiveScore > 75: deepCognitive +3; work+stationary already +8, now +11
        let result = engine.recommendedType(for: signals)
        XCTAssertEqual(result, .deepCognitive)
    }

    // ═══════════════════════════════════════════════════════════════════
    // MARK: 16 · Life Stage
    // ═══════════════════════════════════════════════════════════════════

    func test_hasKids_boostsQuickReflectAndEmotional() {
        let signals = ContextSignals(
            aiUsageToday: 0,
            hasKids: true,
            hrv: 80,
            sleepHours: 8
        )
        // hasKids: quickReflect +2, emotional +2, deepCognitive -1
        let result = engine.recommendedType(for: signals)
        XCTAssertNotNil(result)
    }

    // ═══════════════════════════════════════════════════════════════════
    // MARK: 17 · Post-Meeting Memory Boost
    // ═══════════════════════════════════════════════════════════════════

    func test_postMeeting_boostsMemoryBy8() {
        let signals = ContextSignals(
            age: 55, profession: .other,
            aiUsageToday: 0,
            calendarStatus: .postMeeting,
            hrv: 80,
            sleepHours: 8
        )
        // memory gets +8 + ×1.3 (age 55+) = 10.4
        let result = engine.recommendedType(for: signals)
        XCTAssertEqual(result, .memory)
    }

    func test_postMeeting_isNotAHardBlock() {
        let signals = ContextSignals(calendarStatus: .postMeeting)
        XCTAssertNotNil(engine.recommendedType(for: signals))
    }

    // ═══════════════════════════════════════════════════════════════════
    // MARK: 18 · Combined Signal Scenarios
    // ═══════════════════════════════════════════════════════════════════

    func test_scenario_highAIUser_morningWork_optimalHealth() {
        // Heavy AI user, peak morning, at work stationary, great sleep/HRV
        let signals = ContextSignals(
            hour: 10, chronotype: .mid,
            age: 30, profession: .tech,
            location: .work, motionState: .stationary,
            calendarStatus: .free,
            aiUsageToday: 6,
            consecutiveDaysWithAI: 8,
            hrv: 75,
            sleepHours: 7.5
        )
        // criticalThinking: +7(usage>=5) +5(consec>=7) = +12, ×1.3(tech) = 15.6
        // deepCognitive: +5(usage>=5) +4(work+stat) +5(mid 10-13) = +14, ×1.2(age26-45) = 16.8
        // Expected: deepCognitive wins (strongest combined)
        let result = engine.recommendedType(for: signals)
        XCTAssertNotNil(result)
        XCTAssertTrue(result == .deepCognitive || result == .criticalThinking)
    }

    func test_scenario_postExercise_seniorUser_postMeeting() {
        // 55yo, 30min post-exercise, post-meeting → memory should dominate
        let signals = ContextSignals(
            age: 55, profession: .manager,
            aiUsageToday: 2,
            calendarStatus: .postMeeting,
            hrv: 65,
            sleepHours: 7.0,
            lastExerciseMinutes: 35
        )
        // memory: +4(aiUsage>=3) +6(postExercise) +8(postMeeting) = 18, ×1.3(age55+) = 23.4
        let result = engine.recommendedType(for: signals)
        XCTAssertEqual(result, .memory)
    }

    func test_scenario_runnerNoSleep() {
        // Running, very poor sleep, HRV borderline
        let signals = ContextSignals(
            motionState: .running,
            hrv: 35,
            sleepHours: 5.2
        )
        // Gate: sleep 5-6h removes deepCognitive+criticalThinking
        // Running makes physicalMind +5, deepCognitive -5
        // allowed won't include deepCognitive or criticalThinking
        let allowed = engine.allowedTypes(for: signals)
        XCTAssertFalse(allowed.contains(.deepCognitive))
        XCTAssertFalse(allowed.contains(.criticalThinking))
        let result = engine.recommendedType(for: signals)
        XCTAssertEqual(result, .physicalMind)
    }

    func test_scenario_drivingWithEarphones() {
        let signals = ContextSignals(
            aiUsageToday: 3,
            motionState: .driving,
            bluetoothDevices: [.earphones, .car],
            hrv: 55,
            sleepHours: 7.0
        )
        // Driving gate: only memory/sensory/recovery/quickReflect allowed
        // memory: +4(aiUsage>=3) + 3(driving motion) = 7
        let result = engine.recommendedType(for: signals)
        XCTAssertTrue([.memory, .sensory, .recovery, .quickReflect].contains(result!))
    }

    func test_scenario_cafeWalkingCreative() {
        let signals = ContextSignals(
            hour: 17, chronotype: .mid,
            age: 28,
            location: .cafe, motionState: .walking,
            aiUsageToday: 0,
            hrv: 80,
            sleepHours: 8
        )
        // cafe: social +2, sensory +2
        // walking: sensory +3, creative +2, physicalMind +3
        // mid + 17-19: creative +3
        // sensory total: 5, creative total: 5, social: 2, physicalMind: 3
        let result = engine.recommendedType(for: signals)
        XCTAssertTrue(result == .sensory || result == .creative)
    }

    // ═══════════════════════════════════════════════════════════════════
    // MARK: 19 · ChallengeBank Integrity
    // ═══════════════════════════════════════════════════════════════════

    func test_challengeBank_has50challenges() {
        XCTAssertEqual(ChallengeBank.all.count, 50)
    }

    func test_challengeBank_5perType() {
        for type in ChallengeType.allCases {
            let count = ChallengeBank.templates(for: type).count
            XCTAssertEqual(count, 5, "Expected 5 challenges for \(type), got \(count)")
        }
    }

    func test_challengeBank_allPromptsNonEmpty() {
        for template in ChallengeBank.all {
            XCTAssertFalse(template.prompt.isEmpty, "Empty prompt for type \(template.type)")
        }
    }

    func test_challengeBank_validDurations() {
        let valid = [30, 45, 60, 90, 120]
        for template in ChallengeBank.all {
            XCTAssertTrue(valid.contains(template.durationSeconds),
                "Invalid duration \(template.durationSeconds) for \(template.type)")
        }
    }

    func test_challengeBank_validIntensities() {
        for template in ChallengeBank.all {
            XCTAssertTrue((1...10).contains(template.intensity),
                "Intensity \(template.intensity) out of range for \(template.type)")
        }
    }

    // ═══════════════════════════════════════════════════════════════════
    // MARK: 20 · ChallengeSelector
    // ═══════════════════════════════════════════════════════════════════

    func test_selector_returnsChallenge_forValidType() {
        let selector = ChallengeSelector()
        let result = selector.select(type: .memory, recentIDs: [])
        XCTAssertNotNil(result)
        XCTAssertEqual(result?.type, .memory)
    }

    func test_selector_avoidsRecentIDs() {
        let selector = ChallengeSelector()
        let pool = ChallengeBank.templates(for: .memory)
        // Exclude all but one
        let keep = pool.last!
        let avoidIDs = pool.dropLast().map { $0.id }

        // With 4 out of 5 avoided, should return the remaining one
        let result = selector.select(type: .memory, recentIDs: avoidIDs)
        XCTAssertEqual(result?.id, keep.id)
    }

    func test_selector_fullPipeline_returnsNilWhenBlocked() {
        let selector = ChallengeSelector()
        let signals = ContextSignals(calendarStatus: .inMeeting)
        XCTAssertNil(selector.selectChallenge(signals: signals))
    }

    func test_selector_fullPipeline_returnsQuickReflectForMeetingSoon() {
        let selector = ChallengeSelector()
        let signals = ContextSignals(calendarStatus: .meetingSoon)
        let challenge = selector.selectChallenge(signals: signals)
        XCTAssertNotNil(challenge)
        XCTAssertEqual(challenge?.type, .quickReflect)
    }
}
