import Foundation
import CoreMotion

// MARK: - MotionService
// Classifies device motion into MotionState using CMMotionActivityManager.

@Observable
final class MotionService {
    var motionState: MotionState = .stationary
    var isAuthorized = false

    private let activityManager = CMMotionActivityManager()

    func requestAuthorization() {
        guard CMMotionActivityManager.isActivityAvailable() else { return }
        activityManager.startActivityUpdates(to: .main) { [weak self] activity in
            guard let activity else { return }
            self?.isAuthorized = true
            self?.motionState = Self.classify(activity)
        }
    }

    func stopUpdates() {
        activityManager.stopActivityUpdates()
    }

    private static func classify(_ activity: CMMotionActivity) -> MotionState {
        if activity.automotive { return .driving }
        if activity.running    { return .running }
        if activity.walking || activity.cycling { return .walking }
        return .stationary
    }
}
