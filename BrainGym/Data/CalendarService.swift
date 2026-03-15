import Foundation
import EventKit

// MARK: - CalendarService
// Reads calendar events to determine CalendarStatus for the algorithm.

@Observable
final class CalendarService {
    var calendarStatus: CalendarStatus = .free
    var isAuthorized = false

    private let eventStore = EKEventStore()
    private var refreshTimer: Timer?

    func requestAuthorization() async {
        do {
            let granted = try await eventStore.requestFullAccessToEvents()
            await MainActor.run { isAuthorized = granted }
            if granted {
                await refresh()
                startPeriodicRefresh()
            }
        } catch {
            // Proceed without calendar access
        }
    }

    func refresh() async {
        let status = computeStatus()
        await MainActor.run { calendarStatus = status }
    }

    private func startPeriodicRefresh() {
        refreshTimer?.invalidate()
        refreshTimer = Timer.scheduledTimer(withTimeInterval: 15 * 60, repeats: true) { [weak self] _ in
            Task { await self?.refresh() }
        }
    }

    // MARK: - Status computation

    private func computeStatus() -> CalendarStatus {
        let now = Date()
        let lookAhead = Calendar.current.date(byAdding: .minute, value: 25, to: now)!
        let lookBack  = Calendar.current.date(byAdding: .minute, value: -15, to: now)!

        let predicate = eventStore.predicateForEvents(withStart: lookBack, end: lookAhead, calendars: nil)
        let events = eventStore.events(matching: predicate)
            .filter { !$0.isAllDay && $0.attendees?.isEmpty == false || $0.hasAlarm }

        // Currently in meeting?
        if events.contains(where: { $0.startDate <= now && $0.endDate >= now }) {
            return .inMeeting
        }

        // Meeting within 20 minutes?
        let soonThreshold = Calendar.current.date(byAdding: .minute, value: 20, to: now)!
        if events.contains(where: { $0.startDate > now && $0.startDate <= soonThreshold }) {
            return .meetingSoon
        }

        // Meeting ended within last 10 minutes?
        let postThreshold = Calendar.current.date(byAdding: .minute, value: -10, to: now)!
        if events.contains(where: { $0.endDate >= postThreshold && $0.endDate <= now }) {
            return .postMeeting
        }

        return .free
    }
}
