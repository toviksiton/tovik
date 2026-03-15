import Foundation
import FamilyControls
import ManagedSettings
import DeviceActivity

// MARK: - ScreenTimeService
// Monitors target AI app bundle IDs via DeviceActivityMonitor.
// On 3rd open: local notification nudge.
// On 5th open: ShieldConfiguration overlay (skip after 5s).
// On 8th+ open: 60-second mandatory timer.

// NOTE: ScreenTime / FamilyControls requires:
//   1. com.apple.developer.family-controls entitlement
//   2. A DeviceActivityMonitor extension target
//   3. Physical device (not simulator)

// MARK: - Target AI app bundle IDs

enum AIAppBundleIDs {
    static let all: Set<String> = [
        "com.openai.chat",
        "com.anthropic.claude",
        "com.microsoft.copilot",
        "com.google.ios.gemini",
        "com.perplexity.labs.ios"
    ]
}

// MARK: - ScreenTimeService

@Observable
final class ScreenTimeService {
    var isAuthorized = false
    var aiOpenCountToday: Int = 0

    private let center = AuthorizationCenter.shared
    private let store = ManagedSettingsStore()

    func requestAuthorization() async {
        do {
            try await center.requestAuthorization(for: .individual)
            await MainActor.run { isAuthorized = true }
            setupMonitoring()
        } catch {
            // FamilyControls not available or denied
        }
    }

    private func setupMonitoring() {
        // DeviceActivity monitoring is configured in the extension target.
        // This service handles the app-side logic (thresholds, shields).
        scheduleActivityMonitor()
    }

    private func scheduleActivityMonitor() {
        let monitor = DeviceActivityCenter()
        let schedule = DeviceActivitySchedule(
            intervalStart: DateComponents(hour: 0, minute: 0),
            intervalEnd:   DateComponents(hour: 23, minute: 59),
            repeats: true
        )
        let activity = DeviceActivityName("brain.gym.ai.monitoring")
        do {
            try monitor.startMonitoring(activity, during: schedule)
        } catch {
            // Monitor already started or unavailable
        }
    }

    // MARK: - Called from DeviceActivityMonitor extension when thresholds are hit

    func handleAIAppOpened() {
        aiOpenCountToday += 1
        switch aiOpenCountToday {
        case 3:
            scheduleNudgeNotification()
        case 5:
            applyShield(mandatory: false)
        case 8...:
            applyShield(mandatory: true)
        default:
            break
        }
    }

    // MARK: - Notifications

    private func scheduleNudgeNotification() {
        let content = UNMutableNotificationContent()
        content.title = "Brain Gym"
        content.body = "פתחת AI 3 פעמים היום. מוכן לאתגר מוחי?"
        content.sound = .default
        let request = UNNotificationRequest(
            identifier: "brain.gym.nudge.\(UUID())",
            content: content,
            trigger: nil // deliver immediately
        )
        UNUserNotificationCenter.current().add(request)
    }

    // MARK: - Shield

    private func applyShield(mandatory: Bool) {
        var applications = FamilyActivitySelection()
        // Selection must be configured by user through FamilyActivityPicker
        // Here we rely on the pre-configured selection stored in UserDefaults
        if let data = UserDefaults.standard.data(forKey: "brain.gym.aiAppSelection"),
           let selection = try? PropertyListDecoder().decode(FamilyActivitySelection.self, from: data) {
            applications = selection
        }
        store.shield.applications = applications.applicationTokens
        // ShieldConfiguration UI is in the ShieldConfiguration extension
    }

    func removeShield() {
        store.shield.applications = nil
    }
}

// MARK: - Notification center import
import UserNotifications
