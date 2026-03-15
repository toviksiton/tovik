import SwiftUI

// MARK: - NBackTestView
// N=2 N-Back with Hebrew letters. 15 trials, ~30% matches injected.
// Score = hits / (hits + misses) × 100

struct NBackTestView: View {
    var onComplete: (Double) -> Void

    // Hebrew letters for stimuli
    private static let letters = ["א", "ב", "ג", "ד", "ה", "ו", "ז", "ח", "ט", "י"]
    private static let n = 2
    private static let totalTrials = 15
    private static let matchRate = 0.30

    @State private var sequence: [String] = []
    @State private var trialIndex = 0
    @State private var currentLetter: String = ""
    @State private var showLetter = false
    @State private var userResponses: [Bool?] = [] // true=match, false=nonMatch, nil=no response
    @State private var hits = 0
    @State private var misses = 0
    @State private var falseAlarms = 0
    @State private var phase: Phase = .intro
    @State private var feedbackColor: Color? = nil

    enum Phase { case intro, running, results }

    var body: some View {
        ZStack {
            Color(hex: "#0E0C0A").ignoresSafeArea()

            VStack(spacing: 32) {
                header

                Spacer()

                switch phase {
                case .intro:   introContent
                case .running: trialContent
                case .results: resultsContent
                }

                Spacer()

                if phase == .running {
                    matchButton
                }
            }
            .padding(.horizontal, 32)
        }
        .environment(\.layoutDirection, .rightToLeft)
    }

    // MARK: - Sub-views

    private var header: some View {
        HStack {
            Text("N-Back (N=2)")
                .font(.custom("PlayfairDisplay-Regular", size: 20))
                .foregroundColor(Color(hex: "#F5F0E8"))
            Spacer()
            if phase == .running {
                Text("\(trialIndex)/\(Self.totalTrials)")
                    .font(.custom("DMMono-Regular", size: 16))
                    .foregroundColor(Color(hex: "#504540"))
            }
        }
        .padding(.top, 48)
    }

    private var introContent: some View {
        VStack(spacing: 24) {
            Text("האם האות הנוכחית זהה לאות שהופיעה לפני 2 מקומות?")
                .font(.custom("PlayfairDisplay-Regular", size: 20))
                .foregroundColor(Color(hex: "#F5F0E8"))
                .multilineTextAlignment(.center)

            Text("הקש 'התאמה' רק כשכן")
                .font(.custom("DMMono-Regular", size: 14))
                .foregroundColor(Color(hex: "#504540"))

            Button(action: { haptic(.medium); buildSequence(); phase = .running; runTrial() }) {
                Text("התחל")
                    .font(.custom("PlayfairDisplay-Bold", size: 20))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 18)
                    .background(Color(hex: "#C4622D"))
                    .cornerRadius(14)
            }
        }
    }

    private var trialContent: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 24)
                .fill(feedbackColor ?? Color(hex: "#141210"))
                .frame(width: 180, height: 180)
                .animation(.easeInOut(duration: 0.15), value: feedbackColor)

            if showLetter {
                Text(currentLetter)
                    .font(.custom("PlayfairDisplay-Bold", size: 80))
                    .foregroundColor(Color(hex: "#F5F0E8"))
                    .transition(.opacity)
            }
        }
    }

    private var matchButton: some View {
        Button(action: userTappedMatch) {
            Text("התאמה")
                .font(.custom("PlayfairDisplay-Bold", size: 22))
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 20)
                .background(Color(hex: "#4A7B5C"))
                .cornerRadius(16)
        }
        .padding(.bottom, 48)
        .disabled(!showLetter)
    }

    private var resultsContent: some View {
        VStack(spacing: 16) {
            let score = calcScore()
            Text("\(Int(score.rounded()))")
                .font(.custom("DMMono-Regular", size: 72))
                .foregroundColor(Color(hex: "#C4622D"))
            Text("ציון N-Back")
                .font(.custom("DMMono-Regular", size: 16))
                .foregroundColor(Color(hex: "#504540"))

            Button(action: { haptic(.medium); onComplete(score) }) {
                Text("המשך")
                    .font(.custom("PlayfairDisplay-Bold", size: 20))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 18)
                    .background(Color(hex: "#C4622D"))
                    .cornerRadius(14)
            }
        }
    }

    // MARK: - Logic

    private func buildSequence() {
        var seq = [String]()
        for i in 0..<Self.totalTrials {
            if i >= Self.n && Double.random(in: 0...1) < Self.matchRate {
                seq.append(seq[i - Self.n]) // inject match
            } else {
                seq.append(Self.letters.randomElement()!)
            }
        }
        sequence = seq
        userResponses = Array(repeating: nil, count: Self.totalTrials)
    }

    private func runTrial() {
        guard trialIndex < Self.totalTrials else {
            phase = .results
            return
        }
        currentLetter = sequence[trialIndex]
        withAnimation(.easeIn(duration: 0.1)) { showLetter = true }
        haptic(.light)

        // Auto-advance after 2s (3s total window: 2s shown + 1s blank)
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            recordNoResponse()
            withAnimation { showLetter = false }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                trialIndex += 1
                runTrial()
            }
        }
    }

    private func userTappedMatch() {
        guard showLetter else { return }
        let isMatch = trialIndex >= Self.n && sequence[trialIndex] == sequence[trialIndex - Self.n]
        userResponses[trialIndex] = true
        if isMatch {
            hits += 1
            feedbackColor = Color(hex: "#4A7B5C")
        } else {
            falseAlarms += 1
            feedbackColor = Color(hex: "#8B2500")
        }
        haptic(.medium)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { feedbackColor = nil }
    }

    private func recordNoResponse() {
        guard userResponses[trialIndex] == nil else { return }
        let isMatch = trialIndex >= Self.n && sequence[trialIndex] == sequence[trialIndex - Self.n]
        if isMatch { misses += 1 }
    }

    private func calcScore() -> Double {
        let total = Double(hits + misses)
        guard total > 0 else { return 0 }
        return (Double(hits) / total) * 100.0
    }
}
