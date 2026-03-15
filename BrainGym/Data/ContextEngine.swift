import Foundation

// MARK: - ContextEngine
// Aggregates all services into a ContextSignals snapshot for the ScoringEngine.

@Observable
final class ContextEngine {

    // Injected services
    var healthKit: HealthKitService
    var calendar: CalendarService
    var location: LocationService
    var motion: MotionService
    var bluetooth: BluetoothService

    // User profile (persisted separately, injected here)
    var userProfile: UserProfile

    init(
        healthKit: HealthKitService,
        calendar: CalendarService,
        location: LocationService,
        motion: MotionService,
        bluetooth: BluetoothService,
        userProfile: UserProfile
    ) {
        self.healthKit   = healthKit
        self.calendar    = calendar
        self.location    = location
        self.motion      = motion
        self.bluetooth   = bluetooth
        self.userProfile = userProfile
    }

    // MARK: - Build current signals snapshot

    func currentSignals(cognitiveScore: Int? = nil) -> ContextSignals {
        let hour = Calendar.current.component(.hour, from: Date())
        let aiUsage = AIUsageTracker.shared

        return ContextSignals(
            hour: hour,
            chronotype: userProfile.chronotype,
            age: userProfile.age,
            profession: userProfile.profession,
            hasUniversityDegree: userProfile.hasUniversityDegree,
            hasKids: userProfile.hasKids,
            location: location.locationContext,
            motionState: motion.motionState,
            calendarStatus: calendar.calendarStatus,
            aiUsageToday: aiUsage.openCountToday,
            aiUsageWeekly: aiUsage.openCountWeekly,
            consecutiveDaysWithAI: aiUsage.consecutiveDays,
            bluetoothDevices: bluetooth.connectedDevices,
            heartRate: healthKit.heartRate,
            hrv: healthKit.hrv,
            sleepHours: healthKit.sleepHours,
            steps: healthKit.steps,
            lastExerciseMinutes: healthKit.lastExerciseMinutes,
            cognitiveScore: cognitiveScore
        )
    }

    // MARK: - Select challenge for current context

    func selectChallenge(cognitiveScore: Int? = nil, recentIDs: [UUID] = []) -> Challenge? {
        let signals = currentSignals(cognitiveScore: cognitiveScore)
        return ChallengeSelector().selectChallenge(signals: signals, recentIDs: recentIDs)
    }
}

// MARK: - UserProfile (simple struct, persisted via AppStorage/SwiftData)

struct UserProfile: Codable {
    var age: Int = 30
    var chronotype: Chronotype = .mid
    var profession: Profession = .other
    var hasUniversityDegree: Bool = true
    var hasKids: Bool = false
}

// MARK: - AIUsageTracker (simple in-memory + UserDefaults persistence)

final class AIUsageTracker {
    static let shared = AIUsageTracker()
    private init() { load() }

    private(set) var openCountToday: Int = 0
    private(set) var openCountWeekly: Int = 0
    private(set) var consecutiveDays: Int = 0
    private var lastOpenDate: Date?
    private var lastResetDate: Date = Date()

    func recordOpen() {
        let today = Calendar.current.startOfDay(for: Date())
        // Reset daily counter if new day
        if let last = lastResetDate as Date?,
           !Calendar.current.isDate(last, inSameDayAs: Date()) {
            openCountToday = 0
            lastResetDate = today
        }
        openCountToday += 1
        openCountWeekly += 1
        // Consecutive days logic
        if let last = lastOpenDate {
            let daysBetween = Calendar.current.dateComponents([.day], from: last, to: Date()).day ?? 0
            if daysBetween == 1 { consecutiveDays += 1 }
            else if daysBetween > 1 { consecutiveDays = 1 }
        } else {
            consecutiveDays = 1
        }
        lastOpenDate = Date()
        save()
    }

    private func save() {
        let defaults = UserDefaults.standard
        defaults.set(openCountToday,  forKey: "bg.ai.today")
        defaults.set(openCountWeekly, forKey: "bg.ai.weekly")
        defaults.set(consecutiveDays, forKey: "bg.ai.consec")
        defaults.set(lastOpenDate,    forKey: "bg.ai.lastOpen")
        defaults.set(lastResetDate,   forKey: "bg.ai.resetDate")
    }

    private func load() {
        let d = UserDefaults.standard
        openCountToday  = d.integer(forKey: "bg.ai.today")
        openCountWeekly = d.integer(forKey: "bg.ai.weekly")
        consecutiveDays = d.integer(forKey: "bg.ai.consec")
        lastOpenDate    = d.object(forKey: "bg.ai.lastOpen") as? Date
        lastResetDate   = (d.object(forKey: "bg.ai.resetDate") as? Date) ?? Date()
    }
}
