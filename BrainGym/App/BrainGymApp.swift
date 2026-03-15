import SwiftUI
import SwiftData

@main
struct BrainGymApp: App {

    // MARK: - Services (long-lived, instantiated once)
    @State private var healthKit   = HealthKitService()
    @State private var calendar    = CalendarService()
    @State private var location    = LocationService()
    @State private var motion      = MotionService()
    @State private var bluetooth   = BluetoothService()
    @State private var screenTime  = ScreenTimeService()

    // MARK: - SwiftData
    let container = ModelContainer.brainGym

    var body: some Scene {
        WindowGroup {
            RootView(
                healthKit:  healthKit,
                calendar:   calendar,
                location:   location,
                motion:     motion,
                bluetooth:  bluetooth,
                screenTime: screenTime
            )
            .modelContainer(container)
            .preferredColorScheme(.dark)
            .environment(\.layoutDirection, .rightToLeft)
            .onAppear {
                motion.requestAuthorization()
                bluetooth.start()
                registerFonts()
            }
        }
    }

    // MARK: - Font registration
    private func registerFonts() {
        let fonts = [
            "PlayfairDisplay-Regular", "PlayfairDisplay-Bold",
            "DMMono-Regular", "DMMono-Medium"
        ]
        for name in fonts {
            guard let url = Bundle.main.url(forResource: name, withExtension: "ttf"),
                  let provider = CGDataProvider(url: url as CFURL),
                  let font = CGFont(provider) else { continue }
            CTFontManagerRegisterGraphicsFont(font, nil)
        }
    }
}
