import Foundation
import CoreLocation

// MARK: - LocationService
// Classifies current location into LocationContext using geofencing +
// significant-location-change monitoring.

@Observable
final class LocationService: NSObject {
    var locationContext: LocationContext = .unknown
    var isAuthorized = false

    private let manager = CLLocationManager()
    private var currentLocation: CLLocation?

    // Named geofences (set by user in Settings or auto-detected)
    var officeRegion: CLCircularRegion?
    var gymRegion: CLCircularRegion?

    override init() {
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyHundredMeters
        manager.distanceFilter = 100
    }

    func requestAuthorization() {
        manager.requestWhenInUseAuthorization()
    }

    func startMonitoring() {
        manager.startMonitoringSignificantLocationChanges()
        if let office = officeRegion { manager.startMonitoring(for: office) }
        if let gym = gymRegion       { manager.startMonitoring(for: gym) }
    }

    // MARK: - Context classification

    private func classify(location: CLLocation) -> LocationContext {
        // Named geofences take priority
        if let office = officeRegion, office.contains(location.coordinate) { return .work }
        if let gym = gymRegion, gym.contains(location.coordinate)           { return .gym }

        // Heuristic: use speed + activity (Motion service provides finer grain)
        // For now return .unknown; ContextEngine combines with MotionService
        return .unknown
    }
}

// MARK: - CLLocationManagerDelegate

extension LocationService: CLLocationManagerDelegate {

    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        switch manager.authorizationStatus {
        case .authorizedWhenInUse, .authorizedAlways:
            isAuthorized = true
            startMonitoring()
        default:
            isAuthorized = false
        }
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let loc = locations.last else { return }
        currentLocation = loc
        locationContext = classify(location: loc)
    }

    func locationManager(_ manager: CLLocationManager, didEnterRegion region: CLRegion) {
        if region.identifier == "office" { locationContext = .work }
        if region.identifier == "gym"    { locationContext = .gym }
    }

    func locationManager(_ manager: CLLocationManager, didExitRegion region: CLRegion) {
        // Re-classify based on last known location
        if let loc = currentLocation { locationContext = classify(location: loc) }
    }
}
