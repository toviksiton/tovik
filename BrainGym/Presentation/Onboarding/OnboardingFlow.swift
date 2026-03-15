import SwiftUI
import SwiftData

// MARK: - OnboardingFlow
// 5 screens: Hero → Permissions → Profile → Assessment → First Challenge

struct OnboardingFlow: View {
    @Environment(\.modelContext) private var modelContext
    var onComplete: () -> Void

    @State private var step = 0
    @State private var settings = UserSettings()
    @State private var cognitiveScore: CognitiveScore?
    @State private var firstChallenge: Challenge?

    // Services (passed down for permission requests)
    var healthKit: HealthKitService
    var calendar: CalendarService
    var location: LocationService
    var screenTime: ScreenTimeService

    var body: some View {
        ZStack {
            Color(hex: "#0E0C0A").ignoresSafeArea()

            switch step {
            case 0: HeroScreen(onNext: { withAnimation { step = 1 } })
            case 1: PermissionsScreen(
                        healthKit: healthKit,
                        calendar: calendar,
                        location: location,
                        screenTime: screenTime,
                        onNext: { withAnimation { step = 2 } }
                    )
            case 2: ProfileSetupScreen(settings: $settings, onNext: { withAnimation { step = 3 } })
            case 3: AssessmentScreen(onComplete: { score in
                        cognitiveScore = score
                        modelContext.insert(score)
                        withAnimation { step = 4 }
                    })
            case 4: FirstChallengeScreen(
                        settings: settings,
                        cognitiveScore: cognitiveScore,
                        onComplete: { withAnimation { finalize() } }
                    )
            default: EmptyView()
            }
        }
        .environment(\.layoutDirection, .rightToLeft)
    }

    private func finalize() {
        settings.onboardingComplete = true
        modelContext.insert(settings)
        try? modelContext.save()
        onComplete()
    }
}

// MARK: - Screen 1: Hero

private struct HeroScreen: View {
    var onNext: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            Spacer()

            VStack(spacing: 24) {
                Text("חדר הכושר\nלמוח שלך")
                    .font(.display(44, weight: "Bold"))
                    .foregroundColor(Color(hex: "#F5F0E8"))
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)

                VStack(spacing: 12) {
                    statBadge("55%", "ירידה בקישוריות מוחית")
                    statBadge("MIT 2025", "מחקר שמוכיח את הנזק")
                }

                Text("בכל פעם שאתה פותח AI — המוח שלך מוותר על מאמץ. Brain Gym מחזיר אותו לפעולה.")
                    .font(.display(18, weight: "Regular"))
                    .foregroundColor(Color(hex: "#504540"))
                    .multilineTextAlignment(.center)
                    .lineSpacing(5)
                    .padding(.horizontal, 8)
            }
            .padding(.horizontal, 32)

            Spacer()

            Button(action: { haptic(.heavy); onNext() }) {
                Text("בואו נתחיל")
                    .font(.display(22, weight: "Bold"))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 20)
                    .background(Color(hex: "#C4622D"))
                    .cornerRadius(16)
            }
            .padding(.horizontal, 32)
            .padding(.bottom, 56)
        }
    }

    private func statBadge(_ number: String, _ label: String) -> some View {
        HStack(spacing: 10) {
            Text(number)
                .font(.mono(28, weight: "Regular"))
                .foregroundColor(Color(hex: "#C4622D"))
            Text(label)
                .font(.mono(14))
                .foregroundColor(Color(hex: "#504540"))
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
        .background(Color(hex: "#141210"))
        .cornerRadius(12)
    }
}

// MARK: - Screen 2: Permissions

private struct PermissionsScreen: View {
    var healthKit: HealthKitService
    var calendar: CalendarService
    var location: LocationService
    var screenTime: ScreenTimeService
    var onNext: () -> Void

    @State private var grantedHealth = false
    @State private var grantedCalendar = false
    @State private var grantedLocation = false
    @State private var grantedNotifications = false

    var body: some View {
        VStack(spacing: 0) {
            VStack(spacing: 8) {
                Text("הרשאות")
                    .font(.display(32, weight: "Bold"))
                    .foregroundColor(Color(hex: "#F5F0E8"))
                Text("כדי שהאפליקציה תפעל בצורה חכמה")
                    .font(.mono(14))
                    .foregroundColor(Color(hex: "#504540"))
            }
            .padding(.top, 80)
            .padding(.horizontal, 32)

            Spacer()

            VStack(spacing: 16) {
                permissionRow(
                    icon: "heart.fill", label: "בריאות", sublabel: "דופק, HRV, שינה, צעדים",
                    granted: grantedHealth,
                    action: {
                        Task { await healthKit.requestAuthorization(); grantedHealth = true }
                    }
                )
                permissionRow(
                    icon: "calendar", label: "לוח שנה", sublabel: "זיהוי פגישות",
                    granted: grantedCalendar,
                    action: {
                        Task { await calendar.requestAuthorization(); grantedCalendar = true }
                    }
                )
                permissionRow(
                    icon: "location.fill", label: "מיקום", sublabel: "בית, עבודה, חדר כושר",
                    granted: grantedLocation,
                    action: { location.requestAuthorization(); grantedLocation = true }
                )
                permissionRow(
                    icon: "bell.fill", label: "התראות", sublabel: "אתגרים ותזכורות",
                    granted: grantedNotifications,
                    action: {
                        Task {
                            let _ = try? await UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge])
                            grantedNotifications = true
                        }
                    }
                )
            }
            .padding(.horizontal, 32)

            Spacer()

            Button(action: { haptic(.medium); onNext() }) {
                Text("המשך")
                    .font(.display(20, weight: "Bold"))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 18)
                    .background(Color(hex: "#C4622D"))
                    .cornerRadius(14)
            }
            .padding(.horizontal, 32)
            .padding(.bottom, 48)
        }
    }

    private func permissionRow(icon: String, label: String, sublabel: String, granted: Bool, action: @escaping () -> Void) -> some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(granted ? Color(hex: "#4A7B5C") : Color(hex: "#C4622D"))
                .frame(width: 32)

            VStack(alignment: .leading, spacing: 2) {
                Text(label)
                    .font(.display(16, weight: "Regular"))
                    .foregroundColor(Color(hex: "#F5F0E8"))
                Text(sublabel)
                    .font(.mono(12))
                    .foregroundColor(Color(hex: "#504540"))
            }

            Spacer()

            Button(action: { haptic(.light); action() }) {
                Text(granted ? "אושר ✓" : "אשר")
                    .font(.mono(13, weight: "Medium"))
                    .foregroundColor(granted ? Color(hex: "#4A7B5C") : .white)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(granted ? Color(hex: "#4A7B5C").opacity(0.2) : Color(hex: "#C4622D"))
                    .cornerRadius(8)
            }
            .disabled(granted)
        }
        .padding(16)
        .background(Color(hex: "#141210"))
        .cornerRadius(12)
    }
}

// MARK: - Screen 3: Profile Setup

private struct ProfileSetupScreen: View {
    @Binding var settings: UserSettings
    var onNext: () -> Void

    var body: some View {
        ScrollView {
            VStack(spacing: 32) {
                VStack(spacing: 8) {
                    Text("הפרופיל שלך")
                        .font(.display(32, weight: "Bold"))
                        .foregroundColor(Color(hex: "#F5F0E8"))
                    Text("מותאם אישית לך")
                        .font(.mono(14))
                        .foregroundColor(Color(hex: "#504540"))
                }
                .padding(.top, 80)

                // Age
                VStack(alignment: .leading, spacing: 8) {
                    Text("גיל: \(settings.age)")
                        .font(.mono(16))
                        .foregroundColor(Color(hex: "#F5F0E8"))
                    Slider(value: Binding(
                        get: { Double(settings.age) },
                        set: { settings.age = Int($0) }
                    ), in: 16...80, step: 1)
                    .tint(Color(hex: "#C4622D"))
                }

                // Chronotype
                VStack(alignment: .leading, spacing: 8) {
                    Text("אני הכי פרודוקטיבי")
                        .font(.mono(14))
                        .foregroundColor(Color(hex: "#504540"))
                    Picker("כרונוטיפ", selection: $settings.chronotype) {
                        Text("בוקר מוקדם").tag(Chronotype.early)
                        Text("אמצע יום").tag(Chronotype.mid)
                        Text("אחה\"צ ולילה").tag(Chronotype.late)
                    }
                    .pickerStyle(.segmented)
                }

                // Profession
                VStack(alignment: .leading, spacing: 8) {
                    Text("תחום עבודה")
                        .font(.mono(14))
                        .foregroundColor(Color(hex: "#504540"))
                    Picker("מקצוע", selection: $settings.profession) {
                        Text("טכנולוגיה").tag(Profession.tech)
                        Text("יצירה").tag(Profession.creative)
                        Text("רפואה").tag(Profession.medical)
                        Text("פיננסים").tag(Profession.finance)
                        Text("חינוך").tag(Profession.education)
                        Text("סטודנט").tag(Profession.student)
                        Text("ניהול").tag(Profession.manager)
                        Text("אחר").tag(Profession.other)
                    }
                    .pickerStyle(.menu)
                    .tint(Color(hex: "#C4622D"))
                }

                // Toggles
                VStack(spacing: 12) {
                    Toggle("יש לי תואר אקדמי", isOn: $settings.hasUniversityDegree)
                        .font(.mono(15))
                        .foregroundColor(Color(hex: "#F5F0E8"))
                        .tint(Color(hex: "#C4622D"))
                    Toggle("יש לי ילדים", isOn: $settings.hasKids)
                        .font(.mono(15))
                        .foregroundColor(Color(hex: "#F5F0E8"))
                        .tint(Color(hex: "#C4622D"))
                }

                Button(action: { haptic(.medium); onNext() }) {
                    Text("המשך")
                        .font(.display(20, weight: "Bold"))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 18)
                        .background(Color(hex: "#C4622D"))
                        .cornerRadius(14)
                }
                .padding(.bottom, 48)
            }
            .padding(.horizontal, 32)
        }
    }
}

// MARK: - Screen 4: Assessment wrapper

private struct AssessmentScreen: View {
    var onComplete: (CognitiveScore) -> Void

    var body: some View {
        VStack(spacing: 0) {
            Text("בדיקת כושר ראשונית")
                .font(.display(24, weight: "Regular"))
                .foregroundColor(Color(hex: "#504540"))
                .padding(.top, 48)

            AssessmentView(onComplete: onComplete)
        }
    }
}

// MARK: - Screen 5: First Challenge

private struct FirstChallengeScreen: View {
    let settings: UserSettings
    let cognitiveScore: CognitiveScore?
    var onComplete: () -> Void

    @State private var phase: FirstChallengePhase = .overlay
    @State private var challenge: Challenge?

    enum FirstChallengePhase { case overlay, active, complete }

    var body: some View {
        Group {
            switch phase {
            case .overlay:
                if let ch = challenge {
                    ChallengeOverlayView(
                        challenge: ch,
                        mandatoryMode: false,
                        onBegin: { withAnimation { phase = .active } },
                        onSkip:  { withAnimation { phase = .complete } }
                    )
                } else {
                    Color(hex: "#0E0C0A").ignoresSafeArea()
                }
            case .active:
                if let ch = challenge {
                    ActiveChallengeView(
                        challenge: ch,
                        onComplete: { withAnimation { phase = .complete } },
                        onSkip:    { withAnimation { phase = .complete } }
                    )
                }
            case .complete:
                if let ch = challenge {
                    ChallengeCompleteView(challenge: ch, streak: 1, onDismiss: onComplete)
                } else {
                    Color(hex: "#0E0C0A").ignoresSafeArea()
                        .onAppear { onComplete() }
                }
            }
        }
        .onAppear { generateChallenge() }
    }

    private func generateChallenge() {
        let signals = ContextSignals(
            hour: Calendar.current.component(.hour, from: Date()),
            chronotype: settings.chronotype,
            age: settings.age,
            profession: settings.profession,
            hasUniversityDegree: settings.hasUniversityDegree,
            hasKids: settings.hasKids,
            cognitiveScore: cognitiveScore?.overallInt
        )
        challenge = ChallengeSelector().selectChallenge(signals: signals)
            ?? ChallengeBank.templates(for: .quickReflect).first?.toChallenge()
    }
}

// MARK: - Import for notifications
import UserNotifications
