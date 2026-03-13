import SwiftUI

// MARK: - Challenge Types

enum ChallengeType: String, Codable, CaseIterable {
    case criticalThinking
    case deepCognitive
    case memory
    case quickReflect
    case recovery
    case sensory
    case emotional
    case social
    case creative
    case physicalMind

    var displayNameHebrew: String {
        switch self {
        case .criticalThinking: return "חשיבה ביקורתית"
        case .deepCognitive:    return "קוגניציה עמוקה"
        case .memory:           return "זיכרון"
        case .quickReflect:     return "רפלקציה מהירה"
        case .recovery:         return "התאוששות"
        case .sensory:          return "חישה"
        case .emotional:        return "רגשות"
        case .social:           return "חברתי"
        case .creative:         return "יצירתיות"
        case .physicalMind:     return "גוף-מוח"
        }
    }

    /// Hex color per design system
    var colorHex: String {
        switch self {
        case .criticalThinking: return "#8B2500"
        case .deepCognitive:    return "#C4622D"
        case .memory:           return "#4A7B5C"
        case .quickReflect:     return "#B8860B"
        case .recovery:         return "#4A6B7B"
        case .sensory:          return "#5B7FA6"
        case .emotional:        return "#8A5B6B"
        case .social:           return "#6B5B8A"
        case .creative:         return "#7B6A3E"
        case .physicalMind:     return "#3E7B5C"
        }
    }
}

// MARK: - Chronotype

enum Chronotype: String, Codable {
    case early
    case mid
    case late
}

// MARK: - Location Context

enum LocationContext: String, Codable {
    case home
    case work
    case cafe
    case gym
    case park
    case commuteCar
    case commuteTransit
    case restaurant
    case unknown
}

// MARK: - Motion State

enum MotionState: String, Codable {
    case stationary
    case walking
    case driving
    case running
}

// MARK: - Calendar Status

enum CalendarStatus: String, Codable {
    case free
    case meetingSoon
    case inMeeting
    case postMeeting
}

// MARK: - Bluetooth Device Types

enum BluetoothDevice: String, Codable, Hashable {
    case earphones
    case watch
    case car
}

// MARK: - Profession

enum Profession: String, Codable {
    case tech
    case creative
    case medical
    case finance
    case education
    case student
    case manager
    case other
}
