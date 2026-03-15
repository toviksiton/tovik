import SwiftUI

// MARK: - ChallengeOverlayView
// Full-screen dark modal over AI app. Shows type badge, prompt, timer ring, CTA.
// Skip appears after 3s. Month 2+: no skip, mandatory 60s timer.

struct ChallengeOverlayView: View {
    let challenge: Challenge
    let mandatoryMode: Bool      // true after month 2
    var onBegin: () -> Void
    var onSkip: () -> Void

    @State private var skipAvailable = false
    @State private var skipCount = 0
    @State private var showContent = false
    @State private var countdownToSkip: Int = 3

    var body: some View {
        ZStack {
            // Dim background
            Color.black.opacity(0.92).ignoresSafeArea()

            VStack(spacing: 0) {
                topBar
                Spacer()
                mainContent
                Spacer()
                bottomActions
            }
            .padding(.horizontal, 28)
        }
        .environment(\.layoutDirection, .rightToLeft)
        .onAppear {
            withAnimation(.easeIn(duration: 0.4)) { showContent = true }
            if !mandatoryMode { startSkipCountdown() }
        }
    }

    // MARK: - Sub-views

    private var topBar: some View {
        HStack {
            // Challenge type badge
            typeBadge

            Spacer()

            // Intensity dots
            intensityDots
        }
        .padding(.top, 56)
    }

    private var typeBadge: some View {
        HStack(spacing: 6) {
            Circle()
                .fill(challenge.type.color)
                .frame(width: 8, height: 8)
            Text(challenge.type.displayNameHebrew)
                .font(.mono(13, weight: "Medium"))
                .foregroundColor(challenge.type.color)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 7)
        .background(challenge.type.color.opacity(0.15))
        .cornerRadius(20)
    }

    private var intensityDots: some View {
        HStack(spacing: 4) {
            ForEach(1...10, id: \.self) { i in
                Circle()
                    .fill(i <= challenge.intensity
                          ? challenge.type.color
                          : Color(hex: "#504540").opacity(0.4))
                    .frame(width: 5, height: 5)
            }
        }
    }

    private var mainContent: some View {
        VStack(spacing: 32) {
            if showContent {
                Text(challenge.prompt)
                    .font(.display(28, weight: "Regular"))
                    .foregroundColor(Color(hex: "#F5F0E8"))
                    .multilineTextAlignment(.center)
                    .lineSpacing(6)
                    .transition(.opacity.combined(with: .move(edge: .bottom)))

                if let note = challenge.researchNote {
                    Text(note)
                        .font(.mono(12))
                        .foregroundColor(Color(hex: "#504540"))
                        .multilineTextAlignment(.center)
                        .transition(.opacity)
                }
            }
        }
        .animation(.easeOut(duration: 0.5).delay(0.1), value: showContent)
    }

    private var bottomActions: some View {
        VStack(spacing: 16) {
            // Begin CTA
            Button(action: {
                haptic(.heavy)
                onBegin()
            }) {
                Text("התחל")
                    .font(.display(22, weight: "Bold"))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 20)
                    .background(challenge.type.color)
                    .cornerRadius(16)
            }

            // Skip button
            if !mandatoryMode {
                skipButton
            } else {
                Text("לא ניתן לדלג · מצב חובה")
                    .font(.mono(13))
                    .foregroundColor(Color(hex: "#504540"))
            }
        }
        .padding(.bottom, 48)
    }

    @ViewBuilder
    private var skipButton: some View {
        if skipAvailable {
            Button(action: {
                haptic(.light)
                skipCount += 1
                onSkip()
            }) {
                HStack(spacing: 6) {
                    Text("דלג")
                    if skipCount > 0 {
                        Text("(\(skipCount))")
                            .font(.mono(12))
                    }
                }
                .font(.mono(14))
                .foregroundColor(Color(hex: "#504540"))
            }
        } else {
            Text("דלג בעוד \(countdownToSkip)...")
                .font(.mono(13))
                .foregroundColor(Color(hex: "#504540").opacity(0.5))
        }
    }

    // MARK: - Logic

    private func startSkipCountdown() {
        countdownToSkip = 3
        Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { timer in
            if countdownToSkip > 1 {
                countdownToSkip -= 1
            } else {
                timer.invalidate()
                withAnimation { skipAvailable = true }
            }
        }
    }
}
