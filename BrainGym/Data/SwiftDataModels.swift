import Foundation
import SwiftData

// MARK: - SwiftData schema container

typealias BrainGymSchema = Schema([
    Challenge.self,
    CognitiveScore.self,
    UserSettings.self
])

// MARK: - UserSettings (persisted profile + preferences)

@Model
final class UserSettings {
    var age: Int
    var chronotypeRaw: String
    var professionRaw: String
    var hasUniversityDegree: Bool
    var hasKids: Bool
    var onboardingComplete: Bool
    var monthsActive: Int           // unlocks mandatory mode at month 2+
    var lastAssessmentDate: Date?

    var chronotype: Chronotype {
        get { Chronotype(rawValue: chronotypeRaw) ?? .mid }
        set { chronotypeRaw = newValue.rawValue }
    }

    var profession: Profession {
        get { Profession(rawValue: professionRaw) ?? .other }
        set { professionRaw = newValue.rawValue }
    }

    var toProfile: UserProfile {
        UserProfile(
            age: age,
            chronotype: chronotype,
            profession: profession,
            hasUniversityDegree: hasUniversityDegree,
            hasKids: hasKids
        )
    }

    init(
        age: Int = 30,
        chronotype: Chronotype = .mid,
        profession: Profession = .other,
        hasUniversityDegree: Bool = true,
        hasKids: Bool = false,
        onboardingComplete: Bool = false,
        monthsActive: Int = 0,
        lastAssessmentDate: Date? = nil
    ) {
        self.age = age
        self.chronotypeRaw = chronotype.rawValue
        self.professionRaw = profession.rawValue
        self.hasUniversityDegree = hasUniversityDegree
        self.hasKids = hasKids
        self.onboardingComplete = onboardingComplete
        self.monthsActive = monthsActive
        self.lastAssessmentDate = lastAssessmentDate
    }
}

// MARK: - ModelContainer factory

extension ModelContainer {
    static var brainGym: ModelContainer {
        let schema = Schema([Challenge.self, CognitiveScore.self, UserSettings.self])
        let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
        return try! ModelContainer(for: schema, configurations: [config])
    }
}
