import SwiftUI

// MARK: - ActiveChallengeView
// Full-screen, near-zero chrome. Giant prompt + circular countdown timer ring.

struct ActiveChallengeView: View {
    let challenge: Challenge
    var onComplete: () -> Void
    var onSkip: () -> Void

    @State private var secondsRemaining: Int
    @State private var isRunning = false
    @State private var timer: Timer?

    init(challenge: Challenge, onComplete: @escaping () -> Void, onSkip: @escaping () -> Void) {
        self.challenge = challenge
        self.onComplete = onComplete
        self.onSkip = onSkip
        _secondsRemaining = State(initialValue: challenge.durationSeconds)
    }

    private var progress: Double {
        Double(secondsRemaining) / Double(challenge.durationSeconds)
    }

    var body: some View {
        ZStack {
            Color(hex: "#0E0C0A").ignoresSafeArea()

            VStack(spacing: 0) {
                Spacer()

                // Timer ring
                timerRing

                Spacer().frame(height: 48)

                // Prompt
                promptText

                Spacer()

                // Footer
                footer
            }
            .padding(.horizontal, 32)
        }
        .environment(\.layoutDirection, .rightToLeft)
        .onAppear { startTimer() }
        .onDisappear { stopTimer() }
    }

    // MARK: - Sub-views

    private var timerRing: some View {
        ZStack {
            // Track
            Circle()
                .stroke(Color(hex: "#141210"), lineWidth: 8)
                .frame(width: 140, height: 140)

            // Progress arc
            Circle()
                .trim(from: 0, to: progress)
                .stroke(challenge.type.color, style: StrokeStyle(lineWidth: 8, lineCap: .round))
                .frame(width: 140, height: 140)
                .rotationEffect(.degrees(-90))
                .animation(.linear(duration: 1), value: progress)

            // Time display
            Text(timeString)
                .font(.mono(32, weight: "Regular"))
                .foregroundColor(Color(hex: "#F5F0E8"))
        }
    }

    private var timeString: String {
        let m = secondsRemaining / 60
        let s = secondsRemaining % 60
        return m > 0 ? "\(m):\(String(format: "%02d", s))" : "\(s)"
    }

    private var promptText: some View {
        Text(challenge.prompt)
            .font(.display(26, weight: "Regular"))
            .foregroundColor(Color(hex: "#F5F0E8"))
            .multilineTextAlignment(.center)
            .lineSpacing(6)
    }

    private var footer: some View {
        HStack {
            Button(action: {
                haptic(.light)
                onSkip()
            }) {
                Text("דלג")
                    .font(.mono(14))
                    .foregroundColor(Color(hex: "#504540"))
            }

            Spacer()

            Button(action: {
                haptic(.heavy)
                stopTimer()
                onComplete()
            }) {
                Text("סיימתי")
                    .font(.display(18, weight: "Bold"))
                    .foregroundColor(.white)
                    .padding(.horizontal, 28)
                    .padding(.vertical, 14)
                    .background(challenge.type.color)
                    .cornerRadius(12)
            }
        }
        .padding(.bottom, 48)
    }

    // MARK: - Timer

    private func startTimer() {
        isRunning = true
        haptic(.medium)
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
            if secondsRemaining > 0 {
                secondsRemaining -= 1
                if secondsRemaining == 10 { haptic(.light) }
            } else {
                stopTimer()
                haptic(.heavy)
                onComplete()
            }
        }
    }

    private func stopTimer() {
        timer?.invalidate()
        timer = nil
        isRunning = false
    }
}
