import SwiftUI
import SwiftData

// MARK: - RootView
// Entry point: shows Onboarding or Main tab view based on settings.

struct RootView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var settingsResults: [UserSettings]

    var healthKit:  HealthKitService
    var calendar:   CalendarService
    var location:   LocationService
    var motion:     MotionService
    var bluetooth:  BluetoothService
    var screenTime: ScreenTimeService

    private var settings: UserSettings? { settingsResults.first }

    var body: some View {
        Group {
            if settings?.onboardingComplete == true {
                mainTabView
            } else {
                OnboardingFlow(
                    onComplete: {},
                    healthKit:  healthKit,
                    calendar:   calendar,
                    location:   location,
                    screenTime: screenTime
                )
            }
        }
    }

    private var mainTabView: some View {
        let profile = settings?.toProfile ?? UserProfile()
        let engine = ContextEngine(
            healthKit:   healthKit,
            calendar:    calendar,
            location:    location,
            motion:      motion,
            bluetooth:   bluetooth,
            userProfile: profile
        )
        let homeVM = HomeViewModel(contextEngine: engine)

        return TabView {
            HomeView(viewModel: homeVM)
                .tabItem {
                    Label("בית", systemImage: "house.fill")
                }

            BrainGymProgressView()
                .tabItem {
                    Label("התקדמות", systemImage: "chart.line.uptrend.xyaxis")
                }

            AssessmentView(onComplete: { score in
                modelContext.insert(score)
            })
            .tabItem {
                Label("בדיקה", systemImage: "brain.head.profile")
            }
        }
        .tint(Color(hex: "#C4622D"))
    }
}
