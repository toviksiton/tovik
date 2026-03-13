import Foundation

// MARK: - ContextSignals

/// All context signals fed into the scoring algorithm.
struct ContextSignals {
    // Time
    var hour: Int                              // 0–23

    // User profile
    var chronotype: Chronotype
    var age: Int
    var profession: Profession
    var hasUniversityDegree: Bool
    var hasKids: Bool

    // Environment
    var location: LocationContext
    var motionState: MotionState
    var calendarStatus: CalendarStatus

    // AI usage
    var aiUsageToday: Int
    var aiUsageWeekly: Int
    var consecutiveDaysWithAI: Int

    // Bluetooth
    var bluetoothDevices: Set<BluetoothDevice>

    // Health (all optional — may not be available)
    var heartRate: Double?          // bpm
    var hrv: Double?                // RMSSD ms
    var sleepHours: Double?
    var steps: Int?
    var lastExerciseMinutes: Int?   // minutes since last exercise ended

    // Cognitive baseline
    var cognitiveScore: Int?        // 0–100 from assessment battery

    // MARK: - Convenience init with sensible defaults for testing
    init(
        hour: Int = 10,
        chronotype: Chronotype = .mid,
        age: Int = 30,
        profession: Profession = .tech,
        hasUniversityDegree: Bool = true,
        hasKids: Bool = false,
        location: LocationContext = .work,
        motionState: MotionState = .stationary,
        calendarStatus: CalendarStatus = .free,
        aiUsageToday: Int = 0,
        aiUsageWeekly: Int = 0,
        consecutiveDaysWithAI: Int = 0,
        bluetoothDevices: Set<BluetoothDevice> = [],
        heartRate: Double? = nil,
        hrv: Double? = nil,
        sleepHours: Double? = nil,
        steps: Int? = nil,
        lastExerciseMinutes: Int? = nil,
        cognitiveScore: Int? = nil
    ) {
        self.hour = hour
        self.chronotype = chronotype
        self.age = age
        self.profession = profession
        self.hasUniversityDegree = hasUniversityDegree
        self.hasKids = hasKids
        self.location = location
        self.motionState = motionState
        self.calendarStatus = calendarStatus
        self.aiUsageToday = aiUsageToday
        self.aiUsageWeekly = aiUsageWeekly
        self.consecutiveDaysWithAI = consecutiveDaysWithAI
        self.bluetoothDevices = bluetoothDevices
        self.heartRate = heartRate
        self.hrv = hrv
        self.sleepHours = sleepHours
        self.steps = steps
        self.lastExerciseMinutes = lastExerciseMinutes
        self.cognitiveScore = cognitiveScore
    }
}
