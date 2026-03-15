import Foundation
import HealthKit

// MARK: - HealthKitService
// Reads heart rate, HRV, sleep, and steps. Read-only — no data is written.

@Observable
final class HealthKitService {
    var heartRate: Double?         // bpm
    var hrv: Double?               // RMSSD ms
    var sleepHours: Double?        // last night
    var steps: Int?                // today
    var lastExerciseMinutes: Int?  // minutes since last workout ended
    var isAuthorized = false

    private let store = HKHealthStore()

    // Types we want to read
    private var readTypes: Set<HKObjectType> {
        let types: [HKObjectType?] = [
            HKQuantityType(.heartRate),
            HKQuantityType(.heartRateVariabilitySDNN),
            HKQuantityType(.stepCount),
            HKCategoryType(.sleepAnalysis),
            HKWorkoutType.workoutType()
        ]
        return Set(types.compactMap { $0 })
    }

    func requestAuthorization() async {
        guard HKHealthStore.isHealthDataAvailable() else { return }
        do {
            try await store.requestAuthorization(toShare: [], read: readTypes)
            isAuthorized = true
            await fetchAll()
        } catch {
            // Authorization denied or unavailable — proceed without HealthKit
        }
    }

    func fetchAll() async {
        async let hr    = fetchLatestHeartRate()
        async let hrv   = fetchLatestHRV()
        async let steps = fetchTodaySteps()
        async let sleep = fetchLastNightSleep()
        async let ex    = fetchLastExerciseMinutes()

        let (heartRateVal, hrvVal, stepsVal, sleepVal, exVal) = await (hr, hrv, steps, sleep, ex)
        await MainActor.run {
            self.heartRate            = heartRateVal
            self.hrv                  = hrvVal
            self.steps                = stepsVal
            self.sleepHours           = sleepVal
            self.lastExerciseMinutes  = exVal
        }
    }

    // MARK: - Fetch helpers

    private func fetchLatestHeartRate() async -> Double? {
        let type = HKQuantityType(.heartRate)
        return await fetchLatestSample(type: type)?.quantity.doubleValue(for: .init(from: "count/min"))
    }

    private func fetchLatestHRV() async -> Double? {
        let type = HKQuantityType(.heartRateVariabilitySDNN)
        return await fetchLatestSample(type: type).map {
            $0.quantity.doubleValue(for: .secondUnit(with: .milli)) * 1000 // convert s → ms
        }
    }

    private func fetchTodaySteps() async -> Int? {
        let type = HKQuantityType(.stepCount)
        let start = Calendar.current.startOfDay(for: Date())
        let predicate = HKQuery.predicateForSamples(withStart: start, end: Date())
        return await withCheckedContinuation { cont in
            let query = HKStatisticsQuery(quantityType: type, quantitySamplePredicate: predicate, options: .cumulativeSum) { _, stats, _ in
                let value = stats?.sumQuantity()?.doubleValue(for: .count())
                cont.resume(returning: value.map(Int.init))
            }
            store.execute(query)
        }
    }

    private func fetchLastNightSleep() async -> Double? {
        let type = HKCategoryType(.sleepAnalysis)
        let now = Date()
        let yesterday = Calendar.current.date(byAdding: .hour, value: -14, to: now)!
        let predicate = HKQuery.predicateForSamples(withStart: yesterday, end: now)
        return await withCheckedContinuation { cont in
            let query = HKSampleQuery(sampleType: type, predicate: predicate, limit: HKObjectQueryNoLimit, sortDescriptors: nil) { _, samples, _ in
                guard let samples = samples as? [HKCategorySample] else { cont.resume(returning: nil); return }
                let asleepValues: [HKCategoryValueSleepAnalysis] = [.asleepCore, .asleepDeep, .asleepREM, .asleepUnspecified]
                let asleepRaw = asleepValues.map(\.rawValue)
                let totalSleep = samples
                    .filter { asleepRaw.contains($0.value) }
                    .reduce(0.0) { $0 + $1.endDate.timeIntervalSince($1.startDate) }
                cont.resume(returning: totalSleep > 0 ? totalSleep / 3600.0 : nil)
            }
            store.execute(query)
        }
    }

    private func fetchLastExerciseMinutes() async -> Int? {
        let workoutType = HKWorkoutType.workoutType()
        let now = Date()
        let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: now)!
        let predicate = HKQuery.predicateForSamples(withStart: yesterday, end: now)
        let sort = NSSortDescriptor(key: HKSampleSortIdentifierEndDate, ascending: false)
        return await withCheckedContinuation { cont in
            let query = HKSampleQuery(sampleType: workoutType, predicate: predicate, limit: 1, sortDescriptors: [sort]) { _, samples, _ in
                guard let workout = samples?.first as? HKWorkout else { cont.resume(returning: nil); return }
                let minsAgo = Int(now.timeIntervalSince(workout.endDate) / 60)
                cont.resume(returning: minsAgo)
            }
            store.execute(query)
        }
    }

    private func fetchLatestSample(type: HKQuantityType) async -> HKQuantitySample? {
        let sort = NSSortDescriptor(key: HKSampleSortIdentifierEndDate, ascending: false)
        return await withCheckedContinuation { cont in
            let query = HKSampleQuery(sampleType: type, predicate: nil, limit: 1, sortDescriptors: [sort]) { _, samples, _ in
                cont.resume(returning: samples?.first as? HKQuantitySample)
            }
            store.execute(query)
        }
    }

    // MARK: - Signals snapshot

    func applyToSignals(_ signals: inout ContextSignals) {
        signals.heartRate           = heartRate
        signals.hrv                 = hrv
        signals.sleepHours          = sleepHours
        signals.steps               = steps
        signals.lastExerciseMinutes = lastExerciseMinutes
    }
}
